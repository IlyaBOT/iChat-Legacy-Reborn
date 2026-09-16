# iChat 5.0.3 / Snow Leopard findings

Source baseline: Mac OS X 10.6.8 (10K549), iChat 5.0.3 build 745.

## Main executable

Universal `i386 + x86_64`.

Directly linked IM components observed from `otool -L`:

- IMCore 701
- InstantMessage 701
- IMRenderingFoundation 701
- IMUtils 701
- IMSecurityUtils 746
- IMFoundation 701

## Jabber preferences bundle

`Contents/PlugIns/Jabber.impreferencepane` is a GUI/preferences bundle. Important settings/classes visible in symbols/strings include:

- `IMAccount`, `IMAccountController`, `IMService`, `IMServiceImpl`
- `XMPPTLSEnabled`
- server host/port and SSL host/port
- SSL enable
- Kerberos 5
- cleartext-password policy
- resource name
- machine-name resource option
- host/port auto discovery

No `XMPPCore.framework` dependency is present in the application-side bundle. The actual transport must therefore be analyzed in the system IM stack / iChatAgent dump.
