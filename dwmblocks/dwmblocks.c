#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#include <X11/Xlib.h>

#include "runtime.h"

#define NILL                            INT_MIN
#define LENGTH(X)                       (sizeof X / sizeof X[0])
#define DELIMITERLENGTH                 (sizeof delimiter)
#define STATUSLENGTH                    (LENGTH(blocks) * (CMDOUTLENGTH + DELIMITERLENGTH + 1))
#define NS                              1000000000LL

#include "config.h"

_Static_assert(INTERVALs >= 0, "INTERVALs must be non-negative");
_Static_assert(INTERVALn >= 0 && INTERVALn < NS, "INTERVALn must be less than one second");
_Static_assert(INTERVALs > 0 || INTERVALn > 0, "the interval must be greater than zero");
_Static_assert(BLOCKTIMEOUTs > 0, "BLOCKTIMEOUTs must be greater than zero");

static void cleanup(void);
static int configure(void);
static void handleclick(int value);
static long long monotonicns(void);
static void reapchildren(void);
static int runblock(Block *block, int sigval, char *output, size_t *length);
static void runintervals(long long *nexttick, unsigned long long *tick, long long interval);
static void setblockfailed(Block *block, const char *reason);
static void statusloop(void);
static void updateblock(Block *block, int sigval);
static void updatestatus(void);
static int writepid(void);

static Block *dirtyblock;
static Display *dpy;
static int lockfd = -1;
static int lockowned;
static char lockpath[PATH_MAX];
static sigset_t blocksigmask;

void
cleanup(void)
{
	if (dpy) {
		XStoreName(dpy, DefaultRootWindow(dpy), "");
		XCloseDisplay(dpy);
		dpy = NULL;
	}
	if (lockfd != -1) {
		if (lockowned)
			unlink(lockpath);
		close(lockfd);
		lockfd = -1;
		lockowned = 0;
	}
}

int
configure(void)
{
	Block *block, *other;

	sigemptyset(&blocksigmask);
	sigaddset(&blocksigmask, SIGHUP);
	sigaddset(&blocksigmask, SIGINT);
	sigaddset(&blocksigmask, SIGTERM);
	for (int sig = SIGRTMIN; sig <= SIGRTMAX; sig++)
		sigaddset(&blocksigmask, sig);
	for (block = blocks; block->pathu; block++) {
		if (block->interval < -1 || block->signal < 0
		|| block->signal > SIGRTMAX - SIGRTMIN
		|| (block->pathc && (block->signal == 0 || block->signal >= DELIMITERENDCHAR))) {
			fprintf(stderr, "dwmblocks: invalid configuration for %s\n", block->pathu);
			return -1;
		}
		for (other = blocks; other < block; other++)
			if (block->signal > 0 && block->signal == other->signal) {
				fprintf(stderr, "dwmblocks: duplicate signal %d\n", block->signal);
				return -1;
			}
	}
	if (sigprocmask(SIG_BLOCK, &blocksigmask, NULL) == -1) {
		perror("dwmblocks: sigprocmask");
		return -1;
	}
	return 0;
}

void
handleclick(int value)
{
	char button[12];
	Block *block;
	pid_t pid;
	int signal = value >> 8;
	int number = value & 0xff;
	sigset_t empty;

	if (number < 1 || number > 9)
		return;
	for (block = blocks; block->pathu; block++)
		if (block->signal == signal && block->pathc)
			break;
	if (!block->pathu)
		return;
	if ((pid = fork()) == -1) {
		perror("dwmblocks: click fork");
		return;
	}
	if (pid == 0) {
		sigemptyset(&empty);
		sigprocmask(SIG_SETMASK, &empty, NULL);
		setsid();
		snprintf(button, sizeof button, "%d", number);
		execl(block->pathc, block->pathc, button, (char *)NULL);
		perror("dwmblocks: click exec");
		_exit(127);
	}
}

long long
monotonicns(void)
{
	struct timespec now;

	if (clock_gettime(CLOCK_MONOTONIC, &now) == -1) {
		perror("dwmblocks: clock_gettime");
		exit(1);
	}
	return now.tv_sec * NS + now.tv_nsec;
}

void
reapchildren(void)
{
	while (waitpid(-1, NULL, WNOHANG) > 0);
}

