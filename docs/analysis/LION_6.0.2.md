# Lion donor baseline — iChat 6.0.2 / build 1011

Donor application: iChat 6.0.2 from Mac OS X Lion.

## High-level split

Lion moves the messaging stack toward a daemon + service-bundle architecture:

```text
iChat 6.0.2
  -> InstantMessage 800
  -> IMCore 800
       -> IMFoundation 800
       -> IMDaemonCore 800
       -> imagent.app
            -> AIM.imservice
            -> Bonjour.imservice
            -> Jabber.imservice
            -> FaceTime.imservice
  -> IMServicePlugIn
       -> IMServicePlugInSupport
```

The major architectural change is not only the GUI version: protocol/session code is now represented by `.imservice` bundles loaded by `imagent`.

## Jabber.imservice

`Jabber.imservice` is a universal `i386 + x86_64` Mach-O bundle.

Its principal class is:

```text
JabberServiceSession
```

Observed dependencies include:

- `IMDaemonCore` 800;
- `IMFoundation` 800;
- `XMPPCore` 800;
- Foundation;
- Security;
- CoreFoundation;
- `libresolv`.

Recovered imported Objective-C classes from `XMPPCore` include:

- `XMPPSession`;
- `XMPPRosterExtension`;
- `XMPPPresenceExtension`;
- `XMPPMessageExtension`;
- `XMPPMultiUserChatExtension`;
- `XMPPFileTransferExtension`;
- `XMPPAudioVideoExtension`;
- `XMPPCardExtension`;
- `XMPPIdleExtension`;
- `XMPPTuneExtension`.

This is the first component to target after the daemon/framework loader chain is functional.

## IMServicePlugIn layer

`IMServicePlugIn.framework` and nested `IMServicePlugInSupport.framework` are comparatively small and have few OS-level dependencies.

`IMServicePlugInSupport` references `IMPathsForPlugInsWithExtension`, indicating that service discovery is intentionally factored out from individual protocol bundles.

This subsystem is a strong backport candidate and should be preserved rather than replaced with a custom plugin ABI unless binary compatibility proves impossible.

## imagent

`imagent` is universal `i386 + x86_64` and links against:

- `IMFoundation` 800;
- `IMDaemonCore` 800;
- `IMServicePlugInSupport`;
- `FTServices` 800;
- `Marco` 800;
- Foundation/CoreFoundation/CoreServices.

This means the Lion `.imservice` bundles cannot simply be dropped into Snow Leopard `iChatAgent`; the daemon-side runtime needs to be brought up as a coherent subset.

## Initial exclusions

For the first Snow Leopard boot milestone:

- do not backport InternetAccounts integration;
- do not require FaceTime;
- do not require AV/video functionality beyond avoiding crashes;
- do not replace Snow Leopard system frameworks in-place.

The experimental runtime should remain isolated and reproducibly patched from local donor files.
