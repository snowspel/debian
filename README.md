# Snow

A complete Hyprland desktop for **Debian 13 (trixie)**: Hyprland 0.55 (Lua config), Quickshell panels, an SDDM login screen, the NVIDIA 590 driver and a set of own apps (file manager, download manager, video player setup). No third-party dotfiles: everything is installed, checked, backed up and restored by the scripts in this folder.

Version: see `VERSION`. Changes: `Docs/CHANGELOG.md`.

## What you get

| Part | What it is |
|---|---|
| Panels | Launcher, quick settings, power menu, notifications, volume / brightness / workspace / clock OSDs, password (polkit) dialog, screenshots |
| Apps | Snow file manager (Super+E), Snow download manager (Super+D, aria2), Thunar (Super+Q), kitty, mpv, imv, yazi, Mousepad, LocalSend, Mission Center |
| Browsers | Brave Origin, LibreWolf |
| System | NVIDIA 590 (open kernel modules, VA-API), Cloudflare WARP, SDDM theme, idle / lock / screen-off timers |
| Tools | `install.sh`, `doctor.sh`, `Files/backup.sh`, `Files/restore.sh`, `Files/reset.sh` |

## Requirements

- Debian 13 (trixie), minimal install, with a normal user that has sudo.
- UEFI **Secure Boot off** (the NVIDIA driver is not signed). Without an NVIDIA GPU the driver step is skipped.
- Internet connection during the install.

## Install on a new PC

1. Copy this folder anywhere (it may have any name). Press `Ctrl+Alt+F3`, log in, `cd` into the folder.
2. `bash install.sh`. The sudo password is asked. If it asks for a reboot after the NVIDIA driver: reboot, `Ctrl+Alt+F3`, run the same command again (finished parts are quick).
3. At the end it creates `Files/original` and `Files/latest` and runs `doctor.sh`. Reboot and log in to Hyprland.

## Everyday commands

Run them from inside the folder.

| Command | What it does |
|---|---|
| `bash Files/backup.sh` | save your current files (settings, wallpaper, default apps) into `Files/latest` |
| `bash doctor.sh` | read-only health check with a final report and a solution for every warning |
| `bash Files/restore.sh` | put the last backup (or `original`) back |
| `bash Files/reset.sh` | full reset to a plain Hyprland (preview first, you type RESET) |
| `bash Script/NN-name.sh` | install / restore one part only; add `check` to only check it |
| `bash install.sh --version` | print the version (`--help` shows the usage) |

Nothing is ever saved outside this folder: replaced files go to `Docs/logs/replaced/`, backups to `Files/history/` and `Backup/`. Keep a copy of the whole folder on a USB stick or in the cloud.

## Folder layout

```
Snow/
  README.md  NOTICE.md  VERSION
  install.sh        installs / restores everything
  doctor.sh         health check
  Script/           one script per component (01 ... 30, in install order) + lib/
  Files/            backup.sh  restore.sh  reset.sh  (+ original/ latest/ history/ Plain-Files/ made by install)
  Docs/             MANUAL.md  KEYBINDS.md  CHANGELOG.md  FILE-INDEX.md  logs/  dev/
```

`Docs/dev/` holds the maintainer notes (decisions, current state, build history).

## If something looks wrong

1. `bash doctor.sh` and read the FINAL REPORT at the end.
2. Panels not showing: `bash ~/.config/snow/bin/core/qs.sh status` or `restart`; the log is `~/.cache/snow/qs.log`.
3. Hyprland config errors: `hyprctl configerrors`.

## More

- Things done by hand, before and after the install: `Docs/MANUAL.md`
- Keys: `Docs/KEYBINDS.md`
- Every file and its job: `Docs/FILE-INDEX.md`
- Third-party credits: `NOTICE.md`
- Licence of the Snow scripts: not set yet (the owner decides before the folder is shared).
