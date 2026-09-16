# Patch recipes

No opaque patched Apple binaries are stored here.

Each compatibility change should be represented by one of:

- source code in `project/`;
- an `install_name_tool` recipe;
- a plist mutation script;
- a small binary patch description with original bytes, replacement bytes, architecture and rationale.

All patches must be reproducible from an unmodified donor extracted by the repository tools.
