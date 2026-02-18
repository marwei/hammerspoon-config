# Background Jobs Framework

Automated workflows that run in the background, responding to system events.

## Quick Start

### Using VPN Auto-Connect

1. **Create macOS Shortcut:**
   - Open Shortcuts app
   - Create shortcut named "Connect Azure VPN"
   - Add AppleScript to click Azure VPN Client's Connect button
   - Test manually to verify it works

2. **Configure URL patterns** in `config.lua`:
   ```lua
   background_jobs = {
     enabled = true,
     jobs = {
       vpn_autoconnect = {
         enabled = true,
         config = {
           url_patterns = {
             "aka%.ms/.*",
             ".*%.microsoft%.com",
             ".*internal%.company%.com",  -- Add your patterns
           }
         }
       }
     }
   }
   ```

3. **Reload Hammerspoon:** Press Hyper+R

4. **Test:** Navigate to matched URL in browser, VPN should connect automatically

### Configuration Options

**Enable/disable framework:**
```lua
background_jobs = {
  enabled = true,  -- Set to false to disable all jobs
}
```

**Enable debug logging:**
```lua
background_jobs = {
  debug_mode = true,  -- Verbose logging to console
}
```

**Per-job settings:**
```lua
vpn_autoconnect = {
  enabled = true,              -- Enable/disable this job
  polling_interval = 5,        -- Seconds between checks (3-10 recommended)
  config = {
    url_patterns = { ... },    -- Lua patterns to match URLs
    vpn_shortcut_name = "...", -- macOS Shortcut name
    auto_disconnect = false,   -- Auto-disconnect when leaving URLs (experimental)
  }
}
```

## Creating New Jobs

### Job Template

Create `jobs/my_job.lua`:

```lua
-- Import shared utilities
local utils = _G.background_jobs_utils

-- Job module
local job = {}

job.name = "My Job"
job.version = "1.0"

-- Required: Initialize job
job.init = function(config)
  -- Load config, setup state
  print("[My Job] Initialized with config:")
  -- config contains values from background_jobs.jobs.my_job.config
  return true
end

-- Optional: Start job
job.start = function()
  print("[My Job] Started")
  return true
end

-- Optional: Cleanup
job.stop = function()
  print("[My Job] Stopped")
  return true
end

-- Optional: Event handlers

-- Called when window focus changes
job.onWindowFocused = function(window, appName)
  utils.debugLog("My Job", "Window focused: " .. appName)
end

-- Called periodically (interval from config)
job.onTimerTick = function(interval)
  utils.debugLog("My Job", "Timer tick (interval: " .. interval .. "s)")
end

-- Called when app launches
job.onAppLaunched = function(appName)
  utils.debugLog("My Job", "App launched: " .. appName)
end

-- Called when app terminates
job.onAppTerminated = function(appName)
  utils.debugLog("My Job", "App terminated: " .. appName)
end

return job
```

### Add to config.lua

```lua
background_jobs = {
  enabled = true,
  jobs = {
    my_job = {
      enabled = true,
      polling_interval = 10,  -- Optional: defaults to 5
      config = {
        -- Your custom config here
        setting1 = "value1",
        setting2 = 123,
      }
    }
  }
}
```

### Reload and Test

1. Press Hyper+R to reload
2. Check console (Hyper+Z) for initialization messages
3. Look for: `[Framework] Job registered: My Job`

## Available Utilities

Jobs have access to shared utilities via `_G.background_jobs_utils`:

### getBrowserURL(appName)
Extract current URL from browser using AppleScript.

```lua
local url = utils.getBrowserURL("Google Chrome")
if url then
  print("Current URL: " .. url)
end
```

**Supported browsers:**
- Safari
- Google Chrome
- Microsoft Edge
- Arc
- Brave Browser
- Firefox (limited support, may return nil)

### matchPattern(text, patterns)
Match text against array of Lua patterns.

```lua
local patterns = {".*%.microsoft%.com", "github%.com/.*"}
local matches, pattern = utils.matchPattern(url, patterns)
if matches then
  print("Matched pattern: " .. pattern)
end
```

**Lua pattern syntax:**
- `%.` = literal dot
- `.*` = zero or more of any character
- `.*%.com` = anything ending with .com
- `https://.*` = URLs starting with https://
- See: https://www.lua.org/pil/20.2.html

