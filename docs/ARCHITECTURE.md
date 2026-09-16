# Architecture notes

## Snow Leopard / iChat 5.0.3

Observed application-side stack:

- iChat 5.0.3 build 745
- `IMCore.framework` 701
- `InstantMessage.framework` 701
- `IMRenderingFoundation.framework` 701
- `IMUtils.framework` 701
- `IMFoundation.framework` 701
- `IMSecurityUtils.framework` 746

`Jabber.impreferencepane` is an account/preferences UI bundle, not the XMPP transport implementation. It manipulates `IMAccount`/`IMService` settings including host, port, SSL/TLS, Kerberos, resource, cleartext policy and auto-discovery.

The daemon-side network implementation lives outside `iChat.app`, under the system IM stack and `iChatAgent`.

## Lion / iChat 6.0.2

Observed donor stack:

- iChat 6.0.2 build 1011
- `IMCore` 800 moved to PrivateFrameworks
- `InstantMessage` 800
- `IMFoundation` 800
- `IMDaemonCore` 800
- `imagent.app`
- `IMServicePlugIn.framework`
- `IMServicePlugInSupport.framework`
- `.imservice` bundles: AIM, Bonjour, Jabber, FaceTime
- `XMPPCore` 800

`Jabber.imservice` uses `JabberServiceSession` as its principal class and directly references XMPP session/extensions.

## Backport boundary

The most promising boundary is to treat the Lion daemon-side IM stack as a coherent donor subsystem. Replacing only the GUI or only one service bundle is unlikely to work because the service ABI changed from stack 701 to 800.
