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

-- Check expected bindings exist (only bare-modifier bindings, skip hyper duplicates)
local function isHyperMod(mods)
  return type(mods) == "table" and #mods == 4
end

local function hasBinding(key)
  for _, b in ipairs(appM._bindings) do
    if b.key == key and not isHyperMod(b.mods) then return true end
  end
  return false
end

test("bindings match app_shortcuts config", function()
  -- One binding per app_shortcuts entry plus escape (ignore hyper duplicates)
  local bareCount = 0
  for _, b in ipairs(appM._bindings) do
    if not isHyperMod(b.mods) then bareCount = bareCount + 1 end
  end
  local expectedCount = #app_shortcuts + 1
  assert(bareCount == expectedCount,
    "expected " .. expectedCount .. " bindings, got " .. bareCount)
end)

test("escape binding exists", function()
  assert(hasBinding('escape'), "missing escape binding")
end)

test("all app_shortcuts keys have bindings", function()
  for _, s in ipairs(app_shortcuts) do
    assert(hasBinding(s.key), "missing binding for key: " .. s.key)
  end
end)

test("no duplicate key bindings", function()
  local seen = {}
  for _, b in ipairs(appM._bindings) do
    local modStr = type(b.mods) == "table" and table.concat(b.mods, "+") or tostring(b.mods or "")
    local id = modStr .. "+" .. b.key
    assert(not seen[id], "duplicate binding: " .. id)
    seen[id] = true
  end
end)

test("all bindings have descriptive labels", function()
  for _, b in ipairs(appM._bindings) do
    -- Only check bare-modifier bindings; hyper duplicates don't need labels
    if b.key ~= "escape" and not isHyperMod(b.mods) then
      assert(b.label ~= nil and b.label ~= "",
        "binding for key '" .. b.key .. "' missing label")
    end
  end
end)

test("labels match config", function()
  for _, s in ipairs(app_shortcuts) do
    local expectedLabel = s.label or s.app
    for _, b in ipairs(appM._bindings) do
      if b.key == s.key then
        assert(b.label == expectedLabel,
          "key '" .. s.key .. "': expected label '" .. expectedLabel ..
          "', got '" .. tostring(b.label) .. "'")
        break
      end
    end
  end
end)

test("app_shortcuts entries have required fields", function()
  for i, s in ipairs(app_shortcuts) do
    assert(s.key, "entry " .. i .. " missing 'key'")
    assert(s.app or s.url, "entry " .. i .. " missing 'app' or 'url'")
  end
end)

return passed, failed
