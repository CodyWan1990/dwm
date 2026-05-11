/* dwmblocks configuration for Waybar-like status bar */

/* Path to block scripts - update this to match your setup */
#define PATH(name)                      "/home/codywan/.config/suckless/scripts/dwm-blocks/"name
#define CLICK(name)                     "/home/codywan/.config/suckless/scripts/dwm-blocks/"name

/* buffer size for capturing output of the programs used for updating blocks */
#define CMDOUTLENGTH                    128

/* DELIMITERENDCHAR must be less than 32.
 * At max, DELIMITERENDCHAR - 1 number of clickable blocks are allowed.
 * Raw characters larger than DELIMITERENDCHAR and smaller than ' ' in ASCII
   character set can be used for signaling color change in status. */
#define DELIMITERENDCHAR                10

/* delimiter specified as an array of characters
 * (don't remove DELIMITERENDCHAR at the end) */
static const char delimiter[] = { ' ', '|', ' ', DELIMITERENDCHAR };

#include "block.h"

/* Interval unit: 1 interval = INTERVALs seconds + INTERVALn nanoseconds */
#define INTERVALs                       1
#define INTERVALn                       0

/* pathu   - path to script that outputs status text
 * pathc   - path to click handler script (NULL if not clickable)
 * interval - update interval in seconds (0 = once at startup, -1 = never auto-update)
 * signal  - signal number for sigdwmblocks (0 = not signalable)
 */

static Block blocks[] = {
/*      pathu                       pathc                               interval  signal */
        { PATH("dwm-battery.sh"),   NULL,                               30,       1 },
        { PATH("dwm-memory.sh"),    NULL,                               5,        2 },
        { PATH("dwm-volume.sh"),    CLICK("dwm-volume-click.sh"),       0,        3 },
        { PATH("dwm-clock.sh"),     NULL,                               30,       4 },
        { PATH("dwm-powermenu.sh"), "/home/codywan/.config/suckless/scripts/dmenu/powermenu.sh", 0, 5 },
        { NULL }
};
