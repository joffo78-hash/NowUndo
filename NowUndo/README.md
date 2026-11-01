# NowUndo

Source repository for NowUndo, a REAPER looper project composed of a JSFX effect, Lua scripts, and web/remote-control files.

## Contents

- `NowUndo_V3.6.10 (8).jsfx` — main JSFX effect supplied in the archive.
- `Scripts/` — startup, dashboard, synchronization, virtual controller, web package, and looper opener scripts.
- `master_synchro` — synchronization support file supplied in the archive.

## Important

This repository preparation preserves the original directory layout and filenames to avoid breaking REAPER paths and action references. `Scripts/VirtualTwister.lua` has been replaced with the separate `VirtualTwister.lua` file supplied after the initial archive, because the version in the archive was an exact duplicate of `VirtualLaunchpadDisplay.lua`. No other project code has been intentionally changed.

## Installation and licensing

Installation instructions and license are not included yet; they should be documented/confirmed by the project maintainer before public distribution.


## ReaPack

This repository is prepared for ReaPack. Once the repository index has been generated, add this repository in REAPER:

1. Open **Extensions → ReaPack → Import a repository**.
2. Paste this URL:

   `https://raw.githubusercontent.com/joffo78-hash/NowUndo/main/index.xml`

3. Confirm, then use **Extensions → ReaPack → Browse packages** and search for **NowUndo**.

The index is generated from the metadata headers in the Lua and JSFX files by the GitHub Actions workflow. New releases must use a higher `@version` value in the relevant file header. ReaPack does not treat a changed file with an unchanged version as a new release.

### Package notes

- The JSFX looper and the individual Lua actions are indexed from their existing folders.
- Helper Lua files marked `@noindex` are intended to be installed as supporting files, not shown as separate actions.
- The web interface needs REAPER's Web Browser Interface enabled. The HTML page and its Lua backend must be installed together; verify the package's included files before relying on remote control.
- The existing startup script contains REAPER action command IDs from the development installation. Those IDs may not match on another REAPER installation, so the startup launcher may need local action-ID setup.

