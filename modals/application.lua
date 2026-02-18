appM = hs.hotkey.modal.new()

function appM:entered()
  toggle_modal_light(lawngreen,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function appM:exited()
  toggle_modal_light(lawngreen,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

appM:bind('', 'escape', function() appM:exit() end)

-- Helper function to get the built-in/native Mac display
local function getNativeScreen()
  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    if screen:name():match("Built%-in") or screen:name():match("Color LCD") then
      return screen
    end
  end
  return hs.screen.primaryScreen()
end

-- Helper function to get the ultra-wide/external display
local function getUltraWideScreen()
  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    -- External screen is the one that's NOT built-in
    if not (screen:name():match("Built%-in") or screen:name():match("Color LCD")) then
      return screen
    end
  end
  return hs.screen.primaryScreen()
end

-- Helper function to launch/focus app with smart window handling
-- If switching to a different app: focus the last active window
-- If target app is already active: cycle to next window
local function launchAndFocusApp(appName)
  local currentApp = hs.application.frontmostApplication()
  local targetApp = hs.application.get(appName)

  -- Check if target app is already running and is the current app
  local isSameApp = targetApp and currentApp and
                    (targetApp:bundleID() == currentApp:bundleID() or
                     targetApp:name() == currentApp:name())

  if isSameApp then
    -- Same app: cycle to next window
    local windows = targetApp:allWindows()
    -- Filter to visible windows only
    local visibleWindows = {}
    for _, win in ipairs(windows) do
      if win:isVisible() and win:isStandard() then
        table.insert(visibleWindows, win)
      end
    end

    if #visibleWindows > 1 then
      local focusedWin = hs.window.focusedWindow()
      local currentIndex = 1
      for i, win in ipairs(visibleWindows) do
        if win:id() == focusedWin:id() then
          currentIndex = i
          break
        end
      end
      -- Focus next window (wrap around)
      local nextIndex = (currentIndex % #visibleWindows) + 1
      visibleWindows[nextIndex]:focus()
    end
  else
    -- Different app: launch/focus and select last active window
    hs.application.launchOrFocus(appName)

    hs.timer.doAfter(0.1, function()
      local app = hs.application.get(appName)
      if app then
        app:unhide()
        app:activate()
        -- Focus the most recently used window
        local windows = app:allWindows()
        if windows and #windows > 0 then
          for _, win in ipairs(windows) do
            if win:isVisible() and win:isStandard() then
              win:focus()
              break
            end
          end
        end
      end
    end)
  end
end

-- Legacy function for cases that need all windows raised
local function launchAndBringAllWindowsToFront(appName)
  hs.application.launchOrFocus(appName)
  hs.timer.doAfter(0.1, function()
    local app = hs.application.get(appName)
    if app then
      app:unhide()
      app:activate()
      local windows = app:allWindows()
      for _, win in ipairs(windows) do
        win:raise()
      end
    end
  end)
end

appM:bind('', 'A', 'Activity Monitor', function()
  launchAndFocusApp('Activity Monitor')
  appM:exit()
end)

appM:bind('', 'space', 'Browser (Default)', function()
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')
  if defaultBrowser then
    local currentApp = hs.application.frontmostApplication()
    local targetApp = hs.application.get(defaultBrowser)

    local isSameApp = targetApp and currentApp and
                      targetApp:bundleID() == currentApp:bundleID()

    if isSameApp then
      -- Same app: cycle to next window
      local windows = targetApp:allWindows()
      local visibleWindows = {}
      for _, win in ipairs(windows) do
        if win:isVisible() and win:isStandard() then
          table.insert(visibleWindows, win)
        end
      end

      if #visibleWindows > 1 then
        local focusedWin = hs.window.focusedWindow()
        local currentIndex = 1
        for i, win in ipairs(visibleWindows) do
          if win:id() == focusedWin:id() then
            currentIndex = i
            break
          end
        end
        local nextIndex = (currentIndex % #visibleWindows) + 1
        visibleWindows[nextIndex]:focus()
      end
    else
      -- Different app: launch/focus last active window
      hs.application.launchOrFocusByBundleID(defaultBrowser)
      hs.timer.doAfter(0.1, function()
        local app = hs.application.get(defaultBrowser)
        if app then
          app:unhide()
          app:activate()
          local windows = app:allWindows()
          if windows and #windows > 0 then
            for _, win in ipairs(windows) do
              if win:isVisible() and win:isStandard() then
                win:focus()
                break
              end
            end
          end
        end
      end)
    end
  else
    hs.alert.show('No default browser found')
  end
  appM:exit()
end)

appM:bind('', 'W', 'Microsoft Word', function()
  launchAndFocusApp('Microsoft Word')
  appM:exit()
end)

appM:bind('', 'tab', 'Notes (Obsidian)', function()
  local currentApp = hs.application.frontmostApplication()
  local targetApp = hs.application.get('Obsidian')

  local isSameApp = targetApp and currentApp and
                    (targetApp:bundleID() == currentApp:bundleID() or
                     targetApp:name() == currentApp:name())

  if isSameApp then
    -- Same app: cycle to next window
    local windows = targetApp:allWindows()
    local visibleWindows = {}
    for _, win in ipairs(windows) do
      if win:isVisible() and win:isStandard() then
        table.insert(visibleWindows, win)
      end
    end

    if #visibleWindows > 1 then
      local focusedWin = hs.window.focusedWindow()
      local currentIndex = 1
      for i, win in ipairs(visibleWindows) do
        if win:id() == focusedWin:id() then
          currentIndex = i
          break
        end
      end
      local nextIndex = (currentIndex % #visibleWindows) + 1
      visibleWindows[nextIndex]:focus()
    end
  else
    -- Different app: launch/focus and position
    launchAndBringAllWindowsToFront('Obsidian')

    hs.timer.doAfter(0.3, function()
      local app = hs.application.get('Obsidian')
      if app then
        local win = app:mainWindow()
        if win then
          local ultraWideScreen = getUltraWideScreen()
          win:moveToScreen(ultraWideScreen, false, true, 0)

          hs.timer.doAfter(0.2, function()
            win:focus()
            resize_win('halfleft')
          end)
        end
      end
    end)
  end

  appM:exit()
end)

appM:bind('', 'I', 'Terminal (iTerm)', function()
  local currentApp = hs.application.frontmostApplication()
  local targetApp = hs.application.get('iTerm2') or hs.application.get('iTerm')

  local isSameApp = targetApp and currentApp and
                    (targetApp:bundleID() == currentApp:bundleID() or
                     targetApp:name() == currentApp:name())

  if isSameApp then
    -- Same app: cycle to next window
    local windows = targetApp:allWindows()
    local visibleWindows = {}
    for _, win in ipairs(windows) do
      if win:isVisible() and win:isStandard() then
        table.insert(visibleWindows, win)
      end
    end

    if #visibleWindows > 1 then
      local focusedWin = hs.window.focusedWindow()
      local currentIndex = 1
      for i, win in ipairs(visibleWindows) do
        if win:id() == focusedWin:id() then
          currentIndex = i
          break
        end
      end
      local nextIndex = (currentIndex % #visibleWindows) + 1
      visibleWindows[nextIndex]:focus()
    end
  else
    -- Different app: launch/focus and position
    launchAndBringAllWindowsToFront('iTerm')

    hs.timer.doAfter(0.3, function()
      local app = hs.application.get('iTerm2')
      if app then
        local win = app:mainWindow()
        if win then
          local nativeScreen = getNativeScreen()
          win:moveToScreen(nativeScreen, false, true, 0)

          hs.timer.doAfter(0.2, function()
            local max = nativeScreen:fullFrame()
            local localf = {}
            localf.x = 0
            localf.y = 0
            localf.w = max.w
            localf.h = max.h
            local absolutef = nativeScreen:localToAbsolute(localf)
            win:setFrame(absolutef, 0)
          end)
        end
      end
    end)
  end

  appM:exit()
end)

appM:bind('', 'T', 'Microsoft Teams', function()
  launchAndFocusApp('Microsoft Teams')
  appM:exit()
end)

appM:bind('', 'E', 'Email (Outlook/Gmail)', function()
  local outlookPath = '/Applications/Microsoft Outlook.app'
  local file = io.open(outlookPath .. '/Contents/Info.plist', 'r')

  if file then
    file:close()
    launchAndFocusApp('Microsoft Outlook')
  else
    hs.urlevent.openURL('https://mail.google.com')
  end

  appM:exit()
end)

appM:bind('', 'V', 'VSCode', function()
  launchAndFocusApp('Visual Studio Code')
  appM:exit()
end)

-- Helper function to check if app exists
local function appExists(path)
  local file = io.open(path .. '/Contents/Info.plist', 'r')
  if file then
    file:close()
    return true
  end
  return false
end

appM:bind('', 'return', 'Telegram', function()
  local currentApp = hs.application.frontmostApplication()
  local targetApp = hs.application.get('Telegram')

  local isSameApp = targetApp and currentApp and
                    (targetApp:bundleID() == currentApp:bundleID() or
                     targetApp:name() == currentApp:name())

  if isSameApp then
    local windows = targetApp:allWindows()
    local visibleWindows = {}
    for _, win in ipairs(windows) do
      if win:isVisible() and win:isStandard() then
        table.insert(visibleWindows, win)
      end
    end

    if #visibleWindows > 1 then
      local focusedWin = hs.window.focusedWindow()
      local currentIndex = 1
      for i, win in ipairs(visibleWindows) do
        if win:id() == focusedWin:id() then
          currentIndex = i
          break
        end
      end
      local nextIndex = (currentIndex % #visibleWindows) + 1
      visibleWindows[nextIndex]:focus()
    end
  else
    launchAndBringAllWindowsToFront('Telegram')

    hs.timer.doAfter(0.3, function()
      local app = hs.application.get('Telegram')
      if app then
        local win = app:mainWindow()
        if win then
          local nativeScreen = getNativeScreen()
          win:moveToScreen(nativeScreen, false, true, 0)
          hs.timer.doAfter(0.2, function()
            win:focus()
          end)
        end
      end
    end)
  end

  appM:exit()
end)

-- Conditionally bind Microsoft Loop if it exists
local loopPath = '/Users/wei/Applications/Edge Apps.localized/Microsoft Loop.app'
if appExists(loopPath) then
  appM:bind('', 'L', 'Microsoft Loop', function()
    launchAndFocusApp('Microsoft Loop')
    appM:exit()
  end)
end

-- Conditionally bind Granola if it exists
local granolaPath = '/Applications/Granola.app'
if appExists(granolaPath) then
  appM:bind('', 'G', 'Granola', function()
    local currentApp = hs.application.frontmostApplication()
    local targetApp = hs.application.get('Granola')

    local isSameApp = targetApp and currentApp and
                      (targetApp:bundleID() == currentApp:bundleID() or
                       targetApp:name() == currentApp:name())

    if isSameApp then
      -- Same app: cycle to next window
      local windows = targetApp:allWindows()
      local visibleWindows = {}
      for _, win in ipairs(windows) do
        if win:isVisible() and win:isStandard() then
          table.insert(visibleWindows, win)
        end
      end

      if #visibleWindows > 1 then
        local focusedWin = hs.window.focusedWindow()
        local currentIndex = 1
        for i, win in ipairs(visibleWindows) do
          if win:id() == focusedWin:id() then
            currentIndex = i
            break
          end
        end
        local nextIndex = (currentIndex % #visibleWindows) + 1
        visibleWindows[nextIndex]:focus()
      end
    else
      -- Different app: launch/focus and position
      launchAndBringAllWindowsToFront('Granola')

      hs.timer.doAfter(0.3, function()
        local app = hs.application.get('Granola')
        if app then
          local win = app:mainWindow()
          if win then
            local ultraWideScreen = getUltraWideScreen()
            win:moveToScreen(ultraWideScreen, false, true, 0)

            hs.timer.doAfter(0.2, function()
              win:focus()
              resize_win('quarterright')
            end)
          end
        end
      end)
    end

    appM:exit()
  end)
end
