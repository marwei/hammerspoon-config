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
--   bringAllWindows - raise all windows after launch (for Telegram, Photos, etc.)
--   screen         - target screen: "native" or "external"
--   resize         - resize direction after positioning (e.g. "halfleft", "fullscreen")
local function launchAndFocusApp(appName, opts)
  opts = opts or {}
  local currentApp = hs.application.frontmostApplication()
  local targetApp = hs.application.get(appName)

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
    hs.application.launchOrFocus(appName)

    local delay = (opts.screen or opts.resize or opts.bringAllWindows) and 0.3 or 0.1
    hs.timer.doAfter(delay, function()
      local app = hs.application.get(appName)
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
for _, s in ipairs(app_shortcuts) do
  local label = s.label or s.app
  appM:bind('', s.key, label, function()
    if s.url then
      hs.urlevent.openURL(s.url)
    else
      launchAndFocusApp(s.app, {
        bringAllWindows = s.bringAllWindows,
        screen = s.screen,
        resize = s.resize,
      })
    end
    appM:exit()
  end)
end
