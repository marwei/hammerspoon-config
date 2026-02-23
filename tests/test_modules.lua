-- Test: module loading and structure
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

-- Setup: load mock and dependencies
local hs_mock = require("tests.hs_mock")
hs_mock.install()

require("lib.style")
require("lib.screens")
require("lib.modal_display")
require("lib.utility")

print("test_modules.lua")

-- Style tests
test("style defines expected color globals", function()
  local expected = {"white", "black", "blue", "firebrick", "lawngreen",
                    "dodgerblue", "purple", "royalblue", "sandybrown", "cyan"}
  for _, name in ipairs(expected) do
    assert(_G[name] ~= nil, "missing color global: " .. name)
  end
end)

test("cyan color is defined", function()
  assert(cyan ~= nil, "cyan should be defined in lib/style.lua")
end)

-- Screens tests
test("getNativeScreen is a global function", function()
  assert(type(getNativeScreen) == "function", "getNativeScreen should be a global function")
end)

test("getUltraWideScreen is a global function", function()
  assert(type(getUltraWideScreen) == "function", "getUltraWideScreen should be a global function")
end)

test("getNativeScreen returns a screen object", function()
  local screen = getNativeScreen()
  assert(screen ~= nil, "getNativeScreen should return a screen")
  assert(type(screen.name) == "function", "screen should have name() method")
end)

test("getUltraWideScreen returns a screen object", function()
  local screen = getUltraWideScreen()
  assert(screen ~= nil, "getUltraWideScreen should return a screen")
end)

-- Modal display tests
test("toggle_modal_light is a global function", function()
  assert(type(toggle_modal_light) == "function", "toggle_modal_light should be a global function")
end)

test("toggle_modal_key_display is a global function", function()
  assert(type(toggle_modal_key_display) == "function", "toggle_modal_key_display should be a global function")
end)

test("show_global_shortcuts is a global function", function()
  assert(type(show_global_shortcuts) == "function", "show_global_shortcuts should be a global function")
end)

-- Check that hotkey_filtered is NOT an accidental global
test("hotkey_filtered is not a global", function()
  assert(_G.hotkey_filtered == nil, "hotkey_filtered should be local, not global")
end)

-- Utility tests
test("is_in is a global function", function()
  assert(type(is_in) == "function", "is_in should be a global function")
end)

test("print_table is a global function", function()
  assert(type(print_table) == "function", "print_table should be a global function")
end)

return passed, failed
