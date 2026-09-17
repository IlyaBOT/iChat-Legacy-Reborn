# Observed missing symbols on Mac OS X 10.6.8

This file tracks ABI failures that were observed while launching Lion iChat 6.0.2 on Snow Leopard 10.6.8. It is intentionally evidence-driven: do not add speculative stubs.

## IMFoundation 800 vs Snow Leopard IMFoundation 701

When Lion `Marco.framework` and `FTServices.framework` were redirected to Snow Leopard's native `IMFoundation.framework`, the following imports were absent from Snow Leopard 10.6.8.

### Marco.framework

- `_IMRemoteObjectDidDisconnectNotification`
- `_OBJC_CLASS_$_IMRemoteObject`
- `_OBJC_CLASS_$_IMRemoteObjectBroadcaster`

### FTServices.framework

- `_IMCurrentPreferredLanguage`
- `_IMGetCachedDomainBoolForKey`
- `_IMGetConferenceSettings`
- `_IMGetMadridSettings`
- `_IMLockdownDeviceActivatedChangedNotification`
- `_IMWeakLinkClass`
- `_IMWeakLinkSymbol`
- `_OBJC_CLASS_$_IMConnectionMonitor`
- `_OBJC_CLASS_$_IMLockdownManager`
- `_OBJC_CLASS_$_IMSystemMonitor`
- `_OBJC_CLASS_$_IMTimer`
- `__IMAlwaysLog`
- `__IMWarn`
- `__IMWillLog`

`IMServicePlugInSupport.framework` had no missing IMFoundation imports in this comparison.

Because the delta includes Objective-C classes and non-trivial helper functions, Lion `IMFoundation 800` was tested locally for `Marco` and `FTServices` instead of fabricating those APIs.

## Lion IMFoundation 800 vs Snow Leopard Security.framework

With Lion `IMFoundation 800` loaded locally, dyld reported:

- `_kSecACLAuthorizationDecrypt`

A complete import/export comparison against Snow Leopard Security.framework showed four missing Lion-era Security symbols:

- `_SecACLCopyContents`
- `_SecACLSetContents`
- `_SecAccessCopyMatchingACLList`
- `_kSecACLAuthorizationDecrypt`

Snow Leopard exports the older related API:

- `_SecACLCopySimpleContents`
- `_SecACLSetSimpleContents`
- `_SecAccessCopySelectedACLList`

`project/LegacySupportShim/SecurityCompat.c` implements a narrow compatibility layer for these four observed imports and delegates to the Snow Leopard Security API where possible.

## Lion FTServices vs Snow Leopard Security.framework

After the IMFoundation Security gap was bridged, dyld reported `_kSecDigestSHA1` from Lion `FTServices.framework`. A full import/export comparison showed eleven Lion Security Transforms symbols absent from Snow Leopard:

- `_SecSignTransformCreate`
- `_SecTransformExecute`
- `_SecTransformSetAttribute`
- `_SecVerifyTransformCreate`
- `_kSecDigestSHA1`
- `_kSecDigestTypeAttribute`
- `_kSecInputIsAttributeName`
- `_kSecInputIsDigest`
- `_kSecKeyAttributeName`
- `_kSecSignatureAttributeName`
- `_kSecTransformInputAttributeName`

For Milestone 1 (launch the iChat 6 GUI), `SecurityCompat.c` exports these symbols as explicitly launch-only stubs. They satisfy dyld but do **not** provide real signing or signature verification. Functional Security Transforms support is deferred until it is proven necessary beyond application startup.

## Lion IMAVCore 800 vs Snow Leopard IMCore 701

After the Security gaps were bridged, dyld reached Lion `IMAVCore.framework` and failed on `_FZAVErrorDomain`, expected from Snow Leopard's native `IMCore.framework`.

A complete import/export comparison showed that Lion IMAVCore references 95 IMCore symbols and that **80 are absent** from Snow Leopard IMCore 701. The missing set includes FaceTime/AV relay constants, domain helpers, logging helpers and several Objective-C classes such as `IMPair`, `IMSuddenTermination`, `IMSystemMonitor`, and `NetworkChangeNotifier`.

