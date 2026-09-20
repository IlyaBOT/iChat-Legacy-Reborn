#import <AppKit/AppKit.h>
#include <stdio.h>

@interface SSConnectionOptions : NSObject @end
@implementation SSConnectionOptions
- (id)init { return [super init]; }
- (int)minimumEncryptionLevel { return 0; }
- (void)setMinimumEncryptionLevel:(int)v { (void)v; }
- (BOOL)shouldFallbackToObserve { return NO; }
- (void)setShouldFallbackToObserve:(BOOL)v { (void)v; }
- (BOOL)shouldGetUserInfo { return NO; }
- (void)setShouldGetUserInfo:(BOOL)v { (void)v; }
- (int)controlType { return 0; }
- (void)setControlType:(int)v { (void)v; }
- (NSDictionary *)hints { return nil; }
- (void)setHints:(NSDictionary *)v { (void)v; }
- (NSArray *)videoEncodings { return nil; }
- (void)setVideoEncodings:(NSArray *)v { (void)v; }
@end

@interface SSEncryptionKeyCredentials : NSObject
- (id)initWithAuthenticationType:(id)type withEncryptionKey:(NSData *)key;
@end
@implementation SSEncryptionKeyCredentials
+ (id)preauthorizedCredentialsWithKey:(NSData *)key { return [[[self alloc] initWithAuthenticationType:nil withEncryptionKey:key] autorelease]; }
- (id)initWithAuthenticationType:(id)type withEncryptionKey:(NSData *)key { (void)type; (void)key; return [super init]; }
- (NSData *)encryptionKey { return nil; }
@end

@interface SSFrameBufferView : NSView @end
@implementation SSFrameBufferView
- (id)frameBuffer { return nil; }
- (void)setFrameBuffer:(id)v { (void)v; }
- (id)inputEventConsumer { return nil; }
- (void)setInputEventConsumer:(id)v { (void)v; }
- (id)delegate { return nil; }
- (void)setDelegate:(id)v { (void)v; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { (void)event; return YES; }
@end

@interface SSKeyboardEvent : NSObject
- (id)initWithKeyCode:(NSUInteger)code withState:(int)state;
@end
@implementation SSKeyboardEvent
+ (id)keyboardEventWithKeyCode:(NSUInteger)code withState:(int)state { return [[[self alloc] initWithKeyCode:code withState:state] autorelease]; }
- (id)initWithKeyCode:(NSUInteger)code withState:(int)state { (void)code; (void)state; return [super init]; }
- (NSUInteger)keyCode { return 0; }
- (int)keyState { return 0; }
@end

@interface SSSession : NSObject @end
@implementation SSSession
- (id)init { return [super init]; }
- (void)setDelegate:(id)v { (void)v; }
- (id)delegate { return nil; }
- (void)setConnectionOptions:(id)v { (void)v; }
- (id)connectionOptions { return nil; }
- (void)connectToAddress:(id)address withOptions:(id)options { (void)address; (void)options; }
- (void)disconnect {}
- (void)reconnect {}
- (void)sendEvent:(id)event { (void)event; }
- (id)frameBuffer { return nil; }
@end

@interface SSUDPSocketAddress : NSObject
- (id)initWithUDPSocket:(int)sock;
@end
@implementation SSUDPSocketAddress
- (id)initWithUDPSocket:(int)sock { (void)sock; return [super init]; }
- (int)socket { return -1; }
- (void)setRemoteIPPort:(NSString *)value { (void)value; }
- (NSString *)remoteIPPort { return nil; }
- (NSString *)displayString { return @""; }
@end

NSArray *SSHighQualityEncodings(void)
{
    return [NSArray array];
}

/* Launch-only: modifier synchronization is irrelevant until Screen Sharing is enabled. */
void SSSendChangedModifierFlags(void)
{
}

__attribute__((constructor))
static void ILRScreenSharingCompatInit(void) { fprintf(stderr,"[ScreenSharingCompat] loaded\n"); }
