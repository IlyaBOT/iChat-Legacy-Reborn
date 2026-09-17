#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <Security/SecACL.h>
#include <stdint.h>

/*
 * Security compatibility layer for running Lion-era iChat components on
 * Mac OS X Snow Leopard 10.6.8.
 *
 * These exports were added only after they were observed as unresolved
 * imports from Lion IMFoundation 800 when linked against Snow Leopard's
 * Security.framework.
 */

typedef uint16_t SecKeychainPromptSelectorCompat;

CFStringRef const kSecACLAuthorizationDecrypt = CFSTR("decrypt");

OSStatus SecACLCopyContents(SecACLRef acl,
                            CFArrayRef *applicationList,
                            CFStringRef *description,
                            SecKeychainPromptSelectorCompat *promptSelector)
{
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR oldSelector;
    oldSelector.version = CSSM_ACL_KEYCHAIN_PROMPT_CURRENT_VERSION;
    oldSelector.flags = 0;

    OSStatus status = SecACLCopySimpleContents(acl,
                                               applicationList,
                                               description,
                                               &oldSelector);
    if (status == errSecSuccess && promptSelector) {
        *promptSelector = oldSelector.flags;
    }
    return status;
}

OSStatus SecACLSetContents(SecACLRef acl,
                           CFArrayRef applicationList,
                           CFStringRef description,
                           SecKeychainPromptSelectorCompat promptSelector)
{
    CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR oldSelector;
    oldSelector.version = CSSM_ACL_KEYCHAIN_PROMPT_CURRENT_VERSION;
    oldSelector.flags = promptSelector;

    return SecACLSetSimpleContents(acl,
                                   applicationList,
                                   description,
                                   &oldSelector);
}

CFArrayRef SecAccessCopyMatchingACLList(SecAccessRef accessRef,
                                        CFTypeRef authorizationTag)
{
    CSSM_ACL_AUTHORIZATION_TAG tag;
    CFArrayRef result = NULL;

    if (authorizationTag == kSecACLAuthorizationDecrypt ||
        (authorizationTag &&
         CFGetTypeID(authorizationTag) == CFStringGetTypeID() &&
         CFEqual(authorizationTag, kSecACLAuthorizationDecrypt))) {
        tag = CSSM_ACL_AUTHORIZATION_DECRYPT;
    } else {
        return NULL;
    }

    if (SecAccessCopySelectedACLList(accessRef, tag, &result) != errSecSuccess) {
        return NULL;
    }
    return result;
}
