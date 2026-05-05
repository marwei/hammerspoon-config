appM = hs.hotkey.modal.new()
appM.name = "Applications"

function appM:entered()
  if show_modal == true then toggle_modal_key_display(appM) end
end

function appM:exited()
  if show_modal == true then toggle_modal_key_display(appM) end
end

appM:bind('', 'escape', function() appM:exit() end)

-- Helper function to launch/focus app with smart window handling
-- If switching to a different app: focus the last active window
-- If target app is already active: cycle to next window
--
-- opts (optional table):
--   bringAllWindows - raise all windows after launch (for Telegram, Photos, etc.)
--   screen         - target screen: "native" or "external"
--   resize         - resize direction after positioning (e.g. "halfleft", "fullscreen")
local function launchAndFocusApp(appName, opts)
  opts = opts or {}
  local currentApp = hs.application.frontmostApplication()
  -- Prefer bundleID lookup: it's a direct match, whereas name lookup
  -- iterates all running apps and queries each via AX (slow on apps
  -- whose CFBundleName differs from their display name, e.g. VSCode).
  local targetApp = opts.bundleID
    and hs.application.applicationsForBundleID(opts.bundleID)[1]
    or hs.application.get(appName)

  -- Finder special case: ensure at least one window exists, open Desktop
  if appName == "Finder" then
    local ok, _ = hs.applescript([[
      tell application "Finder"
        if (count of Finder windows) is 0 then
          make new Finder window to (path to desktop folder)
        end if
        activate
      end tell
    ]])
    if not ok then print("[Application] Finder AppleScript failed") end
    return
  end

  -- Check if target app is already running and is the current app
  local isSameApp = false
  if targetApp and currentApp then
    local targetBundle = targetApp.bundleID and targetApp:bundleID()
    local currentBundle = currentApp.bundleID and currentApp:bundleID()
    isSameApp = (targetBundle and currentBundle and targetBundle == currentBundle) or
                (targetApp:name() == currentApp:name())
  end

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
    local wasRunning = targetApp ~= nil
    local needsPositioning = opts.screen or opts.resize or opts.bringAllWindows

    -- Fast path: app already running with no special positioning.
    -- Skip the timer + mainWindow()/allWindows() scan, which is slow on
    -- Electron apps like VSCode that have many helper windows.
    if wasRunning and not needsPositioning then
      targetApp:unhide()
      targetApp:activate()
      return
    end

    if opts.bundleID then
      hs.application.launchOrFocusByBundleID(opts.bundleID)
    else
      hs.application.launchOrFocus(appName)
    end

    local delay = needsPositioning and 0.3 or 0.1
    hs.timer.doAfter(delay, function()
      local app = opts.bundleID
        and hs.application.applicationsForBundleID(opts.bundleID)[1]
        or hs.application.get(appName)
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

-- Bind shortcuts from config
appM.items = {}
for _, s in ipairs(app_shortcuts) do
  local label = s.label or s.app
  local action = function()
    if s.url then
      hs.urlevent.openURL(s.url)
    else
      launchAndFocusApp(s.app, {
        bundleID = s.bundleID,
        bringAllWindows = s.bringAllWindows,
        screen = s.screen,
        resize = s.resize,
      })
    end
    appM:exit()
  end
  appM:bind('', s.key, label, action)
  -- Also bind with hyper held so key works if user hasn't released Capslock yet
  appM:bind(hyper, s.key, action)

  local icon
  if s.url then
    icon = "lucide:globe"
  else
    icon = "app-name:" .. s.app
  end
  table.insert(appM.items, {key = s.key, label = label, icon = icon})
end

require('lib/icons').prewarm(appM.items)
