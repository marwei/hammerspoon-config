-- Test: configuration consistency
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

-- Setup: load mock and config
local hs_mock = require("tests.hs_mock")
hs_mock.install()

-- Load style first (config doesn't need it, but modules do)
require("lib.style")
require("lib.screens")

-- Load config
require("config")

print("test_config.lua")

test("module_list exists and is a table", function()
  assert(type(module_list) == "table", "module_list should be a table")
end)

test("module_list is not empty", function()
  assert(#module_list > 0, "module_list should not be empty")
end)

test("all modules in module_list have corresponding files", function()
  for _, mod in ipairs(module_list) do
    local path = mod:gsub("%.", "/") .. ".lua"
    local f = io.open(path, "r")
    assert(f, "missing file for module: " .. mod .. " (expected " .. path .. ")")
    if f then f:close() end
  end
end)

test("no duplicate modules in module_list", function()
  local seen = {}
  for _, mod in ipairs(module_list) do
    assert(not seen[mod], "duplicate module: " .. mod)
    seen[mod] = true
  end
end)

test("show_modal is a boolean", function()
  assert(type(show_modal) == "boolean", "show_modal should be a boolean, got " .. type(show_modal))
end)

test("background_jobs table is well-formed", function()
  assert(type(background_jobs) == "table", "background_jobs should be a table")
  assert(type(background_jobs.enabled) == "boolean", "background_jobs.enabled should be a boolean")
  assert(type(background_jobs.jobs) == "table", "background_jobs.jobs should be a table")
end)

test("each background job has required fields", function()
  for name, job in pairs(background_jobs.jobs) do
    assert(type(job.enabled) == "boolean", "job '" .. name .. "' missing enabled boolean")
    assert(type(job.config) == "table", "job '" .. name .. "' missing config table")
  end
end)

return passed, failed
