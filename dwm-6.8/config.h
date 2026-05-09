/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int gappx     = 15;        /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int swallowfloating    = 0;        /* 1 means swallow floating windows by default */
static const unsigned int systraypinning = 2;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 0;    /* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;        /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "Monofur Nerd Font Propo:size=14", "monospace:size=12" };
static const char dmenufont[]       = "Monofur Nerd Font Propo:size=14";
/* Colorschemes ported from the user's Niri themes
 * see ~/scripts/theming/colorschemes/
 * Per scheme, four variants:
 *   SchemeNorm  = { FG,     BG,        COMMENT  }   normal text + inactive border
 *   SchemeSel   = { BLUE,   SELECTION, BLUE     }   selected/focused
 *   SchemeLabel = { BLUE,   BG,        COMMENT  }   status label background
 *   SchemeOcc   = { YELLOW, BG,        COMMENT  }   occupied but unfocused tag
 * Cycle with Mod+Shift+T (forward) / Mod+Ctrl+T (back). Index 0 is the startup theme. */
static const char *colors[][SchemeN][3] = {
	/* 0 - Monokai Pro */ {
		[SchemeNorm]  = { "#fcfcfa", "#2d2a2e", "#727072" },
		[SchemeSel]   = { "#78dce8", "#403e41", "#78dce8" },
		[SchemeLabel] = { "#78dce8", "#2d2a2e", "#727072" },
		[SchemeOcc]   = { "#ffd866", "#2d2a2e", "#727072" },
	},
	/* 1 - Gruvbox */ {
		[SchemeNorm]  = { "#ebdbb2", "#282828", "#928374" },
		[SchemeSel]   = { "#83a598", "#3c3836", "#83a598" },
		[SchemeLabel] = { "#83a598", "#282828", "#928374" },
		[SchemeOcc]   = { "#fabd2f", "#282828", "#928374" },
	},
	/* 2 - Catppuccin Mocha */ {
		[SchemeNorm]  = { "#cdd6f4", "#1e1e2e", "#6c7086" },
		[SchemeSel]   = { "#89b4fa", "#313244", "#89b4fa" },
		[SchemeLabel] = { "#89b4fa", "#1e1e2e", "#6c7086" },
		[SchemeOcc]   = { "#f9e2af", "#1e1e2e", "#6c7086" },
	},
	/* 3 - Dracula */ {
		[SchemeNorm]  = { "#f8f8f2", "#282a36", "#6272a4" },
		[SchemeSel]   = { "#bd93f9", "#44475a", "#bd93f9" },
		[SchemeLabel] = { "#bd93f9", "#282a36", "#6272a4" },
		[SchemeOcc]   = { "#f1fa8c", "#282a36", "#6272a4" },
	},
	/* 4 - Nord */ {
		[SchemeNorm]  = { "#eceff4", "#2e3440", "#4c566a" },
		[SchemeSel]   = { "#81a1c1", "#3b4252", "#81a1c1" },
		[SchemeLabel] = { "#81a1c1", "#2e3440", "#4c566a" },
		[SchemeOcc]   = { "#ebcb8b", "#2e3440", "#4c566a" },
	},
	/* 5 - Tokyo Night */ {
		[SchemeNorm]  = { "#c0caf5", "#1a1b26", "#565f89" },
		[SchemeSel]   = { "#7aa2f7", "#292e42", "#7aa2f7" },
		[SchemeLabel] = { "#7aa2f7", "#1a1b26", "#565f89" },
		[SchemeOcc]   = { "#e0af68", "#1a1b26", "#565f89" },
	},
	/* 6 - Rose Pine */ {
		[SchemeNorm]  = { "#e0def4", "#191724", "#6e6a86" },
		[SchemeSel]   = { "#31748f", "#26233a", "#31748f" },
		[SchemeLabel] = { "#31748f", "#191724", "#6e6a86" },
		[SchemeOcc]   = { "#f6c177", "#191724", "#6e6a86" },
	},
	/* 7 - Kanagawa */ {
		[SchemeNorm]  = { "#dcd7ba", "#1f1f28", "#727169" },
		[SchemeSel]   = { "#7e9cd8", "#2a2a37", "#7e9cd8" },
		[SchemeLabel] = { "#7e9cd8", "#1f1f28", "#727169" },
		[SchemeOcc]   = { "#e6c384", "#1f1f28", "#727169" },
	},
	/* 8 - One Dark */ {
		[SchemeNorm]  = { "#abb2bf", "#282c34", "#5c6370" },
		[SchemeSel]   = { "#61afef", "#3e4452", "#61afef" },
		[SchemeLabel] = { "#61afef", "#282c34", "#5c6370" },
		[SchemeOcc]   = { "#e5c07b", "#282c34", "#5c6370" },
	},
	/* 9 - Everforest */ {
		[SchemeNorm]  = { "#d3c6aa", "#2d353b", "#859289" },
		[SchemeSel]   = { "#7fbbb3", "#3d484d", "#7fbbb3" },
		[SchemeLabel] = { "#7fbbb3", "#2d353b", "#859289" },
		[SchemeOcc]   = { "#dbbc7f", "#2d353b", "#859289" },
	},
	/* 10 - Solarized Dark */ {
		[SchemeNorm]  = { "#839496", "#002b36", "#586e75" },
		[SchemeSel]   = { "#268bd2", "#073642", "#268bd2" },
		[SchemeLabel] = { "#268bd2", "#002b36", "#586e75" },
		[SchemeOcc]   = { "#b58900", "#002b36", "#586e75" },
	},
};

