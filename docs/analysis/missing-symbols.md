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

## Loader progress at this point

The bring-up has already passed the initial missing-image stage for the following Lion components bundled locally with the test iChat application:

- `IMAVCore.framework`
- `IMServicePlugIn.framework` / `IMServicePlugInSupport.framework`
- `CoreMedia.framework`
- `AppleSystemInfo.framework`
- `InternetAccounts.framework`
- `libDiagnosticMessagesClient.dylib`
- `Marco.framework`
- `FTServices.framework`
- `IMFoundation.framework` 800 (experimental local copy for Lion-only consumers)

Native Snow Leopard frameworks are still preferred wherever their ABI is sufficient.
