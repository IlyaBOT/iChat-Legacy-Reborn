CC ?= gcc-4.2
ARCH ?= x86_64
MIN_OS ?= 10.6

TARGET := AddressBookCompat.dylib
SOURCE := AddressBookCompat.m
SNOW_ADDRESSBOOK := /System/Library/Frameworks/AddressBook.framework/Versions/A/AddressBook

CFLAGS := -arch $(ARCH) -Wall -Wextra -Os -mmacosx-version-min=$(MIN_OS)
LDFLAGS := -dynamiclib -framework Foundation -Wl,-reexport_library,$(SNOW_ADDRESSBOOK) -Wl,-install_name,@executable_path/../Frameworks/AddressBookCompat.dylib -Wl,-compatibility_version,1.0.0 -Wl,-current_version,1090.0.0

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(SOURCE) $(LDFLAGS) -o $@

clean:
	rm -f $(TARGET)

.PHONY: all clean
