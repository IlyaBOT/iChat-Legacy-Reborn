CC ?= clang
CFLAGS ?= -Wall -Wextra -Os -mmacosx-version-min=10.6
ARCHS ?= -arch i386 -arch x86_64
LDFLAGS ?= -dynamiclib -Wl,-install_name,@rpath/LegacySupportShim.dylib -mmacosx-version-min=10.6

SNOW_CC ?= gcc-4.2
SECURITY_COMPAT_CFLAGS ?= -Wall -Wextra -Os -mmacosx-version-min=10.6
SECURITY_COMPAT_LDFLAGS ?= -dynamiclib -Wl,-reexport_framework,Security -Wl,-install_name,@executable_path/../Frameworks/SecurityCompat.dylib -framework CoreFoundation

all: LegacySupportShim.dylib SecurityCompat.dylib

LegacySupportShim.dylib: LegacySupportShim.c
	$(CC) $(CFLAGS) $(ARCHS) $(LDFLAGS) -o $@ $<

SecurityCompat.dylib: SecurityCompat.c
	$(SNOW_CC) $(SECURITY_COMPAT_CFLAGS) $(ARCHS) $(SECURITY_COMPAT_LDFLAGS) -o $@ $<

clean:
	rm -f LegacySupportShim.dylib SecurityCompat.dylib

.PHONY: all clean
