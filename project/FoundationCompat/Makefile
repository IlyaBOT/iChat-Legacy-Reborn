CC ?= gcc-4.2
ARCH ?= x86_64
MIN_OS ?= 10.6

TARGET := FoundationCompat.dylib
SOURCE := FoundationCompat.m
SNOW_FOUNDATION := /System/Library/Frameworks/Foundation.framework/Versions/C/Foundation

CFLAGS := -arch $(ARCH) -Wall -Wextra -Os -mmacosx-version-min=$(MIN_OS)
LDFLAGS := -dynamiclib -lobjc -Wl,-reexport_library,$(SNOW_FOUNDATION) -Wl,-install_name,@executable_path/../Frameworks/FoundationCompat.dylib -Wl,-compatibility_version,300.0.0 -Wl,-current_version,833.25.0

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(SOURCE) $(LDFLAGS) -o $@

clean:
	rm -f $(TARGET)

.PHONY: all clean
