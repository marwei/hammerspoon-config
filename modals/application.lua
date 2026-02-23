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

-- Helper function to launch/focus app with smart window handling
-- If switching to a different app: focus the last active window
-- If target app is already active: cycle to next window
--
-- opts (optional table):
--   bundleID       - launch by bundle ID instead of name (e.g. for default browser)
--   bringAllWindows - raise all windows after launch (for Telegram, Photos, etc.)
--   screen         - target screen: "native" or "external"
--   resize         - resize direction after positioning (e.g. "halfleft", "fullscreen")
local function launchAndFocusApp(appName, opts)
  opts = opts or {}
  local currentApp = hs.application.frontmostApplication()
  local targetApp

  if opts.bundleID then
    targetApp = hs.application.get(opts.bundleID)
  else
    targetApp = hs.application.get(appName)
  end

  -- Check if target app is already running and is the current app
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
    -- Different app: launch/focus
    if opts.bundleID then
      hs.application.launchOrFocusByBundleID(opts.bundleID)
    else
      hs.application.launchOrFocus(appName)
    end

    local delay = (opts.screen or opts.resize or opts.bringAllWindows) and 0.3 or 0.1
    hs.timer.doAfter(delay, function()
      local app
      if opts.bundleID then
        app = hs.application.get(opts.bundleID)
      else
        app = hs.application.get(appName)
      end
      if not app then return end

      app:unhide()
      app:activate()

      if opts.bringAllWindows then
        local windows = app:allWindows()
        for _, win in ipairs(windows) do
          win:raise()
        end
      end

      local win = app:mainWindow()
      if not win then
        -- Fallback: find first visible standard window
        local windows = app:allWindows()
        for _, w in ipairs(windows) do
          if w:isVisible() and w:isStandard() then
            win = w
            break
          end
        end
      end
      if not win then return end

      -- Move to target screen if specified
      if opts.screen then
        local targetScreen
        if opts.screen == "native" then
          targetScreen = getNativeScreen()
        elseif opts.screen == "external" then
          targetScreen = getUltraWideScreen()
        end
        if targetScreen then
          win:moveToScreen(targetScreen, false, true, 0)
        end
      end

      if opts.resize then
        hs.timer.doAfter(0.2, function()
          win:focus()
          if opts.resize == "fullscreen_native" then
            -- Special case: fullscreen on native screen
            local nativeScreen = getNativeScreen()
            local max = nativeScreen:fullFrame()
            local localf = {x=0, y=0, w=max.w, h=max.h}
            local absolutef = nativeScreen:localToAbsolute(localf)
            win:setFrame(absolutef, 0)
          else
            resize_win(opts.resize)
          end
        end)
      else
        win:focus()
      end
    end)
  end
end

-- Helper function to check if app exists
local function appExists(path)
  local file = io.open(path .. '/Contents/Info.plist', 'r')
  if file then
    file:close()
    return true
  end
  return false
end

appM:bind('', 'A', 'Activity Monitor', function()
  launchAndFocusApp('Activity Monitor')
  appM:exit()
end)

appM:bind('', 'space', 'Browser (Default)', function()
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')
  if defaultBrowser then
    launchAndFocusApp(nil, {bundleID = defaultBrowser})
  else
    hs.alert.show('No default browser found')
  end
  appM:exit()
end)

appM:bind('', 'W', 'Microsoft Word', function()
  launchAndFocusApp('Microsoft Word')
  appM:exit()
end)

appM:bind('', 'return', 'Notes (Obsidian)', function()
  launchAndFocusApp('Obsidian')
  appM:exit()
end)

appM:bind('', 'I', 'Terminal (iTerm)', function()
  launchAndFocusApp('iTerm', {
    bringAllWindows = true,
    screen = "native",
    resize = "fullscreen_native",
  })
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

appM:bind('', 'P', 'Photos', function()
  launchAndFocusApp('Photos', {bringAllWindows = true})
  appM:exit()
end)

appM:bind('', 'F', 'Autodesk Fusion', function()
  launchAndFocusApp('Autodesk Fusion', {bringAllWindows = true})
  appM:exit()
end)

appM:bind('', 'S', 'Slack', function()
  launchAndFocusApp('Slack')
  appM:exit()
end)

appM:bind('', 'tab', 'Telegram', function()
  launchAndFocusApp('Telegram', {
    bringAllWindows = true,
    screen = "native",
  })
  appM:exit()
end)

-- Conditionally bind Microsoft Loop if it exists
local loopPath = os.getenv("HOME") .. '/Applications/Edge Apps.localized/Microsoft Loop.app'
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
    launchAndFocusApp('Granola', {
      bringAllWindows = true,
      screen = "external",
      resize = "quarterright",
    })
    appM:exit()
  end)
end