int
runblock(Block *block, int sigval, char *output, size_t *length)
{
	char discard[256] = {0};
	int fd[2], status = 0, timedout = 0, childdone = 0, pipeopen = 1;
	long long deadline = monotonicns() + (long long)BLOCKTIMEOUTs * NS;
	pid_t pid;
	sigset_t empty;
	size_t used = 0;

	if (pipe(fd) == -1) {
		perror("dwmblocks: pipe");
		return -1;
	}
	if ((pid = fork()) == -1) {
		perror("dwmblocks: fork");
		close(fd[0]);
		close(fd[1]);
		return -1;
	}
	if (pid == 0) {
		char value[32];

		setpgid(0, 0);
		sigemptyset(&empty);
		sigprocmask(SIG_SETMASK, &empty, NULL);
		close(fd[0]);
		if (fd[1] != STDOUT_FILENO) {
			if (dup2(fd[1], STDOUT_FILENO) == -1)
				_exit(126);
			close(fd[1]);
		}
		if (sigval == NILL)
			execl(block->pathu, block->pathu, (char *)NULL);
		snprintf(value, sizeof value, "%d", sigval);
		execl(block->pathu, block->pathu, value, (char *)NULL);
		perror("dwmblocks: block exec");
		_exit(127);
	}
	close(fd[1]);
	if (setpgid(pid, pid) == -1 && errno != EACCES && errno != ESRCH)
		perror("dwmblocks: setpgid");
	while (!childdone || pipeopen) {
		long long remaining = deadline - monotonicns();
		struct pollfd pfd = { .fd = fd[0], .events = POLLIN | POLLHUP };
		int timeout, ready;

		if (remaining <= 0) {
			timedout = 1;
			break;
		}
		timeout = remaining / 1000000 > 50 ? 50 : (int)((remaining + 999999) / 1000000);
		ready = pipeopen ? poll(&pfd, 1, timeout) : poll(NULL, 0, timeout);
		if (ready == -1 && errno != EINTR) {
			perror("dwmblocks: poll");
			break;
		}
		if (ready > 0 && (pfd.revents & (POLLIN | POLLHUP))) {
			ssize_t n;
			char *dest = used < CMDOUTLENGTH ? output + used : discard;
			size_t available = used < CMDOUTLENGTH ? CMDOUTLENGTH - used : sizeof discard;

			n = read(fd[0], dest, available);
			if (n > 0 && used < CMDOUTLENGTH)
				used += (size_t)n;
			else if (n == 0) {
				close(fd[0]);
				pipeopen = 0;
			} else if (n < 0 && errno != EINTR && errno != EAGAIN) {
				perror("dwmblocks: read");
				break;
			}
		}
		if (!childdone) {
			pid_t waited = waitpid(pid, &status, WNOHANG);
			if (waited == pid)
				childdone = 1;
			else if (waited == -1 && errno != EINTR) {
				perror("dwmblocks: waitpid");
				break;
			}
		}
	}
	if (pipeopen)
		close(fd[0]);
	if (timedout)
		kill(-pid, SIGKILL);
	if (!childdone) {
		kill(-pid, SIGKILL);
		kill(pid, SIGKILL);
		while (waitpid(pid, &status, 0) == -1 && errno == EINTR);
	}
	if (timedout)
		return 1;
	if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
		return 2;
	output[used] = '\0';
	*length = used;
	return 0;
}

void
runintervals(long long *nexttick, unsigned long long *tick, long long interval)
{
	unsigned long long elapsed, previous;
	long long now = monotonicns();
	Block *block;

	if (now < *nexttick)
		return;
	elapsed = (unsigned long long)((now - *nexttick) / interval) + 1;
	previous = *tick;
	*tick += elapsed;
	*nexttick += (long long)elapsed * interval;
	for (block = blocks; block->pathu; block++)
		if (block->interval > 0
		&& previous / (unsigned int)block->interval != *tick / (unsigned int)block->interval)
			updateblock(block, NILL);
	updatestatus();
}

void
setblockfailed(Block *block, const char *reason)
{
	if (!block->failed)
		fprintf(stderr, "dwmblocks: %s: %s\n", block->pathu, reason);
	block->failed = 1;
}

void
updateblock(Block *block, int sigval)
{
	char output[CMDOUTLENGTH + 1], text[CMDOUTLENGTH + 1 + DELIMITERLENGTH] = {0};
	size_t length, newlength = 0;
	int result;

	result = runblock(block, sigval, output, &length);
	if (result != 0) {
		setblockfailed(block, result == 1 ? "timed out" : "command failed");
		return;
	}
	if (block->failed)
		fprintf(stderr, "dwmblocks: %s: recovered\n", block->pathu);
	block->failed = 0;
	if (length && output[length - 1] == '\n')
		length--;
	if (length) {
		if (block->pathc)
			text[newlength++] = (char)block->signal;
		memcpy(text + newlength, output, length);
		newlength += length;
		memcpy(text + newlength, delimiter, DELIMITERLENGTH);
		newlength += DELIMITERLENGTH;
	}
	if (newlength != block->length || memcmp(text, block->curtext, newlength)) {
		memcpy(block->curtext, text, newlength);
		block->length = newlength;
		if (!dirtyblock || block < dirtyblock)
			dirtyblock = block;
	}
}

