-- Test: application modal bindings
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

-- Need resize_win available for application modal
require("modals.window")

-- Load the application modal
require("modals.application")

print("test_application_modal.lua")

test("appM modal exists", function()
  assert(appM ~= nil, "appM should exist as a global")
end)

test("appM has bindings", function()
  assert(#appM._bindings > 0, "appM should have bindings")
end)

-- Check expected bindings exist
local function hasBinding(key)
  for _, b in ipairs(appM._bindings) do
    if b.key == key then return true end
  end
  return false
end

local function getBinding(key)
  for _, b in ipairs(appM._bindings) do
    if b.key == key then return b end
  end
  return nil
end

local expected_keys = {'A', 'E', 'F', 'I', 'P', 'S', 'T', 'V', 'W', 'tab', 'space', 'return', 'escape'}
for _, key in ipairs(expected_keys) do
  test("binding exists for key: " .. key, function()
    assert(hasBinding(key), "missing binding for key: " .. key)
  end)
end

-- Conditional bindings (L and G) may or may not exist depending on installed apps
test("no duplicate key bindings", function()
  local seen = {}
  for _, b in ipairs(appM._bindings) do
    local id = (b.mods or "") .. "+" .. b.key
    assert(not seen[id], "duplicate binding: " .. id)
    seen[id] = true
  end
end)

test("all bindings have descriptive labels", function()
  for _, b in ipairs(appM._bindings) do
    if b.key ~= "escape" then
      assert(b.label ~= nil and b.label ~= "",
        "binding for key '" .. b.key .. "' missing label")
    end
  end
end)

return passed, failed