### debugLog(jobName, message)
Log messages (respects debug_mode).

```lua
utils.debugLog("My Job", "Processing URL: " .. url)
-- Only prints if debug_mode = true
```

### showNotification(title, message, duration)
Show macOS notification.

```lua
utils.showNotification(
  "My Job",
  "Action completed successfully",
  3  -- duration in seconds (optional, defaults to 3)
)
```

## Job Examples

### Example 1: Meeting Auto-Mute

Automatically mute notifications during calendar meetings.

```lua
-- jobs/meeting_automute.lua
local utils = _G.background_jobs_utils
local job = {}

job.name = "Meeting Auto-Mute"
job.version = "1.0"

local state = {
  in_meeting = false,
  calendar_check_interval = 30,  -- Check every 30 seconds
}

local function checkCalendar()
  -- Use AppleScript to check Calendar.app
  local script = [[
    tell application "Calendar"
      set now to current date
      set activeEvents to 0
      repeat with cal in calendars
        repeat with evt in (events of cal whose start date ≤ now and end date ≥ now)
          set activeEvents to activeEvents + 1
        end repeat
      end repeat
      return activeEvents
    end tell
  ]]

  local ok, result = hs.osascript.applescript(script)
  return ok and tonumber(result) > 0
end

job.init = function(config)
  return true
end

job.onTimerTick = function(interval)
  local inMeeting = checkCalendar()

  if inMeeting and not state.in_meeting then
    -- Entering meeting
    hs.execute("shortcuts run 'Mute Notifications'")
    utils.showNotification("Meeting Auto-Mute", "In meeting - notifications muted")
    state.in_meeting = true
  elseif not inMeeting and state.in_meeting then
    -- Leaving meeting
    hs.execute("shortcuts run 'Unmute Notifications'")
    utils.showNotification("Meeting Auto-Mute", "Meeting ended - notifications restored")
    state.in_meeting = false
  end
end

return job
```

**Config:**
```lua
meeting_automute = {
  enabled = true,
  polling_interval = 30,  -- Check calendar every 30 seconds
  config = {}
}
```

### Example 2: Auto Audio Switcher

Switch audio output based on active application.

```lua
-- jobs/audio_switcher.lua
local utils = _G.background_jobs_utils
local job = {}

job.name = "Auto Audio Switcher"
job.version = "1.0"

local audio_map = {}

local function switchAudioOutput(deviceName)
  local devices = hs.audiodevice.allOutputDevices()
  for _, device in ipairs(devices) do
    if device:name() == deviceName then
      device:setDefaultOutputDevice()
      utils.debugLog("Auto Audio Switcher", "Switched to: " .. deviceName)
      return true
    end
  end
  return false
end

job.init = function(config)
  audio_map = config.audio_map or {}
  return true
end

job.onWindowFocused = function(window, appName)
  local targetDevice = audio_map[appName]
  if targetDevice then
    switchAudioOutput(targetDevice)
  end
end

return job
```

**Config:**
```lua
audio_switcher = {
  enabled = true,
  polling_interval = 5,
  config = {
    audio_map = {
      ["Music"] = "MacBook Pro Speakers",
      ["Microsoft Teams"] = "AirPods Pro",
      ["Spotify"] = "HomePod",
      ["Zoom"] = "AirPods Pro",
    }
  }
}
```

### Example 3: Smart Display

Adjust display settings based on time of day.

```lua
-- jobs/smart_display.lua
local utils = _G.background_jobs_utils
local job = {}

job.name = "Smart Display"
job.version = "1.0"

local state = {
  current_mode = "day"
}

local function setNightMode()
  if state.current_mode == "night" then return end

  -- Reduce brightness
  hs.execute("brightness 0.3")

  -- Enable Night Shift
  hs.execute("shortcuts run 'Enable Night Shift'")

  utils.showNotification("Smart Display", "Night mode enabled")
  state.current_mode = "night"
end

local function setDayMode()
  if state.current_mode == "day" then return end

  -- Full brightness
  hs.execute("brightness 0.8")

  -- Disable Night Shift
  hs.execute("shortcuts run 'Disable Night Shift'")

  utils.showNotification("Smart Display", "Day mode enabled")
  state.current_mode = "day"
end

job.init = function(config)
  return true
end

job.onTimerTick = function(interval)
  local hour = tonumber(os.date("%H"))

  -- Night mode: 8 PM to 6 AM
  if hour >= 20 or hour < 6 then
    setNightMode()
  else
    setDayMode()
  end
end

return job
```

