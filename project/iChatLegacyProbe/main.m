#import <Foundation/Foundation.h>
#include <dlfcn.h>

static void probe(NSString *path)
{
    printf("\n=== dlopen: %s ===\n", [path fileSystemRepresentation]);
    dlerror();
    void *h = dlopen([path fileSystemRepresentation], RTLD_NOW | RTLD_LOCAL);
    if (!h) {
        const char *e = dlerror();
        printf("FAIL: %s\n", e ? e : "unknown loader error");
        return;
    }
    printf("OK\n");
    dlclose(h);
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (argc < 2) {
        fprintf(stderr, "usage: iChatLegacyProbe <Mach-O/framework-binary> [...]\n");
        [pool drain];
        return 2;
    }
    for (int i = 1; i < argc; ++i)
        probe([NSString stringWithUTF8String:argv[i]]);
    [pool drain];
    return 0;
}
