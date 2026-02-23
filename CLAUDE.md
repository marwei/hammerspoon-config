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
- Defines `module_list` array specifying which modal modules to load
- Controls `show_modal` flag for visual feedback
- Defines `background_jobs` table for background automation framework configuration
- Application shortcuts are documented as comments; actual bindings live in `modals/application.lua`

### Modal Systems

The configuration uses Hammerspoon modals for different contexts:

**Application Modal (`modals/application.lua`)**
- Activated by Hyper+Space
- Uses `launchAndFocusApp(appName, opts)` helper for all bindings
- `opts` table supports: `bundleID`, `bringAllWindows`, `screen` ("native"/"external"), `resize` (direction string)
- Smart window cycling: if target app is already focused, cycles to next window
- Shows green modal light when active
- Auto-exits after launching an app

**Window Resize Modal (`modals/window.lua`)**
- Activated by Hyper+M
- Provides comprehensive window management functions
- Shows red modal light (firebrick) when active
- Key features:
  - Basic positioning: H (left half), L (right half), J (down half), K (up half)
  - Quarter-width: Shift+H (left quarter), Shift+L (right quarter)
  - Fullscreen (F), center (C) — both delegate to `resize_win()`
  - Multi-monitor: arrow keys to move between displays
- All resize/position logic lives in `resize_win(direction)` and `move_win(direction)` functions

**Modal Display System (`lib/modal_display.lua`)**
- `toggle_modal_light(color, alpha)`: Shows/hides a circular indicator in top-right corner
- `toggle_modal_key_display()`: Shows/hides hotkey cheatsheet overlay
- `show_global_shortcuts()`: Shows/hides global shortcuts overlay
- Internal helpers: `createCheatsheetCanvas(title, heightRatio, contentBuilder)` and `renderShortcutGrid()` handle shared canvas boilerplate
- All functions are toggles — calling again removes the display

### Fn Key Navigation (`fn.lua`)

Custom Fn+key bindings using eventtap:
- Fn+H/J/K/L: Arrow keys (left/down/up/right)
- Fn+Y/O: Horizontal scroll
- Fn+U/I: Vertical scroll
- Fn+,: Left click at cursor
- Fn+.: Right click at cursor

### Background Jobs Framework (`widgets/background_jobs.lua`)

A generalized framework for automated background workflows. Jobs are modular, independently configurable, and share efficient event infrastructure.

**Architecture:**
- **Framework** (`widgets/background_jobs.lua`): Central orchestrator that manages job lifecycle, event distribution, and shared utilities
- **Jobs** (`jobs/` directory): Self-contained modules implementing automation logic
- **Configuration** (`config.lua`): `background_jobs` table with framework settings and per-job configuration

**Framework Features:**
- Single shared event sources (window filter, polling timer, app watcher) for all jobs
- Automatic job loading and lifecycle management (init → start → stop)
- Shared utility functions available to all jobs
- Centralized logging and error handling
- Per-job enable/disable controls

**Shared Utilities (available to all jobs via `_G.background_jobs_utils`):**
- `getBrowserURL(appName)`: Extract current URL from browser using AppleScript (supports Safari, Chrome, Edge, Arc, Brave)
- `matchPattern(text, patterns)`: Match text against array of Lua patterns
- `debugLog(jobName, message)`: Centralized logging (respects debug_mode)
- `showNotification(title, message, duration)`: Consistent notifications

**Event Types:**
- `onWindowFocused(window, appName)`: Triggered when window focus changes
- `onTimerTick(interval)`: Triggered at job's configured polling interval
- `onAppLaunched(appName)`: Triggered when application launches
- `onAppTerminated(appName)`: Triggered when application terminates

**Current Jobs:**

**VPN Auto-Connect** (`jobs/vpn_autoconnect.lua`)
- Monitors browser URLs and triggers Azure VPN when matched patterns detected
- Uses hybrid approach: event-driven (window focus) + polling (in-tab navigation)
- Supports multiple browsers via AppleScript URL extraction
- Configurable URL patterns (Lua patterns for flexible matching)
- VPN status detection via network interfaces and process checks
- Debouncing to prevent rapid connection attempts

**Configuration Example:**
```lua
background_jobs = {
  enabled = true,       -- Master enable/disable
  debug_mode = false,   -- Verbose logging

  jobs = {
    vpn_autoconnect = {
      enabled = true,
      polling_interval = 5,  -- Seconds between checks
      config = {
        url_patterns = {
          "aka%.ms/.*",              -- Microsoft short links
          ".*%.microsoft%.com",      -- Microsoft domains
          ".*%.sharepoint%.com",     -- SharePoint
        },
        auto_disconnect = false,
        vpn_shortcut_name = "Connect Azure VPN",
      }
    }
  }
}
```

