-- Test: window modal bindings and functions
local passed, failed = 0, 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    print("  FAIL: " .. name .. " - " .. tostring(err))
  end
end

-- Setup
local hs_mock = require("tests.hs_mock")
hs_mock.install()

require("lib.style")
require("lib.screens")
require("lib.modal_display")
require("lib.utility")
require("hyper")
require("config")
require("modals.window")

print("test_window_modal.lua")

test("resizeM modal exists", function()
  assert(resizeM ~= nil, "resizeM should exist as a global")
end)

test("resize_win function exists", function()
  assert(type(resize_win) == "function", "resize_win should be a global function")
end)

test("move_win function exists", function()
  assert(type(move_win) == "function", "move_win should be a global function")
end)

-- Check expected bindings
local function hasBinding(key, mods)
  mods = mods or ''
  for _, b in ipairs(resizeM._bindings) do
    if b.key == key and b.mods == mods then return true end
  end
  return false
end

-- Basic directional bindings
local basic_keys = {'H', 'J', 'K', 'L', 'F', 'C', 'escape'}
for _, key in ipairs(basic_keys) do
  test("binding exists for key: " .. key, function()
    assert(hasBinding(key), "missing binding for key: " .. key)
  end)
end

-- Shift variants
test("binding exists for shift+H", function()
  assert(hasBinding('H', 'shift'), "missing binding for shift+H")
end)

test("binding exists for shift+L", function()
  assert(hasBinding('L', 'shift'), "missing binding for shift+L")
end)

-- Arrow keys for monitor movement
local arrow_keys = {'up', 'down', 'left', 'right'}
for _, key in ipairs(arrow_keys) do
  test("binding exists for arrow key: " .. key, function()
    assert(hasBinding(key), "missing binding for arrow key: " .. key)
  end)
end

-- Verify F and C bindings use resize_win (not inline reimplementation)
-- We check this by reading the source file
test("F binding calls resize_win (not inline)", function()
  local f = io.open("modals/window.lua", "r")
  assert(f, "could not open modals/window.lua")
  local content = f:read("*a")
  f:close()

  -- The F binding should be a one-liner calling resize_win
  local pattern = "resizeM:bind%('', 'F'.-function%(%)" .. "%s*resize_win%('fullscreen'%)"
  assert(content:match(pattern), "F binding should call resize_win('fullscreen') directly")
end)

test("C binding calls resize_win (not inline)", function()
  local f = io.open("modals/window.lua", "r")
  assert(f, "could not open modals/window.lua")
  local content = f:read("*a")
  f:close()

  local pattern = "resizeM:bind%('', 'C'.-function%(%)" .. "%s*resize_win%('center'%)"
  assert(content:match(pattern), "C binding should call resize_win('center') directly")
end)

test("all bindings have descriptive labels", function()
  for _, b in ipairs(resizeM._bindings) do
    if b.key ~= "escape" then
      assert(b.label ~= nil and b.label ~= "",
        "binding for key '" .. b.key .. "' missing label")
    end
  end
end)

return passed, failed
