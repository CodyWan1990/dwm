#include <stdio.h>
#include <X11/Xlib.h>

int
main(void)
{
	char *name = NULL;
        Display *dpy;

        if (!(dpy = XOpenDisplay(NULL))) {
                fputs("Error: could not open display.\n", stderr);
                return 1;
        }
        if (XFetchName(dpy, DefaultRootWindow(dpy), &name) && name)
                puts(name);
        else
                fputs("No name has been set for the root window.\n", stderr);
	if (name)
		XFree(name);
        XCloseDisplay(dpy);
        return 0;
}
