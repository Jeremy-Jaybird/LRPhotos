# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LR2ApplePhotos (forked from LRPhotos) is a Lightroom Classic publish service plugin that exports photos to Apple's Photos app. It uses Lua for the Lightroom SDK integration and AppleScript for Photos.app automation.

## Build and Installation

### Development Installation
```bash
# Copy plugin to Lightroom modules (after building AppleScript apps)
./install.sh
```
This copies files to:
- `~/Library/Application Support/Adobe/Lightroom/Modules/LRPhotos.lrplugin`
- `~/Library/Script Libraries/` (AppleScript libraries)
- `~/Library/Services/` (Automator workflow)

### Packaging
```bash
./package.sh
```
**Note**: package.sh references external AppleScript library paths from the original developer's machine. These need to be updated or the libraries need to be committed to the repo.

### AppleScript Compilation
The `.applescript` source files must be compiled to `.app` bundles using Script Editor or `osacompile`:
```bash
osacompile -o PhotosImport.app PhotosImport.applescript
```

## Architecture

### Data Flow
```
Lightroom Classic (Lua)
    │
    ├── Renders photos to temp directory
    ├── Writes session.txt (operation config)
    └── Writes photos.txt (photo descriptors)
            │
            ▼
    osascript PhotosImport.app <temp_dir>
            │
            ▼
AppleScript (reads session.txt + photos.txt)
    │
    ├── Imports photos to Photos.app
    ├── Creates/updates albums
    ├── Sets keywords (lr:<catalog>, album:<name>)
    └── Updates session.txt (done=true) + photos.txt (with Photos UUIDs)
            │
            ▼
Lightroom (polls session.txt for completion)
    │
    └── Stores Photos UUID in plugin metadata
```

### Key Files

**Lua (src/main/lrphotos.lrdevplugin/)**
| File | Purpose |
|------|---------|
| Info.lua | Plugin manifest - defines entry points, metadata, menu items |
| PhotosServiceProvider.lua | Export service definition - delegates to PhotosPublishTask |
| PhotosPublishTask.lua | Core publish logic - renders photos, manages queue, invokes AppleScript |
| PhotosAPI.lua | Helper to find photos by UUID in Lightroom catalog |
| InitPlugin.lua | Plugin initialization - creates temp directories, sets globals |
| Utils.lua | Utility functions - file paths, queue management |

**AppleScript**
| File | Purpose |
|------|---------|
| PhotosImport.applescript | Main import/remove logic - called by Lua via osascript |
| ShowPhoto.applescript | Opens specific photo in Photos.app |
| ShowAlbum.applescript | Opens specific album in Photos.app |
| PhotosMaintenance.applescript | Maintenance utilities |

**AppleScript Libraries** (in `Script Libraries/`, install to ~/Library/Script Libraries/)
- `hbPhotosUtilities.scptd` - Photos.app helper functions
- `hbPhotosServices.scptd` - Album/folder operations
- `hbStringUtilities.scptd` - String manipulation
- `hbMacRomanUtilities.scptd` - Character encoding
- `hbLogger.scptd` - Logging

**Services** (in `Services/`, install to ~/Library/Services/)
- `hbPhotosDisplayID.workflow` - Automator workflow

### IPC via Files

Communication between Lua and AppleScript uses text files in `~/Library/Caches/at.homebrew.lrphotos/`:

**session.txt** - Operation configuration
```
mode=publish|remove
albumName=/folder/album
keepOldPhotos=true|false
exportDone=true|false
hasErrors=true|false
errorMsg=<error message>
```

**photos.txt** - Photo descriptors (one per line)
```
<filepath>:<lr_uuid>:<catalog_name>:<photos_uuid>
```

### Queue System

Multiple publish operations are serialized using a file-based queue in the temp directory. Each operation creates a queue entry file; operations wait for predecessors to complete before proceeding.

## Lightroom SDK Notes

- SDK version: 3.0 minimum
- Plugin identifier: `at.homebrew.lrphotos`
- Publish service only (no export-only mode): `supportsIncrementalPublish = 'only'`
- Metadata stored per-photo: photosId, localId, catalogName, format

## Known Limitations

- Cannot delete photos from Photos.app (AppleScript limitation)
- Cannot add to shared albums (AppleScript limitation)
- Removing photos from album requires delete/recreate of album
- Modal dialogs during batch operations can cause timeouts
