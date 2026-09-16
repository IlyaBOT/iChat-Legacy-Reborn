# iChat 6.0.2 / Lion findings

Donor baseline: iChat 6.0.2 build 1011, IM stack version 800.

## Service architecture

`imagent.app` contains service bundles:

- AIM.imservice
- Bonjour.imservice
- Jabber.imservice
- FaceTime.imservice

`Jabber.imservice` declares `JabberServiceSession` as `NSPrincipalClass` and links against:

- IMDaemonCore 800
- IMFoundation 800
- XMPPCore 800
- Foundation
- Security
- libresolv
- libSystem
- libobjc
- CoreFoundation

Observed XMPP classes include session, roster, presence, message, MUC, file-transfer, card, idle, tune and A/V extensions.

## Plug-in framework

`IMServicePlugIn.framework` and its nested `IMServicePlugInSupport.framework` have a relatively small dependency surface. They are high-priority candidates for early 10.6 loader probing.

## Initial exclusions

Lion `InternetAccounts` integration should be bypassed/stubbed first rather than fully backported. FaceTime also pulls in a much larger Apple-services/AV dependency graph and is not part of the first messaging milestone.
