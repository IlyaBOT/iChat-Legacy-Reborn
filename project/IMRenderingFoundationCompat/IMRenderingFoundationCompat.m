#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#include <stdio.h>

/*
 * Launch-only IMRenderingFoundation compatibility shim for iChat 6.0.2 on
 * Mac OS X Snow Leopard 10.6.8.
 *
 * iChat 6 directly imports 36 symbols from IMRenderingFoundation. Snow
 * Leopard already provides 26 of them. This shim is intended to re-export the
 * native Snow Leopard IMRenderingFoundation binary and add only the ten Lion
 * ABI symbols missing from Snow.
 *
 * This is not a complete Lion IMRenderingFoundation implementation.
 */

#define IMRF_STRING(name) NSString * const name = @#name

IMRF_STRING(kAttachedFileURLAttributeName);
IMRF_STRING(kInlineFileURLAttributeName);
IMRF_STRING(kOriginalFontAttributeName);
IMRF_STRING(kTextEquivalentAttributeName);

/*
 * Lion metadata:
 *
 *   BaseInstantMessage : IMMessage
 *     instanceStart = 120
 *     _fgColor @ 120
 *     _bgColor @ 128
 *     instanceSize = 136
 *
 * Snow Leopard does not export OBJC_CLASS_$_IMMessage from any framework
 * searched during bring-up. Defining a second IMMessage class would therefore
 * be both unnecessary and potentially dangerous if a private/hidden class is
 * registered at runtime. For the launch-only shim we derive from NSObject and
 * explicitly pad the object so the ABI-visible Lion ivar offsets still match.
 */
@interface BaseInstantMessage : NSObject {
@private
    unsigned char _compatPadding8To120[112];
    NSColor *_fgColor; /* x86_64 offset 120 */
@public
    NSColor *_bgColor; /* x86_64 offset 128 */
}
- (BOOL)isInteresting;
- (NSColor *)backgroundColor;
- (NSColor *)foregroundColor;
- (NSString *)speechDescription;
- (id)plainBody;
@end

@implementation BaseInstantMessage

- (BOOL)isInteresting
{
    return NO;
}

- (NSColor *)backgroundColor
{
    return _bgColor;
}

- (NSColor *)foregroundColor
{
    return _fgColor;
}

- (NSString *)speechDescription
{
    id body = [self plainBody];
    return [body isKindOfClass:[NSString class]] ? body : [body description];
}

- (id)plainBody
{
    return nil;
}

- (void)dealloc
{
    [_fgColor release];
    [_bgColor release];
    [super dealloc];
}

@end

/*
 * Lion metadata:
 *
 *   ArchivedMessagePlaceholder : NSObject <NSCoding>
 *     _message  @ 8
 *     _chatItem @ 16
 *     instanceSize = 24
 */
@interface ArchivedMessagePlaceholder : NSObject <NSCoding> {
@private
    BaseInstantMessage *_message; /* x86_64 offset 8 */
    id _chatItem;                 /* x86_64 offset 16 */
}
+ (void)setupArchivedMessageEncoding;
+ (void)setupArchivedMessageDecoding;
- (id)initWithChatItem:(id)chatItem;
@end

@implementation ArchivedMessagePlaceholder

+ (void)setupArchivedMessageEncoding
{
}

+ (void)setupArchivedMessageDecoding
{
}

- (id)initWithChatItem:(id)chatItem
{
    if ((self = [super init])) {
        _chatItem = [chatItem retain];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        if ([coder allowsKeyedCoding]) {
            _message = [[coder decodeObjectForKey:@"message"] retain];
            _chatItem = [[coder decodeObjectForKey:@"chatItem"] retain];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ([coder allowsKeyedCoding]) {
        if (_message) [coder encodeObject:_message forKey:@"message"];
        if (_chatItem) [coder encodeObject:_chatItem forKey:@"chatItem"];
    }
}

- (void)dealloc
{
    [_message release];
    [_chatItem release];
    [super dealloc];
}

@end

/*
 * The Lion binary exports these as ordinary __TEXT,__text C functions.
 * Public SDK/symbol indexes confirm the names but do not expose prototypes.
 * For Milestone 1 we use the geometry-helper ABI implied by the surrounding
 * RectToFitIn family: source rect + destination rect -> fitted NSRect.
 * Runtime use will be validated separately before relying on their geometry
 * semantics.
 */
NSRect RectToFitInAccordingToHeight(NSRect source, NSRect destination)
{
    if (source.size.height == 0.0) {
        return source;
    }

    source.size.width *= destination.size.height / source.size.height;
    source.size.height = destination.size.height;
    source.origin.x = NSMidX(destination) - source.size.width / 2.0;
    source.origin.y = destination.origin.y;
    return source;
}

NSRect RectToFitInAccordingToWidth(NSRect source, NSRect destination)
{
    if (source.size.width == 0.0) {
        return source;
    }

    source.size.height *= destination.size.width / source.size.width;
    source.size.width = destination.size.width;
    source.origin.x = destination.origin.x;
    source.origin.y = NSMidY(destination) - source.size.height / 2.0;
    return source;
}

static void IMRFLogIvar(Class cls, const char *name)
{
    Ivar ivar = class_getInstanceVariable(cls, name);
    if (ivar) {
        fprintf(stderr, "[IMRenderingFoundationCompat] %s.%s = %ld\n",
                class_getName(cls), name, (long)ivar_getOffset(ivar));
    }
}

__attribute__((constructor))
static void IMRenderingFoundationCompatInitialize(void)
{
    fprintf(stderr, "[IMRenderingFoundationCompat] loaded (launch-only, x86_64 ABI)\n");
    fprintf(stderr, "[IMRenderingFoundationCompat] sizeof(BaseInstantMessage)=%lu sizeof(ArchivedMessagePlaceholder)=%lu\n",
            (unsigned long)class_getInstanceSize([BaseInstantMessage class]),
            (unsigned long)class_getInstanceSize([ArchivedMessagePlaceholder class]));
    IMRFLogIvar([BaseInstantMessage class], "_bgColor");
    IMRFLogIvar([ArchivedMessagePlaceholder class], "_message");
    IMRFLogIvar([ArchivedMessagePlaceholder class], "_chatItem");
}