void
updatestatus(void)
{
	static char statustext[STATUSLENGTH];
	char *s = statustext;
	Block *block;

	if (!dirtyblock)
		return;
	for (block = blocks; block < dirtyblock; block++)
		s += block->length;
	for (; block->pathu; block++) {
		memcpy(s, block->curtext, block->length);
		s += block->length;
	}
	s[s == statustext ? 0 : -(int)DELIMITERLENGTH] = '\0';
	dirtyblock = NULL;
	XStoreName(dpy, DefaultRootWindow(dpy), statustext);
	XSync(dpy, False);
}

void
statusloop(void)
{
	const long long interval = (long long)INTERVALs * NS + INTERVALn;
	long long nexttick = monotonicns() + interval;
	unsigned long long tick = 0;
	Block *block;

	for (block = blocks; block->pathu; block++)
		if (block->interval >= 0)
			updateblock(block, NILL);
	if (!dirtyblock)
		dirtyblock = blocks;
	updatestatus();
	for (;;) {
		struct timespec timeout;
		siginfo_t info;
		long long remaining;
		int sig;

		runintervals(&nexttick, &tick, interval);
		remaining = nexttick - monotonicns();
		if (remaining < 0)
			remaining = 0;
		timeout.tv_sec = remaining / NS;
		timeout.tv_nsec = remaining % NS;
		reapchildren();
		sig = sigtimedwait(&blocksigmask, &info, &timeout);
		if (sig == SIGHUP || sig == SIGINT || sig == SIGTERM)
			return;
		if (sig == SIGRTMIN) {
			handleclick(info.si_value.sival_int);
			continue;
		}
		if (sig > SIGRTMIN) {
			for (block = blocks; block->pathu; block++)
				if (block->signal == sig - SIGRTMIN) {
					updateblock(block, info.si_value.sival_int);
					break;
				}
			updatestatus();
			continue;
		}
		if (sig == -1 && errno != EAGAIN && errno != EINTR) {
			perror("dwmblocks: sigtimedwait");
			return;
		}
		if (sig == -1 && (errno == EINTR || errno == EAGAIN))
			continue;
	}
}

int
writepid(void)
{
	struct flock fl = { .l_type = F_WRLCK, .l_whence = SEEK_SET };
	struct stat st;

	if (getlockpath(lockpath, sizeof lockpath) == -1) {
		perror("dwmblocks: runtime path");
		return -1;
	}
	lockfd = open(lockpath, O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0600);
	if (lockfd == -1) {
		perror("dwmblocks: lock open");
		return -1;
	}
	if (fstat(lockfd, &st) == -1 || !S_ISREG(st.st_mode) || st.st_uid != getuid()
	|| st.st_nlink != 1) {
		fputs("dwmblocks: unsafe lock file\n", stderr);
		return -1;
	}
	if (fcntl(lockfd, F_SETLK, &fl) == -1) {
		if (errno == EACCES || errno == EAGAIN)
			fputs("dwmblocks: another instance is already running on this display\n", stderr);
		else
			perror("dwmblocks: lock");
		return -1;
	}
	lockowned = 1;
	if (fchmod(lockfd, 0600) == -1 || ftruncate(lockfd, 0) == -1
	|| dprintf(lockfd, "%ld\n", (long)getpid()) < 0) {
		perror("dwmblocks: lock write");
		return -1;
	}
	return 0;
}

int
main(void)
{
	int xfd, status = 1;

	if (configure() == -1 || writepid() == -1)
		goto done;
	if (!(dpy = XOpenDisplay(NULL))) {
		fputs("dwmblocks: could not open display\n", stderr);
		goto done;
	}
	xfd = ConnectionNumber(dpy);
	if (fcntl(xfd, F_SETFD, fcntl(xfd, F_GETFD) | FD_CLOEXEC) == -1) {
		perror("dwmblocks: display cloexec");
		goto done;
	}
	statusloop();
	status = 0;
done:
	cleanup();
	return status;
}
