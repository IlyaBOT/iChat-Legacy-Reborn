# AddressBookCompat

Launch/runtime compatibility wrapper for Lion-era AddressBook ABI on Mac OS X Snow Leopard 10.6.8.

The dylib re-exports Snow Leopard's native AddressBook framework and adds the 13 instant-message constants required by Lion IMCore/InstantMessage.

The constant values were extracted directly from Lion AddressBook 1090 Mach-O CFString objects with `tools/extract_cfstring_constants.py`; they are not guessed.

This project does not include or redistribute Apple framework binaries.
