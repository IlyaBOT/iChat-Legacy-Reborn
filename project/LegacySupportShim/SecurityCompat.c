#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <Security/SecACL.h>
#include <stdint.h>

/*
 * Security compatibility layer for running Lion-era iChat components on
 * Mac OS X Snow Leopard 10.6.8.
 *
 * Every export here corresponds to an unresolved import observed while
 * launching iChat 6.0.2. Prefer delegation to Snow Leopard APIs where a
 * compatible predecessor exists. Security Transforms were added later; the
 * transform exports below are intentionally launch-only stubs for Milestone 1
 * and do not implement signing or signature verification.
 */

typedef uint16_t SecKeychainPromptSelectorCompat;
typedef CFTypeRef ILRSecTransformRef;

CFStringRef const kSecACLAuthorizationDecrypt = CFSTR("decrypt");

/* Lion Security Transforms constants required by FTServices. Their exact
 * semantic values are not relied upon by the launch-only stubs below. */
CFStringRef const kSecDigestSHA1 = CFSTR("SHA1");
CFStringRef const kSecDigestTypeAttribute = CFSTR("DIGEST_TYPE");
CFStringRef const kSecInputIsAttributeName = CFSTR("INPUT_IS");
CFStringRef const kSecInputIsDigest = CFSTR("DIGEST");
CFStringRef const kSecKeyAttributeName = CFSTR("KEY");
CFStringRef const kSecSignatureAttributeName = CFSTR("SIGNATURE");
CFStringRef const kSecTransformInputAttributeName = CFSTR("INPUT");

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

ILRSecTransformRef SecSignTransformCreate(SecKeyRef key, CFErrorRef *error)
{
    (void)key;
    if (error) *error = NULL;
    return NULL;
}

ILRSecTransformRef SecVerifyTransformCreate(SecKeyRef key,
                                             CFDataRef signature,
                                             CFErrorRef *error)
{
    (void)key;
    (void)signature;
    if (error) *error = NULL;
    return NULL;
}

Boolean SecTransformSetAttribute(ILRSecTransformRef transform,
                                 CFStringRef key,
                                 CFTypeRef value,
                                 CFErrorRef *error)
{
    (void)transform;
    (void)key;
    (void)value;
    if (error) *error = NULL;
    return false;
}

CFTypeRef SecTransformExecute(ILRSecTransformRef transform, CFErrorRef *error)
{
    (void)transform;
    if (error) *error = NULL;
    return NULL;
}
