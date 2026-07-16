#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#include "runtime.h"

#define NILL INT_MIN

static int parseint(const char *arg, int minimum, int maximum, const char *name);
static void sendsignal(int sig, union sigval value);

int
parseint(const char *arg, int minimum, int maximum, const char *name)
{
	char *end;
	long value;

	errno = 0;
	value = strtol(arg, &end, 10);
	if (errno == ERANGE || end == arg || *end || value < minimum || value > maximum) {
		fprintf(stderr, "sigdwmblocks: invalid %s: %s\n", name, arg);
		exit(2);
	}
	return (int)value;
}

void
sendsignal(int sig, union sigval value)
{
	char path[PATH_MAX];
	int fd;
	struct flock lock = { .l_type = F_WRLCK, .l_whence = SEEK_SET };
	struct stat st;

	if (getlockpath(path, sizeof path) == -1) {
		perror("sigdwmblocks: runtime path");
		exit(1);
	}
	fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
	if (fd == -1) {
		int error = errno;

		if (error == ENOENT)
			fputs("sigdwmblocks: no running instance on this display\n", stderr);
		else
			perror("sigdwmblocks: lock open");
		exit(error == ENOENT ? 3 : 1);
	}
	if (fstat(fd, &st) == -1 || !S_ISREG(st.st_mode) || st.st_uid != getuid()
	|| st.st_nlink != 1) {
		fputs("sigdwmblocks: unsafe lock file\n", stderr);
		close(fd);
		exit(1);
	}
	if (fcntl(fd, F_GETLK, &lock) == -1) {
		perror("sigdwmblocks: lock query");
		close(fd);
		exit(1);
	}
	close(fd);
	if (lock.l_type != F_WRLCK) {
		fputs("sigdwmblocks: no running instance on this display\n", stderr);
		exit(3);
	}
	if (sigqueue(lock.l_pid, sig, value) == -1) {
		int error = errno;

		if (error == ESRCH)
			fputs("sigdwmblocks: no running instance on this display\n", stderr);
		else
			perror("sigdwmblocks: sigqueue");
		exit(error == ESRCH ? 3 : 1);
	}
}

int
main(int argc, char *argv[])
{
	int offset;
	union sigval value;

	if (argc < 2 || argc > 3) {
		fputs("Usage: sigdwmblocks <signal> [<sigval>]\n", stderr);
		return 2;
	}
	offset = parseint(argv[1], 1, SIGRTMAX - SIGRTMIN, "signal");
	value.sival_int = argc == 2 ? NILL : parseint(argv[2], INT_MIN, INT_MAX, "value");
	sendsignal(SIGRTMIN + offset, value);
	return 0;
}
