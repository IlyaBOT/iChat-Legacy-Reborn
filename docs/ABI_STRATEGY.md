# ABI strategy

The first Snow Leopard bring-up is intentionally loader-driven. The project should not guess missing APIs from version numbers or blindly transplant Lion system frameworks.

## Rules

1. Keep Apple donor binaries outside Git under `vendor/`.
2. Never replace Snow Leopard's system IM stack during early development.
3. Build an isolated runtime copy and rewrite only the donor copy.
4. Record the exact first loader failure for every component.
5. Add a shim symbol only after the failure is reproduced on 10.6.8.
6. Prefer forwarding to an equivalent 10.6 API over implementing behavior from scratch.
7. Do not no-op account state, IPC, security, memory-management, authentication or transport APIs.

## Bring-up order

```text
IMFoundation 800
  -> IMServicePlugInSupport
  -> IMServicePlugIn
  -> XMPPCore 800
  -> IMDaemonCore 800
  -> IMCore 800
  -> imagent
  -> Jabber.imservice
  -> iChat 6 executable
```

This order separates low-level ABI failures from daemon/session failures.

## Runtime layout

The intended development tree is approximately:

```text
build/runtime/
  iChat6Legacy.app/
    Contents/
      MacOS/iChat
      Frameworks/
        IMCore.framework
        InstantMessage.framework
        IMAVCore.framework
        IMServicePlugIn.framework
        XMPPCore.framework
        PhoneNumbers.framework
        FTServices.framework
        Marco.framework
        LegacySupportShim.dylib
```

The exact layout may change after testing `@rpath`, `@loader_path` and the daemon bundle loading behavior on 10.6.

## Install-name patching

`tools/plan_install_name_rewrites.py` consumes an analysis manifest and a prefix mapping, then emits a reviewable shell script containing `install_name_tool` commands. It does not patch binaries itself.

This separation is deliberate: a generated patch plan can be inspected and committed as metadata without redistributing Apple binaries.

## What counts as success for Phase 1

- `IMFoundation 800` can be opened or its first missing symbol is identified.
- each subsequent donor component has a deterministic loader result;
- missing symbols are documented with provider/forwarding strategy;
- no modification to `/System/Library` is required.
