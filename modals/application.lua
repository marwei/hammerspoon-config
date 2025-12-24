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

-- Helper function to launch/focus app and bring all windows to front
local function launchAndBringAllWindowsToFront(appName)
  -- First launch or focus the application
  hs.application.launchOrFocus(appName)

  -- Then ensure all windows come to front
  hs.timer.doAfter(0.1, function()
    local app = hs.application.get(appName)
    if app then
      app:unhide()
      app:activate()
      -- Raise all windows to bring them to front
      local windows = app:allWindows()
      for _, win in ipairs(windows) do
        win:raise()
      end
    end
  end)
end

appM:bind('', 'A', 'Activity Monitor', function()
  launchAndBringAllWindowsToFront('Activity Monitor')
  appM:exit()
end)

appM:bind('', 'B', 'Browser (Default)', function()
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')
  if defaultBrowser then
    hs.application.launchOrFocusByBundleID(defaultBrowser)
    hs.timer.doAfter(0.1, function()
      local app = hs.application.get(defaultBrowser)
      if app then
        app:unhide()
        app:activate()
        -- Raise all windows to bring them to front
        local windows = app:allWindows()
        for _, win in ipairs(windows) do
          win:raise()
        end
      end
    end)
  else
    hs.alert.show('No default browser found')
  end
  appM:exit()
end)

appM:bind('', 'W', 'Microsoft Word', function()
  launchAndBringAllWindowsToFront('Microsoft Word')
  appM:exit()
end)

appM:bind('', 'space', 'Notes (Obsidian)', function()
  launchAndBringAllWindowsToFront('Obsidian')
  appM:exit()
end)

appM:bind('', 'I', 'Terminal (iTerm)', function()
  launchAndBringAllWindowsToFront('iTerm')

  -- Move iTerm to native screen and make it fullscreen
  hs.timer.doAfter(0.3, function()
    local app = hs.application.get('iTerm2')
    if app then
      local win = app:mainWindow()
      if win then
        local nativeScreen = getNativeScreen()
        win:moveToScreen(nativeScreen, false, true, 0)

        -- Make fullscreen
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

  appM:exit()
end)

appM:bind('', 'T', 'Microsoft Teams', function()
  launchAndBringAllWindowsToFront('Microsoft Teams')
  appM:exit()
end)

appM:bind('', 'E', 'Email (Outlook/Gmail)', function()
  local outlookPath = '/Applications/Microsoft Outlook.app'
  local file = io.open(outlookPath .. '/Contents/Info.plist', 'r')

  if file then
    file:close()
    launchAndBringAllWindowsToFront('Microsoft Outlook')
  else
    hs.urlevent.openURL('https://mail.google.com')
  end

  appM:exit()
end)

appM:bind('', 'V', 'VSCode', function()
  launchAndBringAllWindowsToFront('Visual Studio Code')
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

-- Conditionally bind Microsoft Loop if it exists
local loopPath = '/Users/wei/Applications/Edge Apps.localized/Microsoft Loop.app'
if appExists(loopPath) then
  appM:bind('', 'L', 'Microsoft Loop', function()
    launchAndBringAllWindowsToFront('Microsoft Loop')
    appM:exit()
  end)
end

-- Conditionally bind Granola if it exists
local granolaPath = '/Applications/Granola.app'
if appExists(granolaPath) then
  appM:bind('', 'G', 'Granola', function()
    launchAndBringAllWindowsToFront('Granola')
    appM:exit()
  end)
end
