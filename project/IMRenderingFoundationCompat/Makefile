CC ?= gcc-4.2
ARCH ?= x86_64
MIN_OS ?= 10.6
TARGET := IMRenderingFoundationCompat.dylib
SOURCE := IMRenderingFoundationCompat.m
SNOW_IMRF := /System/Library/Frameworks/InstantMessage.framework/Versions/A/Frameworks/IMRenderingFoundation.framework/Versions/A/IMRenderingFoundation

CFLAGS := -arch $(ARCH) -Wall -Wextra -Os -mmacosx-version-min=$(MIN_OS)
LDFLAGS := -dynamiclib -framework Cocoa -lobjc -Wl,-reexport_library,$(SNOW_IMRF) -Wl,-install_name,@executable_path/../Frameworks/IMRenderingFoundationCompat.dylib -Wl,-compatibility_version,9999.0.0 -Wl,-current_version,9999.0.0

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(SOURCE) $(LDFLAGS) -o $@

clean:
	rm -f $(TARGET)
