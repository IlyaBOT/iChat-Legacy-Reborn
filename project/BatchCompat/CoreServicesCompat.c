#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

/*
 * Launch-only implementation. Lion iChat imports this private Metadata sorter,
 * but its exact semantics are not required to enter the GUI. Returning equal
 * keeps caller behavior deterministic until Metadata functionality is ported.
 */
CFComparisonResult _MDQuerySortDatesDescending(const void *a, const void *b, void *context)
{
    (void)a; (void)b; (void)context;
    return kCFCompareEqualTo;
}

__attribute__((constructor))
static void ILRCoreServicesCompatInit(void) { fprintf(stderr,"[CoreServicesCompat] loaded\n"); }
