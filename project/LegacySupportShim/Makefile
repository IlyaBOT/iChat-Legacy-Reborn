CC ?= clang
CFLAGS ?= -Wall -Wextra -Os -mmacosx-version-min=10.6
ARCHS ?= -arch i386 -arch x86_64
LDFLAGS ?= -dynamiclib -Wl,-install_name,@rpath/LegacySupportShim.dylib -mmacosx-version-min=10.6

all: LegacySupportShim.dylib

LegacySupportShim.dylib: LegacySupportShim.c
	$(CC) $(CFLAGS) $(ARCHS) $(LDFLAGS) -o $@ $<

clean:
	rm -f LegacySupportShim.dylib

.PHONY: all clean