**VPN Auto-Connect Setup:**
1. Create macOS Shortcut named "Connect Azure VPN" (or custom name in config)
2. Shortcut should use AppleScript to trigger Azure VPN Client connection
3. Add URL patterns to `config.url_patterns` array
4. Reload Hammerspoon (Hyper+R)
5. Check console (Hyper+Z) for "Background Jobs Framework initialized"

**Creating New Jobs:**

1. **Create job file** in `jobs/` directory (e.g., `jobs/my_job.lua`)
2. **Implement standard interface:**

```lua
local utils = _G.background_jobs_utils

local job = {}

job.name = "My Job Name"
job.version = "1.0"

-- Required: Initialize job with configuration
job.init = function(config)
  -- Setup state, load config
  return true  -- Return false to abort
end

-- Optional: Start job (called after init)
job.start = function()
  return true
end

-- Optional: Stop job (cleanup)
job.stop = function()
  return true
end

-- Optional: Event handlers (implement only what you need)
job.onWindowFocused = function(window, appName)
  -- Respond to window focus changes
end

job.onTimerTick = function(interval)
  -- Periodic checks (interval from config)
end

job.onAppLaunched = function(appName)
  -- Respond to app launches
end

job.onAppTerminated = function(appName)
  -- Respond to app termination
end

return job
```

3. **Add configuration** to `config.lua`:

```lua
background_jobs = {
  enabled = true,
  jobs = {
    my_job = {
      enabled = true,
      polling_interval = 10,
      config = {
        -- Job-specific config
      }
    }
  }
}
```

4. **Reload Hammerspoon** (Hyper+R)

**Job Examples:**

**Meeting Auto-Mute:**
```lua
-- jobs/meeting_automute.lua
-- Check calendar every 30s, auto-mute notifications during meetings
onTimerTick = function(interval)
  local inMeeting = checkCalendar()
  if inMeeting then
    hs.execute("defaults write com.apple.ncprefs.plist dnd_prefs -int 1")
  end
end
```

**Smart Display:**
```lua
-- jobs/smart_display.lua
-- Adjust brightness/color temp by time of day
onTimerTick = function(interval)
  local hour = os.date("%H")
  if hour >= 20 or hour < 6 then
    -- Night mode: reduce brightness, warm colors
  end
end
```

**Auto Audio Switcher:**
```lua
-- jobs/audio_switcher.lua
-- Switch audio output based on active app
onWindowFocused = function(window, appName)
  if appName == "Music" then
    switchAudioOutput("Speakers")
  elseif appName == "Microsoft Teams" then
    switchAudioOutput("Headphones")
  end
end
```

**Global Variables:**
- `background_jobs_state`: Framework state (jobs registry, instances, config)
- `_G.background_jobs_utils`: Shared utility functions

**Performance:**
- Single window filter shared across all jobs (not one per job)
- Single polling timer with minimum interval across all jobs
- Inactive/disabled jobs consume zero resources
- Event-driven architecture minimizes CPU usage

**Debugging:**
- Enable `debug_mode` in `config.lua` for verbose logging
- Check console (Hyper+Z) for framework initialization messages
- Look for job-specific error messages with `[Job Name]` prefix
- Test jobs individually by disabling others

**Limitations:**
- AppleScript browser URL extraction: Firefox has limited support, may fall back to window title
- Polling delay: 5-second default means in-tab navigation detected after delay
- VPN control: Azure VPN Client has no official API, relies on UI automation
- URL obfuscation: Shortened URLs (bit.ly) won't match patterns unless expanded

### Libraries

**Screens (`lib/screens.lua`)**: Shared screen detection utilities
- `getNativeScreen()`: Returns the built-in/native Mac display (matches "Built-in" or "Color LCD")
- `getUltraWideScreen()`: Returns the external display (first non-built-in screen)
- Both fall back to `hs.screen.primaryScreen()` if no match found
- Used by `modals/application.lua` and `modals/layout.lua`

**Style (`lib/style.lua`)**: Color constants using Hammerspoon drawing color APIs (includes `cyan`)

**Utility (`lib/utility.lua`)**: Helper functions like `is_in()` and `print_table()`

## Development Workflow

### Testing Changes

