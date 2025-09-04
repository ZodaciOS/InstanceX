// ContainerShim.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>
#include <limits.h>
#include <errno.h>

typedef char *(*orig_NSHomeDirectory_t)(void);
static orig_NSHomeDirectory_t orig_NSHomeDirectory = NULL;

static char *make_container_home() {
    const char *cont = getenv("IX_CONTAINER");
    if (!cont) return NULL;
    static char buf[PATH_MAX];
    snprintf(buf, sizeof(buf), "/var/mobile/InstanceX/containers/%s", cont);
    return buf;
}

char *NSHomeDirectory(void) {
    if (!orig_NSHomeDirectory) {
        orig_NSHomeDirectory = (orig_NSHomeDirectory_t)dlsym(RTLD_NEXT, "NSHomeDirectory");
    }
    char *container = make_container_home();
    if (container) {
        return strdup(container);
    }
    if (orig_NSHomeDirectory) return orig_NSHomeDirectory();
    return strdup("/var/mobile");
}

char *getenv(const char *name) {
    static char *(*orig_getenv)(const char *) = NULL;
    if (!orig_getenv) orig_getenv = (char *(*)(const char *))dlsym(RTLD_NEXT, "getenv");
    if (!name) return orig_getenv(name);
    if (strcmp(name, "HOME") == 0) {
        char *container = make_container_home();
        if (container) return strdup(container);
    }
    return orig_getenv(name);
}

int getpwuid_r(uid_t uid, struct passwd *pwd, char *buf, size_t buflen, struct passwd **result) {
    static int (*orig_getpwuid_r)(uid_t, struct passwd*, char*, size_t, struct passwd**) = NULL;
    if (!orig_getpwuid_r) orig_getpwuid_r = dlsym(RTLD_NEXT, "getpwuid_r");
    int ret = orig_getpwuid_r(uid, pwd, buf, buflen, result);
    if (ret == 0 && result && *result) {
        const char *cont = getenv("IX_CONTAINER");
        if (cont) {
            static char pathbuf[PATH_MAX];
            snprintf(pathbuf, sizeof(pathbuf), "/var/mobile/InstanceX/containers/%s", cont);
            (*result)->pw_dir = pathbuf;
        }
    }
    return ret;
}
