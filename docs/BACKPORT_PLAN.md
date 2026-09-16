# Backport plan

## Milestone 0 — reproducible reverse engineering

- Extract Snow Leopard and Lion donors into local `vendor/` trees.
- Generate deterministic manifests: architecture, install names, dylib dependencies, imported symbols and selected strings.
- Compare stack 701 vs 800 automatically.

## Milestone 1 — loader probe on Snow Leopard

Build `iChatLegacyProbe` for 10.6 and `dlopen()` donor components one at a time. Record the first loader error for each component.

Suggested order:

1. IMFoundation 800
2. IMServicePlugInSupport
3. IMServicePlugIn
4. XMPPCore 800
5. IMDaemonCore 800
6. IMCore 800
7. imagent
8. Jabber.imservice
9. iChat 6 executable

This creates a concrete missing-symbol graph instead of guessing from version numbers.

## Milestone 2 — isolated donor runtime

Create an `iChat6Legacy.app` working copy and keep Lion-only dependencies local. Do not replace Snow Leopard's system IM frameworks during development.

Investigate `@loader_path`, `@executable_path` and/or explicit controlled framework search paths. Every install-name rewrite must be reproducible from scripts in this repository.

## Milestone 3 — compatibility shims

Implement only APIs proven missing by the loader probe. Prefer:

1. forwarding to an equivalent Snow Leopard API;
2. a small compatibility wrapper;
3. a safe no-op only for optional functionality.

Do not blindly stub functions that affect account/session state, security, memory ownership or IPC.

## Milestone 4 — daemon/service bring-up

Initial scope:

- imagent launches on 10.6;
- service discovery works;
- Bonjour/Jabber service bundle loads;
- account can be constructed without Lion InternetAccounts;
- XMPP session reaches connection/authentication code.

Initial exclusions:

- FaceTime;
- InternetAccounts UI integration;
- video-conference compatibility beyond what is needed to keep the app stable.

## Milestone 5 — modern services

Once the native service-plugin ABI works, add original service bundles or gateway-based integrations without embedding large modern protocol stacks directly into `imagent`.
