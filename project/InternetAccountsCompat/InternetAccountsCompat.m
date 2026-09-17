#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdio.h>

/*
 * Launch-only InternetAccounts compatibility shim for iChat 6.0.2 on
 * Mac OS X Snow Leopard 10.6.8.
 *
 * Lion iChat imports only IAPluginManager and four plugin ID constants from
 * InternetAccounts.framework. Loading the real Lion framework pulls in Lion
 * AppKit APIs such as NSTableRowView, so Milestone 1 replaces that framework
 * with this minimal ABI-compatible surface.
 *
 * This is not a functional Internet Accounts implementation.
 */

#define IA_STRING(name) NSString * const name = @#name

IA_STRING(kIAAOLPluginID);
IA_STRING(kIAGooglePluginID);
IA_STRING(kIAMobileMePluginID);
IA_STRING(kIAYahooPluginID);

@interface IAPluginManager : NSObject {
@private
    NSMutableDictionary *_plugins;             /* x86_64 offset 8 */
    NSMutableDictionary *_cachedDisplayNames;  /* x86_64 offset 16 */
    NSMutableDictionary *_cachedImagePaths;    /* x86_64 offset 24 */
}
+ (id)shared;
- (id)servicesForDomain:(id)value;
- (id)pluginIDForDomain:(id)value;
- (id)pluginIDForProviderID:(id)value;
- (id)matchingAListAccountForAccountSettings:(id)settings pluginID:(id)pluginID;
- (id)matchingAListAccountForSetupInput:(id)input discoveredResult:(id)result;
- (id)aListAccountContainingChildUID:(id)uid;
- (id)childAccountWithUID:(id)uid;
- (id)accountWithUID:(id)uid;
- (id)pluginIDForAppBundleID:(id)bundleID;
- (id)appBundleIDForPluginID:(id)pluginID;
- (id)aListPluginsSupportingServices:(id)services;
- (id)dataPluginsSupportingServices:(id)services;
- (id)applicationsForServices:(id)services outServices:(id)outServices;
- (id)applicationsForServices:(id)services;
- (id)applicationForService:(id)service;
- (id)addressBookApp;
- (id)iPhotoApp;
- (id)iChatApp;
- (id)iCalApp;
- (id)mailApp;
- (id)applicationWithBundleID:(id)bundleID;
- (void)setCachedImagePath:(id)path forApp:(id)app;
- (id)cachedImagePathForApp:(id)app;
- (void)setCachedDisplayName:(id)name forApp:(id)app;
- (id)cachedDisplayNameForApp:(id)app;
- (id)pluginWithIdentifier:(id)identifier;
- (id)allAListPlugins;
- (id)allDataPlugins;
- (id)providerOfType:(id)type;
- (id)allPlugins;
- (id)loadPlugins:(id)value;
- (id)createIAPluginAtPath:(id)path;
@end

@implementation IAPluginManager

+ (id)shared
{
    static IAPluginManager *manager = nil;
    @synchronized(self) {
        if (!manager) {
            manager = [[self alloc] init];
        }
    }
    return manager;
}

- (id)init
{
    if ((self = [super init])) {
        _plugins = [[NSMutableDictionary alloc] init];
        _cachedDisplayNames = [[NSMutableDictionary alloc] init];
        _cachedImagePaths = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_plugins release];
    [_cachedDisplayNames release];
    [_cachedImagePaths release];
    [super dealloc];
}

- (id)servicesForDomain:(id)value { (void)value; return nil; }
- (id)pluginIDForDomain:(id)value { (void)value; return nil; }
- (id)pluginIDForProviderID:(id)value { (void)value; return nil; }
- (id)matchingAListAccountForAccountSettings:(id)settings pluginID:(id)pluginID { (void)settings; (void)pluginID; return nil; }
- (id)matchingAListAccountForSetupInput:(id)input discoveredResult:(id)result { (void)input; (void)result; return nil; }
- (id)aListAccountContainingChildUID:(id)uid { (void)uid; return nil; }
- (id)childAccountWithUID:(id)uid { (void)uid; return nil; }
- (id)accountWithUID:(id)uid { (void)uid; return nil; }
- (id)pluginIDForAppBundleID:(id)bundleID { (void)bundleID; return nil; }
- (id)appBundleIDForPluginID:(id)pluginID { (void)pluginID; return nil; }
- (id)aListPluginsSupportingServices:(id)services { (void)services; return [NSArray array]; }
- (id)dataPluginsSupportingServices:(id)services { (void)services; return [NSArray array]; }
- (id)applicationsForServices:(id)services outServices:(id)outServices { (void)services; (void)outServices; return [NSArray array]; }
- (id)applicationsForServices:(id)services { (void)services; return [NSArray array]; }
- (id)applicationForService:(id)service { (void)service; return nil; }
- (id)addressBookApp { return nil; }
- (id)iPhotoApp { return nil; }
- (id)iChatApp { return nil; }
- (id)iCalApp { return nil; }
- (id)mailApp { return nil; }
- (id)applicationWithBundleID:(id)bundleID { (void)bundleID; return nil; }

- (void)setCachedImagePath:(id)path forApp:(id)app
{
    if (!app) return;
    if (path) [_cachedImagePaths setObject:path forKey:app];
    else [_cachedImagePaths removeObjectForKey:app];
}

- (id)cachedImagePathForApp:(id)app
{
    return app ? [_cachedImagePaths objectForKey:app] : nil;
}

- (void)setCachedDisplayName:(id)name forApp:(id)app
{
    if (!app) return;
    if (name) [_cachedDisplayNames setObject:name forKey:app];
    else [_cachedDisplayNames removeObjectForKey:app];
}

- (id)cachedDisplayNameForApp:(id)app
{
    return app ? [_cachedDisplayNames objectForKey:app] : nil;
}

- (id)pluginWithIdentifier:(id)identifier
{
    return identifier ? [_plugins objectForKey:identifier] : nil;
}

- (id)allAListPlugins { return [NSArray array]; }
- (id)allDataPlugins { return [NSArray array]; }
- (id)providerOfType:(id)type { (void)type; return nil; }
- (id)allPlugins { return [_plugins allValues]; }
- (id)loadPlugins:(id)value { (void)value; return nil; }
- (id)createIAPluginAtPath:(id)path { (void)path; return nil; }

@end

__attribute__((constructor))
static void InternetAccountsCompatInitialize(void)
{
    fprintf(stderr, "[InternetAccountsCompat] loaded (launch-only, x86_64 ABI)\n");
    fprintf(stderr, "[InternetAccountsCompat] sizeof(IAPluginManager)=%lu\n",
            (unsigned long)class_getInstanceSize([IAPluginManager class]));
}
