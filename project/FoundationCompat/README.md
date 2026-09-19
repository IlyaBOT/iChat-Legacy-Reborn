# FoundationCompat

Snow Leopard compatibility wrapper for the narrow Lion Foundation ABI surface currently required by Lion iChat 6.

At the first successful load of the local Lion messaging island, Lion IMRenderingFoundation required exactly one Foundation symbol missing from Snow Leopard:

`_OBJC_CLASS_$_NSFileWrapper`

The Lion class metadata shows NSFileWrapper as an NSObject subclass with an x86_64 instance size of 56 bytes. This compatibility class preserves that object layout and implements a small public/basic NSFileWrapper behavior surface.

The dylib re-exports Snow Leopard Foundation; it does not bundle or redistribute Apple's Foundation binary.
