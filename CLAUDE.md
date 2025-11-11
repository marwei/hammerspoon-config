# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Hammerspoon configuration for macOS automation and window management. Hammerspoon is a macOS automation tool that bridges Lua scripting with system-level APIs.

**Official Documentation**: https://www.hammerspoon.org/docs/

## Architecture

### Core Components

**Entry Point (`init.lua`)**
- Loads all libraries and modules in order
- Sets up global hotkeys for reload (Hyper+R), hotkey cheatsheet (Hyper+H), console toggle (Hyper+Z), and resize mode (Hyper+M)
- Configures global timers and screen watchers
- Disables animations for instant feedback

**Hyper Key System (`hyper.lua`)**
- Defines `hyper` as the modifier combination: cmd+alt+shift+ctrl
- Karabiner-Elements handles the actual Hyper key mapping (e.g., Capslock → Hyper, with tap-to-ESC functionality)
- The modal in hyper.lua may reference F18 binding but this is handled externally by Karabiner-Elements
- This is a critical system component - be careful when modifying as bugs can cause stuck modifiers

**Configuration (`config.lua`)**
- Defines `applist` array with application shortcuts
- Defines `module_list` array specifying which modal modules to load
- Controls `show_modal` flag for visual feedback

### Modal Systems

The configuration uses Hammerspoon modals for different contexts:

**Application Modal (`modals/application.lua`)**
- Activated by Hyper+A (must be bound in config)
- Launches or focuses applications based on `applist` in config.lua
- Shows green modal light when active
- Auto-exits after launching an app

**Window Resize Modal (`modals/window.lua`)**
- Activated by Hyper+M
- Provides comprehensive window management functions
- Shows red modal light (firebrick) when active
- Key features:
  - Basic positioning: H (left half), L (right half), J (down half), K (up half)
  - Corners: W (NW), E (NE), S (SW), D (SE)
  - Double-press H or L for quarter-width windows
  - Fullscreen (F), center (C), floating center (Shift+C)
  - Incremental resize: = (expand), - (shrink)
  - Incremental move: Shift+HJKL
  - Multi-monitor: arrow keys or space to move between displays
  - Window cycling: [ and ] to focus other windows
  - Cursor centering: ` to center cursor in window
- Maintains state in `prev_direction` for double-press detection

**Modal Display System (`lib/modal_display.lua`)**
- `toggle_modal_light(color, alpha)`: Shows/hides a circular indicator in top-right corner
- `toggle_modal_key_display()`: Shows/hides hotkey cheatsheet overlay
- Both functions are toggles - calling again removes the display

### Fn Key Navigation (`fn.lua`)

Custom Fn+key bindings using eventtap:
- Fn+H/J/K/L: Arrow keys (left/down/up/right)
- Fn+Y/O: Horizontal scroll
- Fn+U/I: Vertical scroll
- Fn+,: Left click at cursor
- Fn+.: Right click at cursor

### Libraries

**Style (`lib/style.lua`)**: Color constants using Hammerspoon drawing color APIs

**Utility (`lib/utility.lua`)**: Helper functions like `is_in()` and `print_table()`

## Development Workflow

### Testing Changes

1. Save changes to any `.lua` file
2. Press Hyper+R (or Cmd+Alt+Shift+Ctrl+R) to reload configuration
3. Check console (Hyper+Z) for any errors

### Adding New Applications

Edit `applist` in `config.lua`:
```lua
applist = {
    {shortcut = 'i', appname = 'iTerm'},
    -- add new entry
}
```

### Adding New Modals

1. Create new file in `modals/` directory
2. Add to `module_list` in `config.lua`
3. Bind activation hotkey in `init.lua`
4. Use `toggle_modal_light()` and `toggle_modal_key_display()` for visual feedback

### Debugging

- Use `print()` statements (output goes to Hammerspoon console)
- Access console with Hyper+Z
- Use `hs.alert.show("message")` for temporary on-screen alerts
- Check `hs.hotkey.getHotkeys()` to debug hotkey conflicts

## Important Conventions

### Global Variables

Global variables are used throughout for state management:
- Modal objects: `appM`, `resizeM`
- Display objects: `modal_light`, `hotkeytext`, `hotkeybg`, `modal_tray`, etc.
- State: `prev_direction`, `resize_win_list`, `resize_current_winnum`
- Timers/watchers: `globalGC`, `globalScreenWatcher`, `fn_tapper`

### Coordinate Systems

Window positioning uses Hammerspoon's local/absolute coordinate system:
- `screen:absoluteToLocal()` converts global coordinates to screen-relative
- `screen:localToAbsolute()` converts screen-relative to global coordinates
- Always convert coordinates when working with multi-monitor setups

### Modal Pattern

Standard modal structure:
```lua
modalM = hs.hotkey.modal.new()

function modalM:entered()
  toggle_modal_light(color, 0.7)
  if show_modal then toggle_modal_key_display() end
end

function modalM:exited()
  toggle_modal_light(color, 0.7)
  if show_modal then toggle_modal_key_display() end
end

modalM:bind('', 'escape', function() modalM:exit() end)
```

## Common Issues

**Hyper Key Not Working**
- Check Karabiner-Elements configuration for Hyper key mapping
- Verify that `hyper` array in hyper.lua matches the modifiers (cmd+alt+shift+ctrl)
- Test with Hammerspoon console open (Hyper+Z) to see if events are firing
- Ensure Hammerspoon has accessibility permissions in System Preferences

**Modal Stuck Active**
- Modal light/display persists if toggle functions called odd number of times
- Fix by manually calling toggle again or deleting globals and reloading

**Windows Not Resizing**
- Check if window is resizable (some apps restrict resizing)
- Verify screen coordinates with `hs.screen.mainScreen():fullFrame()`

**Memory Leaks**
- Global garbage collection runs every 180 seconds
- Screen watcher cleans up display objects on screen change
- When adding new display objects, ensure cleanup in screen watcher callback
