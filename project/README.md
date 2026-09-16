# Build project

`iChatLegacyProbe` is the first executable target. It intentionally does one thing: `dlopen()` a donor binary with `RTLD_NOW` and print the exact loader error on Snow Leopard.

On a Snow Leopard development machine with Xcode command-line tools:

```sh
cd project/iChatLegacyProbe
make
./iChatLegacyProbe /path/to/framework/binary
```

An Xcode project will be added after the initial loader graph and target SDK/toolchain are fixed. The Makefile keeps the first experiment buildable with the native 10.6 toolchain and avoids committing an unverified generated `.pbxproj`.
