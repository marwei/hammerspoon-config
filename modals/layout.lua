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
  -- Browser on left half of ultrawide (0% to 50%), Obsidian on right half of ultrawide (50% to 100%)
  -- iTerm full screen on built-in display

  -- Get the primary screen (ultrawide)
  local ultrawideScreen = hs.screen.primaryScreen()

  -- Get the built-in screen
  local builtinScreen = getNativeScreen()

  -- Get default browser
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')
  local browserName = nil

  if defaultBrowser then
    local browserApp = hs.application.applicationsForBundleID(defaultBrowser)[1]
    if browserApp then
      browserName = browserApp:name()
    end
  end

  if not browserName then
    hs.alert.show("No default browser found")
    layoutM:exit()
    return
  end

  -- Position browser on left half of ultrawide
  positionWindow(browserName, 0, 0, 0.5, 1, ultrawideScreen, function()
    -- Position Obsidian on right half of ultrawide
    positionWindow('Obsidian', 0.5, 0, 0.5, 1, ultrawideScreen, function()
      -- Position iTerm full screen on built-in display
      positionWindow('iTerm2', 0, 0, 1, 1, builtinScreen, function(itermWin)
        -- Focus iTerm window after all are positioned
        if itermWin then
          itermWin:focus()
        end
      end)
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