/* Maps each colors[] index to the basename of its file in
 * ~/scripts/theming/colorschemes/<name>.sh — used by applyscheme() to keep
 * dwmblocks in sync. KEEP IN ORDER WITH colors[]. */
static const char *colorscheme_files[] = {
	"monokai",          /* 0 - Monokai Pro */
	"gruvbox",          /* 1 - Gruvbox */
	"catppuccin-mocha", /* 2 - Catppuccin Mocha */
	"dracula",          /* 3 - Dracula */
	"nord",             /* 4 - Nord */
	"tokyonight",       /* 5 - Tokyo Night */
	"rose-pine",        /* 6 - Rose Pine */
	"kanagawa",         /* 7 - Kanagawa */
	"onedark",          /* 8 - One Dark */
	"everforest",       /* 9 - Everforest */
	"solarized-dark",   /* 10 - Solarized Dark */
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const unsigned int ulinepad		= 5;	/* horizontal padding between the underline and tag */
static const unsigned int ulinestroke	= 2;	/* thickness / height of the underline */
static const unsigned int ulinevoffset	= 0;	/* how far above the bottom of the bar the line should appear */
static const int ulineall				= 0;	/* 1 to show underline on all tags, 0 for just the active ones */

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class     instance  title           tags mask  isfloating  isterminal  noswallow  monitor */
	{ "Gimp",    NULL,     NULL,           0,         1,          0,           0,        -1 },
	{ "Firefox", NULL,     NULL,           1 << 8,    0,          0,          -1,        -1 },
	{ "St",      NULL,     NULL,           0,         0,          1,           0,        -1 },
	{ NULL,      NULL,     "Event Tester", 0,         0,          0,           1,        -1 }, /* xev */
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

#define STATUSBAR "dwmblocks"

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
/* Generic "run any binary in $PATH" — themed dmenu_run. Bound to Mod+Alt+Space. */
static const char *dmenucmd[]    = { "/home/codywan/scripts/dmenu/dmenu-themed.sh", "-m", dmenumon, NULL };
/* .desktop-aware launcher (apps + flatpaks only) — themed. Bound to Mod+Space. */
static const char *appscmd[]     = { "/home/codywan/scripts/dmenu/dmenu-apps.sh", NULL };
/* Clipboard history (clipmenud must be running). Bound to Mod+V. */
static const char *clipmenucmd[] = { "/home/codywan/scripts/dmenu/clipmenu-themed.sh", NULL };
/* DFM file manager — themed via PATH shim. Bound to Mod+Alt+F. */
static const char *dfmcmd[]      = { "/home/codywan/scripts/dmenu/dfm-themed.sh", NULL };
/* Power menu (Logout / Reboot / Shutdown) — themed dmenu. Bound to Ctrl+Alt+Delete. */
static const char *powermenucmd[] = { "/home/codywan/scripts/dmenu/powermenu.sh", NULL };
static const char *termcmd[]  = { "st", NULL };

#include "movestack.c"
static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_space,  spawn,          {.v = appscmd } },
	{ MODKEY|Mod1Mask,              XK_space,  spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_v,      spawn,          {.v = clipmenucmd } },
	{ MODKEY|Mod1Mask,              XK_f,      spawn,          {.v = dfmcmd } },
	{ ControlMask|Mod1Mask,         XK_Delete, spawn,          {.v = powermenucmd } },
	{ MODKEY|ShiftMask,             XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_Down,   focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_Up,     focusstack,     {.i = -1 } },
    { MODKEY,                       XK_h,      focusmaster,    {0} },
    { MODKEY,                       XK_Left,   focusmaster,    {0} },
    { MODKEY,                       XK_l,      focusmaster,    {0} },
    { MODKEY,                       XK_Right,  focusmaster,    {0} },
    { MODKEY|ShiftMask,             XK_Left,   zoom,           {0} },
    { MODKEY|ShiftMask,             XK_Right,  movestack,      {.i = +1} },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,      movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Down,   movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Up,     movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_equal,  incnmaster,     {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_minus,  incnmaster,     {.i = -1 } },
	{ MODKEY|ControlMask,           XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY|ControlMask,           XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ControlMask,           XK_Left,   setmfact,       {.f = -0.05} },
	{ MODKEY|ControlMask,           XK_Right,  setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY,                       XK_BackSpace, killclient,  {0} },
	{ MODKEY|ShiftMask,             XK_t,      setscheme,      {.i = +1} },
	{ MODKEY|ControlMask,           XK_t,      setscheme,      {.i = -1} },
	{ MODKEY|ShiftMask,             XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_p,      setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
    { MODKEY|ControlMask,           XK_f,      fullscreen,     {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
    { MODKEY|ControlMask,           XK_comma,  cyclelayout,    {.i = -1 } },
    { MODKEY|ControlMask,           XK_period, cyclelayout,    {.i = +1 } },
	{ MODKEY,                       XK_minus,  setgaps,        {.i = -1 } },
	{ MODKEY,                       XK_equal,  setgaps,        {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_g,      setgaps,        {.i = 0  } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
	{ ClkStatusText,        0,              Button4,        sigstatusbar,   {.i = 4} },
	{ ClkStatusText,        0,              Button5,        sigstatusbar,   {.i = 5} },
	{ ClkStatusText,        0,              6,              sigstatusbar,   {.i = 6} },
	{ ClkStatusText,        0,              7,              sigstatusbar,   {.i = 7} },
	{ ClkStatusText,        0,              8,              sigstatusbar,   {.i = 8} },
	{ ClkStatusText,        0,              9,              sigstatusbar,   {.i = 9} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
