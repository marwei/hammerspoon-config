layoutM = hs.hotkey.modal.new()

function layoutM:entered()
  toggle_modal_light(dodgerblue, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function layoutM:exited()
  toggle_modal_light(dodgerblue, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

layoutM:bind('', 'escape', function() layoutM:exit() end)

-- Helper function to get the built-in/native Mac display
local function getNativeScreen()
  -- Try to find the built-in screen
  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    if screen:name():match("Built%-in") or screen:name():match("Color LCD") then
      return screen
    end
  end
  -- Fall back to primary screen if built-in not found
  return hs.screen.primaryScreen()
end

-- Helper function to position a window
local function positionWindow(appName, xPercent, yPercent, wPercent, hPercent, targetScreen, callback)
  -- Launch or focus the app first
  hs.application.launchOrFocus(appName)

  -- Wait for app to be ready with retries
  local retries = 0
  local maxRetries = 20

  local function tryPosition()
    retries = retries + 1
    local app = hs.application.get(appName)

    if app then
      local win = app:mainWindow()
      if win then
        local screen = targetScreen or win:screen() or hs.screen.mainScreen()
        local max = screen:fullFrame()

        -- Create frame with screen-relative coordinates
        local localf = {}
        localf.x = max.w * xPercent
        localf.y = 0
        localf.w = max.w * wPercent
        localf.h = max.h * hPercent

        -- Convert to absolute coordinates and apply
        local absolutef = screen:localToAbsolute(localf)
        win:setFrame(absolutef, 0)

        if callback then callback(win) end
        return
      end
    end

    -- Retry if app/window not ready yet
    if retries < maxRetries then
      hs.timer.doAfter(0.2, tryPosition)
    else
      hs.alert.show("Timeout waiting for " .. appName)
      if callback then callback(nil) end
    end
  end

  hs.timer.doAfter(0.2, tryPosition)
end

layoutM:bind('', 'C', 'Cerebral Layout', function()
  -- Obsidian on left half (0% to 50%), VSCode on right half (50% to 100%)
  -- Note: VS Code's process name is "Code" not "Visual Studio Code"
  -- Position on native Mac display

  -- Get the native/built-in screen
  local nativeScreen = getNativeScreen()

  -- Open VS Code with specific folder (will reuse existing window if already open)
  local vscodeFolder = os.getenv("HOME") .. "/Desktop/Obsidian/work"
  hs.task.new("/usr/bin/open", function() end, {"-a", "Visual Studio Code", vscodeFolder}):start()

  positionWindow('Obsidian', 0, 0, 0.5, 1, nativeScreen, function()
    positionWindow('Code', 0.5, 0, 0.5, 1, nativeScreen, function(vscodeWin)
      -- Focus VS Code window after both are positioned
      if vscodeWin then
        vscodeWin:focus()

        -- Wait a bit for VS Code to be fully ready, then open Copilot chat in full-screen
        hs.timer.doAfter(0.5, function()
          -- Open Copilot Chat in full-screen with Ctrl+Cmd+C
          hs.eventtap.keyStroke({"ctrl", "cmd"}, "c")
        end)
      end
    end)
  end)
  layoutM:exit()
end)

layoutM:bind('', 'B', 'Browser Layout', function()
  -- Distribute all browser windows evenly across the screen
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')

  if defaultBrowser then
    local browserApp = hs.application.applicationsForBundleID(defaultBrowser)[1]

    if browserApp then
      -- Get all standard windows
      local allWindows = browserApp:allWindows()
      local windows = {}
      for _, win in ipairs(allWindows) do
        if win:isStandard() then
          table.insert(windows, win)
        end
      end

      local numWindows = #windows

      if numWindows > 0 then
        -- Calculate width for each window
        local widthPercent = 1.0 / numWindows

        -- Position each window
        for i, win in ipairs(windows) do
          local screen = win:screen() or hs.screen.mainScreen()
          local max = screen:fullFrame()

          -- Create frame for this window's position
          local localf = {}
          localf.x = max.w * widthPercent * (i - 1)
          localf.y = 0
          localf.w = max.w * widthPercent
          localf.h = max.h

          -- Convert to absolute coordinates and apply
          local absolutef = screen:localToAbsolute(localf)
          win:setFrame(absolutef, 0)
        end

        -- Raise all windows to the front to keep them on top
        for _, win in ipairs(windows) do
          win:raise()
        end

        -- Focus the first window
        windows[1]:focus()

        hs.alert.show(numWindows .. " browser window(s) distributed evenly")
      else
        hs.alert.show("No browser windows found")
      end
    else
      hs.alert.show("Browser not running")
    end
  else
    hs.alert.show("No default browser found")
  end

  layoutM:exit()
end)

layoutM:bind('', 'T', 'Teams Layout', function()
  -- Teams in center 50% (25% to 75%), Granola in right 25% (75% to 100%)
  -- Position on primary/ultra-wide screen

  -- Get the primary screen (ultra-wide)
  local primaryScreen = hs.screen.primaryScreen()

  -- Position Teams in center 50%
  positionWindow('Microsoft Teams', 0.25, 0, 0.5, 1, primaryScreen, function(teamsWin)
    -- Position Granola in right 25%
    positionWindow('Granola', 0.75, 0, 0.25, 1, primaryScreen, function()
      -- Focus Teams window after both are positioned
      if teamsWin then
        teamsWin:focus()
      end
    end)
  end)

  layoutM:exit()
end)
