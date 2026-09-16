# iChat Legacy Reborn
 
Reverse-engineering and backporting the Lion-era iChat 6 to older Mac OS X releases *(10.6-10.4)* and extending it with modern messaging service compatibility.

## Baseline

| Role | System | iChat | IM stack |
|---|---|---|---|
| Donor | Mac OS X Lion | 6.0.2 (1011) | 800 |
| Target (Tier 1) | Mac OS X 10.6.8 | 5.0.3 (745) | 701 |
| Target (Tier 2) | Mac OS X 10.5.8 | - | - |
| Target (Tier 3) | Mac OS X 10.4.11 | - | - |

Initial CPU target: **i386 + x86_64**.

## What this repository contains

- original compatibility/backport source code;
- Xcode/build projects;
- extraction and analysis tools;
- dependency/symbol manifests generated from user-owned Apple software;
- reverse-engineering notes and reproducible patch descriptions.

It does **not** redistribute Apple application/framework binaries or installer payloads. Those belong under the local `vendor/` directory and are ignored by Git.

## Current direction

Lion split the daemon-side messaging implementation into `imagent` plus `.imservice` bundles. The initial backport target is therefore the Lion IM stack as a coherent unit rather than trying to bolt `Jabber.imservice` directly onto Snow Leopard's `iChatAgent`.

First bring-up target:

```text
iChat 6 GUI
  -> InstantMessage 800
  -> IMCore 800 / IMFoundation / IMDaemonCore
  -> imagent
  -> IMServicePlugInSupport
  -> Jabber.imservice
  -> XMPPCore 800
```

Internet Accounts and FaceTime integration are deliberately out of scope for the first boot milestone.

## Quick start

1. Populate local donors under `vendor/`.
2. Run `tools/analyze_tree.py` for each donor tree.
3. Run `tools/compare_manifests.py`.
4. Build/run `iChatLegacyProbe` on 10.6 to test which Lion frameworks can be loaded and record the first missing dependency/symbol.

See `docs/BACKPORT_PLAN.md`.
