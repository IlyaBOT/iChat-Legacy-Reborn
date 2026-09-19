# Runtime closure audit

For Milestone 1, stop iterating on one dyld failure at a time.

`audit_runtime_closure.py` recursively resolves the main iChat process runtime closure and audits all app-local Mach-O consumers against the actual provider export surfaces. It follows `LC_REEXPORT_DYLIB`, so umbrella/re-export frameworks such as FoundationCompat, IMCore/IMFoundation and WebKit/WebCore are handled correctly.

Use `--lion-root` to annotate missing symbols that are present in the equivalent Lion provider.

`apply_runtime_map.py` applies declarative install-name mappings from JSON. The supplied `patches/milestone1-runtime-map.json` deliberately targets only the main process and in-process plug-ins/framework binaries; helper executables, XPC services and imagent are not rewritten with main-executable-relative paths.
