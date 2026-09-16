# Snow Leopard baseline — iChat 5.0.3 / build 745

Target system: Mac OS X 10.6.8 (10K549), Darwin 10.8.0.

## GUI binary

`/Applications/iChat.app/Contents/MacOS/iChat`

- universal `i386 + x86_64`;
- `CFBundleShortVersionString = 5.0.3`;
- `CFBundleVersion = 745`;
- principal application class: `FezApplication`;
- registers `aim:`, `xmpp:`, `im:` and `iChat:` URL schemes.

Primary IM dependencies observed from the executable:

- `IMCore.framework` 701;
- `InstantMessage.framework` 701;
- `IMRenderingFoundation.framework` 701;
- `IMUtils.framework` 701;
- `IMFoundation.framework` 701;
- `IMSecurityUtils.framework` 746.

## Important architecture observation

The bundles inside `iChat.app/Contents/PlugIns` named `AIM.impreferencepane`, `Bonjour.impreferencepane` and `Jabber.impreferencepane` are account/preferences UI, not protocol engines.

The Jabber preferences bundle exposes controls/default keys for:

- server and port;
- SSL/TLS;
- resource;
- Kerberos 5;
- clear-text-password policy;
- host/port autodiscovery;
- Google Talk account special casing.

The actual transport/session implementation is therefore in the system IM stack and `iChatAgent`, not in `Jabber.impreferencepane`.

## Useful private API names recovered from the application

Strings/symbols in the 745 application show the GUI communicating with a daemon-side messaging layer. Relevant names include:

- `DaemonListenerStub`;
- `IMAccount` / `IMAccountController`;
- `IMService` / `IMServiceImpl`;
- daemon connection/disconnection handling;
- service/account login state callbacks;
- Jabber account categories/setters.

The binary also retains `/SourceCache/iChat/iChat-745.3/...` source paths, which are useful for grouping recovered classes by their original subsystem.

## Missing donor data still required

The `iChat.app` archive is only the GUI-side baseline. A full 701→800 mapping also requires a local extraction of:

- `/System/Library/Frameworks/IMCore.framework`;
- `/System/Library/Frameworks/InstantMessage.framework`;
- the Snow Leopard `iChatAgent` bundle/binary;
- nested `IMCore` frameworks such as `IMFoundation`, `IMUtils` and `IMSecurityUtils`.

These proprietary files remain local under `vendor/` and must not be committed.
