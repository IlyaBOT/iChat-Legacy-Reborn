CC ?= gcc-4.2
CFLAGS ?= -Wall -Wextra -Os -mmacosx-version-min=10.6
ARCHS ?= -arch x86_64
LDFLAGS ?= -dynamiclib -framework Foundation -lobjc -Wl,-install_name,/System/Library/PrivateFrameworks/InternetAccounts.framework/Versions/A/InternetAccounts -Wl,-compatibility_version,1.0.0 -Wl,-current_version,1.0.0

all: InternetAccounts

InternetAccounts: InternetAccountsCompat.m
	$(CC) $(CFLAGS) $(ARCHS) $(LDFLAGS) -o $@ $<

clean:
	rm -f InternetAccounts

.PHONY: all clean
