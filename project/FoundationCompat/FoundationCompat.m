#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdio.h>

/*
 * Minimal Lion NSFileWrapper compatibility class for Snow Leopard 10.6.
 *
 * Lion Foundation's NSFileWrapper is an NSObject subclass with instanceStart=8
 * and instanceSize=56 on x86_64. The six object-sized ivars below preserve that
 * layout exactly on the target architecture.
 *
 * This is intentionally a compatibility implementation, not a copy of Apple's
 * implementation. It provides the public/basic behavior needed by Lion-era
 * clients while Snow Leopard Foundation supplies the rest of Foundation.
 */

@interface NSFileWrapper : NSObject <NSCoding>
{
@private
    NSString     *_preferredFileName;
    NSString     *_fileName;
    id            _icon;
    id            _contents;
    NSDictionary *_fileAttributes;
    id            _moreVars;
}
- (id)initRegularFileWithContents:(NSData *)contents;
- (id)initDirectoryWithFileWrappers:(NSDictionary *)children;
- (id)initSymbolicLinkWithDestinationURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url options:(NSUInteger)options error:(NSError **)error;
- (BOOL)isRegularFile;
- (BOOL)isDirectory;
- (BOOL)isSymbolicLink;
- (NSData *)regularFileContents;
- (NSDictionary *)fileWrappers;
- (NSURL *)symbolicLinkDestinationURL;
- (NSString *)preferredFilename;
- (void)setPreferredFilename:(NSString *)name;
- (NSString *)filename;
- (void)setFilename:(NSString *)name;
- (NSDictionary *)fileAttributes;
- (void)setFileAttributes:(NSDictionary *)attributes;
- (BOOL)writeToURL:(NSURL *)url options:(NSUInteger)options originalContentsURL:(NSURL *)originalURL error:(NSError **)error;
@end

enum {
    ILRFileWrapperUnknown = 0,
    ILRFileWrapperRegular = 1,
    ILRFileWrapperDirectory = 2,
    ILRFileWrapperSymlink = 3
};

@implementation NSFileWrapper

- (id)init
{
    self = [super init];
    if (self) {
        _moreVars = [[NSNumber alloc] initWithInt:ILRFileWrapperUnknown];
    }
    return self;
}

- (id)initRegularFileWithContents:(NSData *)contents
{
    self = [self init];
    if (self) {
        [_contents release];
        _contents = [contents copy];
        [_moreVars release];
        _moreVars = [[NSNumber alloc] initWithInt:ILRFileWrapperRegular];
    }
    return self;
}

- (id)initDirectoryWithFileWrappers:(NSDictionary *)children
{
    self = [self init];
    if (self) {
        [_contents release];
        _contents = [children mutableCopy];
        [_moreVars release];
        _moreVars = [[NSNumber alloc] initWithInt:ILRFileWrapperDirectory];
    }
    return self;
}

- (id)initSymbolicLinkWithDestinationURL:(NSURL *)url
{
    self = [self init];
    if (self) {
        [_contents release];
        _contents = [url copy];
        [_moreVars release];
        _moreVars = [[NSNumber alloc] initWithInt:ILRFileWrapperSymlink];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url options:(NSUInteger)options error:(NSError **)error
{
    (void)options;
    if (!url) {
        [self release];
        return nil;
    }

    NSString *path = [url path];
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

    if (!exists) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        }
        [self release];
        return nil;
    }

    if (isDir) {
        self = [self initDirectoryWithFileWrappers:[NSDictionary dictionary]];
    } else {
        NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
        if (!data) {
            [self release];
            return nil;
        }
        self = [self initRegularFileWithContents:data];
    }

    if (self) {
        [self setFilename:[path lastPathComponent]];
        [self setPreferredFilename:[path lastPathComponent]];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
        [self setFileAttributes:attrs];
    }
    return self;
}

- (void)dealloc
{
    [_preferredFileName release];
    [_fileName release];
    [_icon release];
    [_contents release];
    [_fileAttributes release];
    [_moreVars release];
    [super dealloc];
}

- (int)_ilrKind
{
    return [_moreVars respondsToSelector:@selector(intValue)] ? [_moreVars intValue] : ILRFileWrapperUnknown;
}

- (BOOL)isRegularFile { return [self _ilrKind] == ILRFileWrapperRegular; }
- (BOOL)isDirectory { return [self _ilrKind] == ILRFileWrapperDirectory; }
- (BOOL)isSymbolicLink { return [self _ilrKind] == ILRFileWrapperSymlink; }

- (NSData *)regularFileContents
{
    return [self isRegularFile] ? _contents : nil;
}

- (NSDictionary *)fileWrappers
{
    return [self isDirectory] ? _contents : nil;
}

- (NSURL *)symbolicLinkDestinationURL
{
    return [self isSymbolicLink] ? _contents : nil;
}

- (NSString *)preferredFilename { return _preferredFileName; }
- (NSString *)filename { return _fileName; }

- (void)setPreferredFilename:(NSString *)name
{
    if (_preferredFileName != name) {
        [_preferredFileName release];
        _preferredFileName = [name copy];
    }
}

- (void)setFilename:(NSString *)name
{
    if (_fileName != name) {
        [_fileName release];
        _fileName = [name copy];
    }
}

- (NSDictionary *)fileAttributes { return _fileAttributes; }

- (void)setFileAttributes:(NSDictionary *)attributes
{
    if (_fileAttributes != attributes) {
        [_fileAttributes release];
        _fileAttributes = [attributes copy];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self) {
        [self setPreferredFilename:[coder decodeObjectForKey:@"NSPreferredFilename"]];
        [self setFilename:[coder decodeObjectForKey:@"NSFilename"]];
        [self setFileAttributes:[coder decodeObjectForKey:@"NSFileAttributes"]];

        id contents = [coder decodeObjectForKey:@"NSContents"];
        NSNumber *kind = [coder decodeObjectForKey:@"NSKind"];
        [_contents release];
        _contents = [contents retain];
        [_moreVars release];
        _moreVars = kind ? [kind retain] : [[NSNumber alloc] initWithInt:ILRFileWrapperUnknown];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_preferredFileName forKey:@"NSPreferredFilename"];
    [coder encodeObject:_fileName forKey:@"NSFilename"];
    [coder encodeObject:_fileAttributes forKey:@"NSFileAttributes"];
    [coder encodeObject:_contents forKey:@"NSContents"];
    [coder encodeObject:_moreVars forKey:@"NSKind"];
}

- (BOOL)writeToURL:(NSURL *)url options:(NSUInteger)options originalContentsURL:(NSURL *)originalURL error:(NSError **)error
{
    (void)options;
    (void)originalURL;

    if ([self isRegularFile]) {
        return [(NSData *)_contents writeToURL:url options:NSDataWritingAtomic error:error];
    }

    if ([self isDirectory]) {
        NSString *path = [url path];
        return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:_fileAttributes error:error];
    }

    if ([self isSymbolicLink]) {
        NSString *dst = [(NSURL *)_contents path];
        return [[NSFileManager defaultManager] createSymbolicLinkAtPath:[url path] withDestinationPath:dst error:error];
    }

    return NO;
}

@end

__attribute__((constructor))
static void FoundationCompatInitialize(void)
{
    fprintf(stderr, "[FoundationCompat] NSFileWrapper compatibility class loaded; size=%lu\n",
            (unsigned long)class_getInstanceSize([NSFileWrapper class]));
}
