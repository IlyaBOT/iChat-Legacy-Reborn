#include <sys/types.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <mach/mach.h>
#include <servers/bootstrap.h>
#include <uuid/uuid.h>
#include <stdio.h>

/*
 * Lion private bootstrap entry points.
 * Signatures match launchd bootstrap_priv.h. On Snow Leopard we degrade the
 * Lion-specific pid/UUID/flags behavior to the public bootstrap APIs.
 */
kern_return_t bootstrap_look_up3(mach_port_t bp, const name_t service_name, mach_port_t *sp, pid_t target_pid, const uuid_t instance_id, uint64_t flags)
{
    (void)target_pid; (void)instance_id; (void)flags;
    return bootstrap_look_up(bp, service_name, sp);
}

kern_return_t bootstrap_check_in3(mach_port_t bp, const name_t service_name, mach_port_t *sp, uuid_t instance_id, uint64_t flags)
{
    (void)instance_id; (void)flags;
    return bootstrap_check_in(bp, service_name, sp);
}

size_t strnlen(const char *s, size_t maxlen)
{
    const char *p;
    if (!s) return 0;
    p=(const char *)memchr(s,'\0',maxlen);
    return p ? (size_t)(p-s) : maxlen;
}

__attribute__((constructor))
static void ILRLibSystemCompatInit(void) { fprintf(stderr,"[LibSystemCompat] loaded\n"); }
