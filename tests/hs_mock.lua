-- Hammerspoon API mock for testing outside of Hammerspoon
-- Provides chainable no-op stubs for all commonly used HS APIs

local mock = {}

-- Utility: create a callable table that returns itself (chainable no-op)
local function chainable()
  local obj = {}
  setmetatable(obj, {
    __index = function(_, _) return function(...) return obj end end,
    __call = function(...) return obj end,
    __newindex = function(t, k, v) rawset(t, k, v) end,
  })
  return obj
end

-- Mock modal that tracks bindings
local function createMockModal()
  local modal = {}
  modal._bindings = {}

  function modal:bind(mods, key, ...)
    local args = {...}
    local label, pressFn
    if type(args[1]) == "string" then
      label = args[1]
      pressFn = args[2]
    else
      label = nil
      pressFn = args[1]
    end
    table.insert(self._bindings, {
      mods = mods,
      key = key,
      label = label,
      pressFn = pressFn,
    })
  end

  function modal:enter() end
  function modal:exit() end
  function modal:entered() end
  function modal:exited() end

  modal.new = function()
    return createMockModal()
  end

  return modal
end

-- hs.hotkey
mock.hotkey = {
  modal = { new = function() return createMockModal() end },
  bind = function(...) return chainable() end,
  getHotkeys = function() return {} end,
  alertDuration = 0,
}

-- hs.canvas
local function createMockCanvas()
  local canvas = {}
  local elements = {}
  setmetatable(canvas, {
    __newindex = function(t, k, v)
      if type(k) == "number" then
        elements[k] = v
      else
        rawset(t, k, v)
      end
    end,
    __index = function(t, k)
      if type(k) == "number" then
        return elements[k]
      end
      -- Return chainable methods
      return function(...) return canvas end
    end,
  })
  canvas._default = {}
  return canvas
end

mock.canvas = {
  new = function(...) return createMockCanvas() end,
  windowLevels = { overlay = 1, modalPanel = 2, status = 3 },
  windowBehaviors = { stationary = 1, canJoinAllSpaces = 2 },
}

-- hs.drawing
mock.drawing = {
  color = {
    white = {white=1},
    black = {white=0},
    blue = {red=0, green=0, blue=1},
    osx_red = {red=1, green=0, blue=0},
    osx_green = {red=0, green=1, blue=0},
    osx_yellow = {red=1, green=1, blue=0},
    x11 = setmetatable({}, {
      __index = function(_, name)
        return {red=0.5, green=0.5, blue=0.5, alpha=1, _name=name}
      end,
    }),
  },
}

-- hs.screen
local function createMockScreen(name, w, h)
  local screen = {}
  local frame = {x=0, y=0, w=w or 1920, h=h or 1080}
  function screen:name() return name or "Built-in Retina Display" end
  function screen:fullFrame() return {x=frame.x, y=frame.y, w=frame.w, h=frame.h} end
  function screen:frame() return self:fullFrame() end
  function screen:absoluteToLocal(f) return {x=f.x-frame.x, y=f.y-frame.y, w=f.w, h=f.h} end
  function screen:localToAbsolute(f) return {x=f.x+frame.x, y=f.y+frame.y, w=f.w, h=f.h} end
  return screen
end

mock.screen = {
  mainScreen = function() return createMockScreen("Built-in Retina Display", 1920, 1080) end,
  primaryScreen = function() return createMockScreen("Built-in Retina Display", 1920, 1080) end,
  allScreens = function() return {createMockScreen("Built-in Retina Display", 1920, 1080)} end,
  watcher = {
    newWithActiveScreen = function(...) return chainable() end,
  },
}

-- hs.window
mock.window = {
  focusedWindow = function()
    local win = {}
    function win:frame() return {x=0, y=0, w=960, h=540} end
    function win:screen() return mock.screen.mainScreen() end
    function win:setFrame() end
    function win:focus() end
    function win:id() return 1 end
    function win:isVisible() return true end
    function win:isStandard() return true end
    function win:raise() end
    function win:moveToScreen() end
    function win:moveOneScreenNorth() end
    function win:moveOneScreenSouth() end
    function win:moveOneScreenWest() end
    function win:moveOneScreenEast() end
    return win
  end,
  animationDuration = 0,
}

-- hs.application
mock.application = {
  frontmostApplication = function()
    local app = {}
    function app:bundleID() return "com.test.current" end
    function app:name() return "TestApp" end
    return app
  end,
  get = function(...) return nil end,
  launchOrFocus = function(...) end,
  launchOrFocusByBundleID = function(...) end,
  applicationsForBundleID = function(...) return {} end,
}

-- hs.timer
mock.timer = {
  doAfter = function(delay, fn) return chainable() end,
  doEvery = function(interval, fn) return chainable() end,
  secondsSinceEpoch = function() return os.time() end,
}

-- hs.eventtap
mock.eventtap = {
  new = function(...) return chainable() end,
  keyStroke = function(...) end,
  event = { types = { keyDown = 1 } },
}

-- hs.alert
mock.alert = {
  show = function(...) return 1 end,
  closeSpecific = function(...) end,
}

-- hs.pasteboard
mock.pasteboard = {
  getContents = function() return "" end,
}

-- hs.chooser
mock.chooser = {
  new = function(...) return chainable() end,
}

-- hs.urlevent
mock.urlevent = {
  getDefaultHandler = function(...) return "com.apple.Safari" end,
  openURL = function(...) end,
}

-- hs.webview
mock.webview = {
  new = function(...) return chainable() end,
}

-- hs.pathwatcher
mock.pathwatcher = {
  new = function(...) return chainable() end,
}

-- hs.task
mock.task = {
  new = function(...) return chainable() end,
}

-- hs.osascript
mock.osascript = {
  applescript = function(...) return true, "", {} end,
}

-- hs.hints
mock.hints = {
  showTitleThresh = 0,
}

-- hs.mouse
mock.mouse = {
  getCurrentScreen = function() return mock.screen.mainScreen() end,
}

-- hs.toggleConsole
mock.toggleConsole = function() end

-- hs.reload
mock.reload = function() end

-- hs.execute
mock.execute = function(...) return "", true, 0 end

-- Install the mock as the global `hs`
function mock.install()
  _G.hs = mock
  -- Also provide os.getenv if not present
  if not os.getenv then
    os.getenv = function(var)
      if var == "HOME" then return "/tmp" end
      return nil
    end
  end
end

return mock
