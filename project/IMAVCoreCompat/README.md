# IMAVCoreCompat

Launch-only replacement for Lion `IMAVCore.framework` while bringing iChat 6.0.2 up on Mac OS X Snow Leopard 10.6.8.

## Scope

This shim exists to satisfy the ABI imported directly by the iChat GUI without pulling in Lion `IMAVCore 800`, `Marco`, `FTServices`, Lion `IMFoundation 800`, and their wider dependency chain.

Current implementation is intentionally x86_64-only and is **not** a functional audio/video stack.

It provides:

- the Objective-C classes directly imported by iChat;
- the exported ivar-offset ABI required by `IMAVChat`, `IMAVChatParticipant`, and `IMAVChatFeature`;
- the directly imported notification/key/preference symbols;
- launch-safe placeholder implementations for a small number of AV helpers and singleton entry points.

## Verified Lion x86_64 layout

- `IMAVChat`: instance size 376; `_recorder` 352, `_auxVideo` 360, `_ard` 368.
- `IMAVChatParticipant`: instance size 304; imported ARD/channel ivars occupy offsets 12 through 64.
- `IMAVChatFeature`: instance size 16; `_avChat` offset 8.
- `IMAVInterface`: instance size 17.
- `VCChannelNegotiation`: instance size 128.
- `IMAVController`: instance size 19.

Runtime constructor logging prints the critical generated ivar offsets so they can be checked before trusting a build.

## Build on Snow Leopard

```sh
make
make check
```

Do not ship this as a real AV implementation. Milestone 1 is limited to launching and quitting the iChat 6 GUI.
