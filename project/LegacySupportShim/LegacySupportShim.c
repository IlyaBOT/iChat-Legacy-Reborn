#include <stdio.h>
#include <dlfcn.h>

/*
 * iChat Legacy Reborn compatibility shim.
 *
 * Do not add guessed ABI stubs here. Every exported compatibility symbol must
 * correspond to a loader failure observed on Mac OS X 10.6.8 and documented
 * in docs/analysis/missing-symbols.md.
 */

__attribute__((constructor))
static void ILRShimInitialize(void)
{
    fprintf(stderr, "[iChatLegacy] LegacySupportShim loaded\n");
}

void *ILRLookupSystemSymbol(const char *name)
{
    if (!name) {
        return NULL;
    }
    return dlsym(RTLD_DEFAULT, name);
}