**Config:**
```lua
smart_display = {
  enabled = true,
  polling_interval = 60,  -- Check every minute
  config = {}
}
```

## Troubleshooting

### Job not loading

**Check console (Hyper+Z) for errors:**
- "Failed to load job": File doesn't exist or has syntax errors
- "Job missing init()": Job doesn't implement required init function
- "Job init() failed": Error during initialization

**Solutions:**
- Verify file exists in `jobs/` directory
- Check Lua syntax (no syntax errors)
- Ensure job returns a table with `init` function

### Events not firing

**Enable debug mode:**
```lua
background_jobs = { debug_mode = true }
```

**Check console for event logs:**
- "Window focused: ..." - Window focus events
- "Timer tick" - Polling events
- "App event: ..." - App launch/terminate events

**Common issues:**
- Job doesn't implement event handler function
- Event handler has errors (check console)
- Framework not enabled (`enabled = false`)

### URL extraction failing (VPN job)

**Check browser support:**
- Chrome, Safari, Edge, Arc, Brave: Full support
- Firefox: Limited support (may fail)

**Enable debug mode to see extraction attempts:**
```lua
debug_mode = true
```

**Console will show:**
- "Failed to get URL from [Browser]" - AppleScript failed
- "No AppleScript template for browser" - Browser not supported

### VPN not connecting

**Test macOS Shortcut manually first:**
- Open Shortcuts app
- Run "Connect Azure VPN" shortcut
- Verify it connects VPN

**Check shortcut name matches config:**
```lua
vpn_shortcut_name = "Connect Azure VPN"  -- Must match exactly
```

**Check URL patterns use Lua syntax:**
```lua
"aka%.ms/.*"           -- ✓ Correct: escaped dot
"aka.ms/.*"            -- ✗ Wrong: dot matches any character
```

## Performance Tips

### Optimize polling intervals

Longer intervals = lower CPU usage:
```lua
polling_interval = 10  -- Check every 10 seconds (vs default 5)
```

Use events instead of polling when possible:
- `onWindowFocused` for immediate response to focus changes
- `onAppLaunched` for app-specific triggers

### Disable unused jobs

```lua
jobs = {
  unused_job = {
    enabled = false,  -- Consumes zero resources
    ...
  }
}
```

### Monitor resource usage

**Check Hammerspoon CPU usage:**
- Open Activity Monitor
- Look for "Hammerspoon" process
- Should be < 1% when idle

**If high CPU usage:**
- Enable debug mode to see which job is active
- Increase polling intervals
- Check for infinite loops in job code

## Best Practices

### State Management

Store job state in local variables:
```lua
local state = {
  last_value = nil,
  counter = 0,
}

job.onTimerTick = function(interval)
  state.counter = state.counter + 1
end
```

### Error Handling

Wrap risky operations in pcall:
```lua
job.onWindowFocused = function(window, appName)
  local success, result = pcall(function()
    -- Risky operation
    local url = utils.getBrowserURL(appName)
    return url
  end)

  if not success then
    print("[My Job] Error: " .. tostring(result))
  end
end
```

### Logging

Use debugLog for development, print for errors:
```lua
-- Development logging (respects debug_mode)
utils.debugLog("My Job", "Processing item: " .. item)

-- Always log errors
if error then
  print("[My Job] ERROR: " .. error_message)
end
```

### Testing

Test jobs incrementally:
1. Start with just `init()` and verify it loads
2. Add one event handler at a time
3. Enable debug mode and check console output
4. Test edge cases (nil values, missing data)

## Additional Resources

- **Hammerspoon API:** https://www.hammerspoon.org/docs/
- **Lua patterns:** https://www.lua.org/pil/20.2.html
- **AppleScript:** https://developer.apple.com/library/archive/documentation/AppleScript/
- **Framework source:** `widgets/background_jobs.lua`
- **VPN job example:** `jobs/vpn_autoconnect.lua`
