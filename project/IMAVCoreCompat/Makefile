CC ?= gcc-4.2
ARCH ?= -arch x86_64
CFLAGS ?= -Wall -Wextra -Os -mmacosx-version-min=10.6
INSTALL_NAME ?= /System/Library/PrivateFrameworks/IMAVCore.framework/Versions/A/IMAVCore
LDFLAGS ?= -dynamiclib -framework Foundation -lobjc -Wl,-install_name,$(INSTALL_NAME) -Wl,-compatibility_version,1.0.0 -Wl,-current_version,800.0.0

all: IMAVCore

IMAVCore: IMAVCoreCompat.m
	$(CC) $(ARCH) $(CFLAGS) $(LDFLAGS) -o $@ $<

check: IMAVCore
	file IMAVCore
	otool -L IMAVCore
	nm -gjU IMAVCore | grep -E 'IMAVChat|IMAVController|IMAVInterface|FZVideoConferenceController|VCChannelNegotiation|OppositeRole|VCCameraPrefsChanged|VCChanged|VCDefault|VCMaxBitrate|NSStringDescription' | sort

clean:
	rm -f IMAVCore

.PHONY: all check clean