1. Save changes to any `.lua` file
2. Press Hyper+R (or Cmd+Alt+Shift+Ctrl+R) to reload configuration
3. Check console (Hyper+Z) for any errors

### Automated Tests

Run `lua tests/run_all.lua` from the project root. Requires `lua` (install via `brew install lua`).

Tests validate:
- **test_config.lua**: `module_list` files exist, no duplicates, `background_jobs` well-formed, `show_modal` is boolean
- **test_modules.lua**: All library globals exported correctly, `hotkey_filtered` is local (not leaked), color globals including `cyan`
- **test_application_modal.lua**: All expected key bindings exist, no duplicates, all bindings have labels
- **test_window_modal.lua**: All expected key bindings exist, F/C bindings call `resize_win()` (not inline), functions defined

The test suite uses `tests/hs_mock.lua` which stubs Hammerspoon APIs so modules can load outside of Hammerspoon. Mock modals track registered bindings for inspection.

### Adding New Applications

Add a new binding directly in `modals/application.lua`:
```lua
appM:bind('', 'X', 'App Name', function()
  launchAndFocusApp('App Name', {
    -- Optional: bringAllWindows = true,
    -- Optional: screen = "native" or "external",
    -- Optional: resize = "halfleft", "fullscreen", etc.
  })
  appM:exit()
end)
```

### Adding New Modals

1. Create new file in `modals/` directory
2. Add to `module_list` in `config.lua`
3. Bind activation hotkey in `init.lua`
4. Use `toggle_modal_light()` and `toggle_modal_key_display()` for visual feedback

### Adding New Background Jobs

For automated workflows that run in the background (no user interaction needed):

1. Create new file in `jobs/` directory (e.g., `jobs/my_job.lua`)
2. Implement standard job interface (see Background Jobs Framework section)
3. Add job configuration to `background_jobs.jobs` in `config.lua`
4. Reload Hammerspoon (Hyper+R)
5. Check console (Hyper+Z) for "Job registered: [Job Name]"

**When to use jobs vs modals:**
- **Jobs**: Background automation, event-driven responses, periodic checks (VPN auto-connect, meeting auto-mute)
- **Modals**: User-initiated actions, keyboard-driven workflows (window management, app launcher)

### Debugging

- Run `lua tests/run_all.lua` to validate config and module structure
- Use `print()` statements (output goes to Hammerspoon console)
- Access console with Hyper+Z
- Use `hs.alert.show("message")` for temporary on-screen alerts
- Check `hs.hotkey.getHotkeys()` to debug hotkey conflicts

## Important Conventions

### Global Variables

Global variables are used throughout for state management:
- Modal objects: `appM`, `resizeM`, `layoutM`, `cerebralM`
- Functions: `resize_win()`, `move_win()`, `getNativeScreen()`, `getUltraWideScreen()`, `toggle_modal_light()`, `toggle_modal_key_display()`, `show_global_shortcuts()`
- Display objects: `modal_light`, `cheatsheet_view`, `global_shortcuts_view`, `modal_tray`, etc.
- Color globals: `white`, `black`, `firebrick`, `lawngreen`, `cyan`, `dodgerblue`, etc. (defined in `lib/style.lua`)
- Timers/watchers: `globalGC`, `globalScreenWatcher`, `fn_tapper`
- Background jobs: `background_jobs_state` (framework state), `_G.background_jobs_utils` (shared utilities)

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

**Background Jobs Not Loading**
- Check console (Hyper+Z) for error messages during framework initialization
- Verify `widgets/background_jobs.lua` exists and is in `module_list`
- Ensure `background_jobs` table exists in `config.lua` with `enabled = true`
- Verify job file exists in `jobs/` directory and returns a valid table
- Check job implements required `init()` function

**VPN Auto-Connect Not Working**
- Verify macOS Shortcut exists with exact name from config (`vpn_shortcut_name`)
- Test shortcut manually first to ensure it connects VPN
- Enable `debug_mode = true` in `background_jobs` config to see URL extraction attempts
- Check browser is supported (Safari, Chrome, Edge, Arc, Brave - Firefox has limited support)
- Verify URL patterns use Lua pattern syntax (e.g., `%.` for literal dot, `.*` for wildcard)
- Ensure Azure VPN Client is installed and running

**Job Performance Issues**
- Increase `polling_interval` to reduce CPU usage (default: 5 seconds)
- Framework uses single shared timer/filter for all jobs (minimal overhead)
- Disable unused jobs in config with `enabled = false`
- Check console for repeated error messages that may indicate job failures
