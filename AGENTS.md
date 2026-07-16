# Repository Guidelines

## Project Structure & Module Organization

This repository assembles a customized X11 desktop. Core C projects live in versioned directories: `dwm-6.8/`, `dmenu-5.4/`, and `st-0.9.3/`. Supporting components are in `dwmblocks/`, `clipmenu/`, `dfm/`, and `FT-Labs-picom/`. Runtime shell helpers are grouped by purpose under `scripts/` (for example, `scripts/dwm/`, `scripts/dmenu/`, and `scripts/colorschemes/`). Applied upstream patches are retained under each component's `patches/done/` directory. The root `install.sh` installs dependencies, builds components, and deploys the desktop configuration.

## Build, Test, and Development Commands

Run component builds from the repository root:

- `make -C dwm-6.8` builds the window manager; substitute `dmenu-5.4`, `st-0.9.3`, `dwmblocks`, or `clipmenu` as needed.
- `meson setup FT-Labs-picom/build FT-Labs-picom --reconfigure` configures picom, and `meson compile -C FT-Labs-picom/build` builds it.
- `make -C clipmenu tests` runs clipmenu unit tests; `make -C clipmenu integration_tests` requires an X server/Xvfb and `xsel`.
- `meson test -C FT-Labs-picom/build` runs picom's registered unit test.
- `./install.sh` performs a full system install for supported Arch-, Debian-, or Fedora-family systems. It invokes `sudo` and changes user configuration, so review it before running.

Use `make -C <component> clean` before confirming a clean rebuild.

## Coding Style & Naming Conventions

Preserve upstream suckless C style: tabs for indentation, compact control flow, declarations near use, and lowercase function/variable names. Keep compile-time customization in `config.h` and mirror reusable defaults in `config.def.h`. Picom follows `FT-Labs-picom/.editorconfig` (tabs, width 8, 90-character lines). Shell scripts should remain POSIX `sh` where declared, use four-space indentation, quote expansions, and choose descriptive kebab-case filenames such as `dwm-volume-click.sh`.

## Testing Guidelines

There is no repository-wide test runner or coverage threshold. Run the tests belonging to the changed component. For dwm, dmenu, st, and dwmblocks, require a warning-free build and smoke-test behavior in a disposable X session. Add clipmenu unit cases to `clipmenu/tests/test_store.c`; place picom integration scenarios under `FT-Labs-picom/tests/testcases/` with matching configuration in `tests/configs/` when needed.

## Commit & Pull Request Guidelines

History favors short imperative subjects (for example, `debian update` or `dmenu improved`). Keep subjects concise but more specific: `fix Fedora picom dependencies`. Separate unrelated component changes. Pull requests should identify affected directories, describe user-visible behavior, list build/test commands run, link relevant issues or upstream patches, and include screenshots for visual changes to menus, bars, terminal rendering, or compositor effects.
