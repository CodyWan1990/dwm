#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "runtime.h"

int
getlockpath(char *path, size_t size)
{
	char display[128];
	const char *dir, *value;
	struct stat st;
	size_t i;
	int n;

	dir = getenv("XDG_RUNTIME_DIR");
	value = getenv("DISPLAY");
	if (!dir || !*dir || !value || !*value) {
		errno = ENOENT;
		return -1;
	}
	if (stat(dir, &st) == -1)
		return -1;
	if (!S_ISDIR(st.st_mode) || st.st_uid != getuid() || (st.st_mode & 0022)) {
		errno = EPERM;
		return -1;
	}
	if (strlen(value) >= sizeof display) {
		errno = ENAMETOOLONG;
		return -1;
	}
	for (i = 0; value[i]; i++)
		display[i] = isalnum((unsigned char)value[i]) || value[i] == '-'
		             || value[i] == '_' || value[i] == '.' ? value[i] : '_';
	display[i] = '\0';
	n = snprintf(path, size, "%s/dwmblocks-%s.pid", dir, display);
	if (n < 0 || (size_t)n >= size) {
		errno = ENAMETOOLONG;
		return -1;
	}
	return 0;
}
