CC ?= gcc-4.2
ARCH ?= x86_64
MIN_OS ?= 10.6
BUILD_DIR ?= build
GENERATED_DIR ?= $(BUILD_DIR)/generated

CFLAGS := -arch $(ARCH) -Wall -Wextra -Os -mmacosx-version-min=$(MIN_OS)

SNOW_APPKIT := /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
SNOW_CORESERVICES := /System/Library/Frameworks/CoreServices.framework/Versions/A/CoreServices
SNOW_QUARTZ := /System/Library/Frameworks/Quartz.framework/Versions/A/Quartz
SNOW_SCREENSHARING := /System/Library/PrivateFrameworks/ScreenSharing.framework/Versions/A/ScreenSharing
SNOW_LIBSYSTEM := /usr/lib/libSystem.B.dylib

TARGETS := $(BUILD_DIR)/AppKitCompat.dylib $(BUILD_DIR)/CoreServicesCompat.dylib $(BUILD_DIR)/QuartzCompat.dylib $(BUILD_DIR)/ScreenSharingCompat.dylib $(BUILD_DIR)/LibSystemCompat.dylib

all: $(TARGETS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/AppKitCompat.dylib: AppKitCompat.m $(GENERATED_DIR)/AppKitConstants.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -dynamiclib AppKitCompat.m $(GENERATED_DIR)/AppKitConstants.m -Wl,-reexport_library,$(SNOW_APPKIT) -framework Foundation -lobjc -Wl,-install_name,@executable_path/../Frameworks/AppKitCompat.dylib -Wl,-compatibility_version,45.0.0 -Wl,-current_version,1138.0.0 -o $@

$(BUILD_DIR)/CoreServicesCompat.dylib: CoreServicesCompat.c $(GENERATED_DIR)/CoreServicesConstants.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -dynamiclib CoreServicesCompat.c $(GENERATED_DIR)/CoreServicesConstants.c -Wl,-reexport_library,$(SNOW_CORESERVICES) -framework CoreFoundation -Wl,-install_name,@executable_path/../Frameworks/CoreServicesCompat.dylib -Wl,-compatibility_version,1.0.0 -Wl,-current_version,53.0.0 -o $@

$(BUILD_DIR)/QuartzCompat.dylib: QuartzCompat.m $(GENERATED_DIR)/QuartzConstants.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -dynamiclib QuartzCompat.m $(GENERATED_DIR)/QuartzConstants.m -Wl,-reexport_library,$(SNOW_QUARTZ) -framework Foundation -lobjc -Wl,-install_name,@executable_path/../Frameworks/QuartzCompat.dylib -Wl,-compatibility_version,1.0.0 -Wl,-current_version,1.0.0 -o $@

$(BUILD_DIR)/ScreenSharingCompat.dylib: ScreenSharingCompat.m $(GENERATED_DIR)/ScreenSharingConstants.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -dynamiclib ScreenSharingCompat.m $(GENERATED_DIR)/ScreenSharingConstants.m -Wl,-reexport_library,$(SNOW_SCREENSHARING) -framework AppKit -framework Foundation -lobjc -Wl,-install_name,@executable_path/../Frameworks/ScreenSharingCompat.dylib -Wl,-compatibility_version,1.0.0 -Wl,-current_version,1.0.0 -o $@

$(BUILD_DIR)/LibSystemCompat.dylib: LibSystemCompat.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -dynamiclib LibSystemCompat.c -Wl,-reexport_library,$(SNOW_LIBSYSTEM) -Wl,-install_name,@executable_path/../Frameworks/LibSystemCompat.dylib -Wl,-compatibility_version,1.0.0 -Wl,-current_version,159.1.0 -o $@

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
