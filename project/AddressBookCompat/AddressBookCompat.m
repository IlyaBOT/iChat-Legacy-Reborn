#import <Foundation/Foundation.h>
#include <stdio.h>

/*
 * Lion AddressBook 1090 compatibility additions for Snow Leopard 10.6.8.
 *
 * These values were extracted directly from the Lion AddressBook Mach-O
 * CFString objects. Snow Leopard's AddressBook is re-exported by the wrapper;
 * only the Lion-only instant-message constants are provided here.
 */

NSString * const kABInstantMessageProperty = @"InstantMessage";
NSString * const kABInstantMessageServiceAIM = @"AIMInstant";
NSString * const kABInstantMessageServiceFacebook = @"FacebookInstant";
NSString * const kABInstantMessageServiceGaduGadu = @"GaduGaduInstant";
NSString * const kABInstantMessageServiceGoogleTalk = @"GoogleTalkInstant";
NSString * const kABInstantMessageServiceICQ = @"ICQInstant";
NSString * const kABInstantMessageServiceJabber = @"JabberInstant";
NSString * const kABInstantMessageServiceKey = @"InstantMessageService";
NSString * const kABInstantMessageServiceMSN = @"MSNInstant";
NSString * const kABInstantMessageServiceQQ = @"QQInstant";
NSString * const kABInstantMessageServiceSkype = @"SkypeInstant";
NSString * const kABInstantMessageServiceYahoo = @"YahooInstant";
NSString * const kABInstantMessageUsernameKey = @"InstantMessageUsername";

__attribute__((constructor))
static void AddressBookCompatInitialize(void)
{
    fprintf(stderr, "[AddressBookCompat] loaded (Snow AddressBook + Lion IM constants)\n");
}