This is too large to bridge by continuing to run the real Lion IMAVCore against the Snow IMCore ABI. Milestone 1 therefore pivots to a dedicated `IMAVCoreCompat` implementation.

The iChat 6 executable directly imports **46 symbols** from IMAVCore. The direct surface is much smaller and consists primarily of:

- notification/key constants;
- Objective-C classes (`FZVideoConferenceController`, `IMAVChat`, `IMAVChatFeature`, `IMAVChatParticipant`, `IMAVController`, `IMAVInterface`, `VCChannelNegotiation`);
- exported Objective-C ivar-offset symbols for `IMAVChat`, `IMAVChatFeature`, and `IMAVChatParticipant`;
- a small group of VC globals/functions.

Snow Leopard IMCore and InstantMessage contain some older IMAV chat keys but do not export the required Lion AV classes or VC symbols. The compatibility implementation therefore needs to reproduce the observed Lion Objective-C ABI (superclasses, instance sizes, ivar order/offsets, class/metaclass exports) sufficiently for iChat 6 to reach the GUI without enabling AV functionality.

## iChat 6 executable vs Snow Leopard IMCore 701

After the AV, InternetAccounts and IMRenderingFoundation gaps were bridged, dyld reached the iChat 6 executable's direct IMCore dependency and failed on `_ABIMHandlesChangedNotification`.

A complete direct import/export comparison found **187 IMCore imports from iChat 6, of which 153 are absent from Snow Leopard IMCore 701**. This is not a narrow compatibility surface. The missing set includes central Lion messaging classes and infrastructure such as:

- `IMChat`, `IMChatRegistry`, `IMFileTransfer`;
- `IMMessageChatItem`, `IMDatestampChatItem`, `IMHeaderChatItem`, `IMTimestampChatItem`;
- `IMLocalObject`, `IMRemoteObject`, `IMRemoteObjectBroadcaster`;
- `IMDirectlyObservableObject`, `IMSystemMonitor`, `IMAddressBook`, `IMFileManager`;
- many account/chat/handle notifications and property keys;
- keychain, logging, plugin-path, temporary-path and service helper functions.

Because iChat directly relies on a large portion of the Lion IMCore object model, a Snow-IMCore re-export shim with 153 fabricated symbols is considered unsafe and unsuitable. The next experiment is to treat **Lion IMCore 800 as the candidate primary IMCore for the iChat 6 process**, then measure its dependencies against Snow Leopard and identify duplicate-class conflicts with native Snow frameworks before deciding whether a mixed Lion/Snow stack is viable.

## Loader progress at this point

The bring-up has passed the initial missing-image stage for the following components and compatibility layers:

- `IMServicePlugIn.framework` / `IMServicePlugInSupport.framework`
- `CoreMedia.framework`
- `AppleSystemInfo.framework`
- `libDiagnosticMessagesClient.dylib`
- `IMAVCoreCompat`
- `InternetAccountsCompat`
- `IMRenderingFoundationCompat`

The real Lion AV dependency chain (`IMAVCore -> Marco/FTServices -> IMFoundation 800 -> IMCore 800/Security Transforms`) is not used for Milestone 1; `IMAVCoreCompat` replaces that surface.

Native Snow Leopard frameworks are still preferred where their ABI is sufficient, but the direct iChat 6 -> IMCore gap is large enough that Lion IMCore 800 must now be evaluated explicitly.


## Lion IMCore 800 as a replacement for Snow IMCore 701

Testing whether Lion IMCore 800 could serve as the single IMCore implementation for both Lion iChat and Snow Leopard's existing messaging frameworks showed that the mixed stack is not ABI-compatible.

### Snow InstantMessage -> Lion IMCore 800

Snow Leopard `InstantMessage.framework` imports 21 symbols from IMCore. Lion IMCore 800 provides 19 of them, but is missing two exported ivar-offset symbols:

- `_OBJC_IVAR_$_IMAccount._iconChecked`
- `_OBJC_IVAR_$_IMAccount._subtypeInfo`

Because these are ivar offsets, this is an object-layout incompatibility rather than a simple missing helper function.

### Snow IMRenderingFoundation -> Lion IMCore 800

Snow Leopard `IMRenderingFoundation.framework` imports 44 symbols from IMCore. Lion IMCore 800 is missing **43** of them. The missing surface includes attributed-string parser classes, rendering attributes, geometry/path helpers, logging helpers and ivar-offset symbols.

Therefore Snow `InstantMessage` / `IMRenderingFoundation` cannot safely be redirected to Lion IMCore 800. A viable Lion IMCore path requires moving the dependent messaging frameworks as a coherent Lion stack instead of mixing them with Snow implementations.

### Lion IMCore 800 vs Snow system frameworks

A direct import/export comparison of Lion IMCore 800 against Snow Leopard system frameworks found:

- Foundation: 27 imports, **0 missing**
- CoreFoundation: 34 imports, **0 missing**
- AddressBook: 40 imports, **13 missing**
- Security: no direct imports requiring additional work in this comparison
- PhoneNumbers.framework: absent on Snow Leopard; Lion IMCore imports only 3 functions from it

The 13 missing AddressBook symbols are instant-messaging constants such as `kABInstantMessageProperty`, service identifiers (AIM, Facebook, GoogleTalk, Jabber, Skype, Yahoo, etc.) and `kABInstantMessageUsernameKey`.

The three PhoneNumbers imports are:

- `_CFPhoneNumberCreate`
- `_CFPhoneNumberCopyUnformattedRepresentation`
- `_CFPhoneNumberCopyUnformattedInternationalRepresentation`

This suggests that the lower Snow runtime is comparatively close to what Lion IMCore needs, and that the next experiment should evaluate a coherent Lion messaging island (`IMCore + IMFoundation + InstantMessage + IMRenderingFoundation`) with narrow compatibility shims for AddressBook and PhoneNumbers rather than forcing Lion IMCore under Snow messaging frameworks.


### Re-export caveat for Lion IMCore analysis

A first physical-export-only comparison of Lion `InstantMessage.framework` / `IMRenderingFoundation.framework` against the Lion IMCore binary reported apparent missing IMCore symbols (11 and 46 respectively). Many of those symbols are known Lion IMFoundation APIs (for example remote-object classes, attributed-string parsers and IM logging helpers), so these counts must not yet be treated as an ABI failure. Lion IMCore may expose part of its public surface by re-exporting its nested IMFoundation framework. The next comparison therefore needs to inspect `LC_REEXPORT_DYLIB` and compare clients against the combined IMCore + IMFoundation export surface.

Also, the current patched iChat executable no longer reports direct imports as `(from IMRenderingFoundation)` because that dependency was already rewritten to `IMRenderingFoundationCompat.dylib`; the previously measured original direct surface remains 36 imports.


## Coherent Lion messaging island confirmed

Inspecting Lion IMCore 800 load commands showed an `LC_REEXPORT_DYLIB` entry for its nested `IMFoundation.framework`. Re-running the ABI comparison against the **combined IMCore + IMFoundation export surface** eliminated the apparent gaps:

- Lion `InstantMessage.framework` -> Lion `IMCore + IMFoundation`: 23 imports, **0 missing**
- Lion `IMRenderingFoundation.framework` -> Lion `IMCore + IMFoundation`: 59 imports, **0 missing**
- Lion IMCore -> Lion IMFoundation: 157 imports, **0 missing**

This confirms that the correct internal stack is a coherent Lion messaging island rather than a mixed Snow/Lion stack:

- Lion IMCore 800
- Lion IMFoundation 800 (re-exported by IMCore)
- Lion InstantMessage 800
- Lion IMRenderingFoundation 800

The next compatibility work should therefore focus on the island's boundary with Snow Leopard system frameworks (AddressBook, AppKit, WebKit, DataDetectors, Symbolication, PhoneNumbers, etc.), not on fabricating internal IMCore symbols.
