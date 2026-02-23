#!/usr/bin/env lua
-- Test runner: runs all test files and reports results

-- Set up package path to find project modules
local script_dir = arg[0]:match("(.*/)")
if script_dir then
  -- Running from a subdirectory, adjust to project root
  local project_root = script_dir:gsub("tests/$", "")
  if project_root == "" then project_root = "./" end
  package.path = project_root .. "?.lua;" .. project_root .. "?/init.lua;" .. package.path
else
  package.path = "./?.lua;./?/init.lua;" .. package.path
end

local total_passed = 0
local total_failed = 0

local test_files = {
  "tests.test_config",
  "tests.test_modules",
  "tests.test_application_modal",
  "tests.test_window_modal",
}

print("Running tests...\n")

for _, test_module in ipairs(test_files) do
  -- Reset loaded modules between test files to avoid state leakage
  -- (except for the mock itself and this runner)
  local keep = {
    ["tests.hs_mock"] = true,
    ["tests.run_all"] = true,
  }
  local to_remove = {}
  for name, _ in pairs(package.loaded) do
    if not keep[name] and name ~= "_G" then
      table.insert(to_remove, name)
    end
  end
  for _, name in ipairs(to_remove) do
    package.loaded[name] = nil
  end

  -- Clear globals that modules set
  _G.hs = nil
  _G.appM = nil
  _G.resizeM = nil
  _G.layoutM = nil
  _G.cerebralM = nil
  _G.hyper = nil
  _G.module_list = nil
  _G.show_modal = nil
  _G.background_jobs = nil
  _G.resize_win = nil
  _G.move_win = nil
  _G.toggle_modal_light = nil
  _G.toggle_modal_key_display = nil
  _G.show_global_shortcuts = nil
  _G.getNativeScreen = nil
  _G.getUltraWideScreen = nil
  _G.is_in = nil
  _G.print_table = nil
  _G.cheatsheet_view = nil
  _G.global_shortcuts_view = nil
  _G.modal_light = nil
  -- Color globals
  _G.white = nil
  _G.black = nil
  _G.blue = nil
  _G.osx_red = nil
  _G.osx_green = nil
  _G.osx_yellow = nil
  _G.tomato = nil
  _G.dodgerblue = nil
  _G.firebrick = nil
  _G.lawngreen = nil
  _G.lightseagreen = nil
  _G.purple = nil
  _G.royalblue = nil
  _G.sandybrown = nil
  _G.cyan = nil
  _G.white90 = nil
  _G.black50 = nil
  _G.darkblue = nil
  _G.gray = nil
  _G.hotkey_filtered = nil

  -- Use dofile so we get multiple return values (require only returns one)
  local test_path = test_module:gsub("%.", "/") .. ".lua"
  local ok, result_or_err, failed = pcall(dofile, test_path)
  if ok then
    local p = result_or_err or 0
    local f = failed or 0
    total_passed = total_passed + p
    total_failed = total_failed + f
    local status = f == 0 and "OK" or "FAILED"
    print(string.format("  %s: %d passed, %d failed [%s]", test_module, p, f, status))
  else
    total_failed = total_failed + 1
    print(string.format("  %s: ERROR loading - %s", test_module, tostring(result_or_err)))
  end
  print("")
end

print(string.format("Total: %d passed, %d failed", total_passed, total_failed))

if total_failed > 0 then
  os.exit(1)
else
  print("\nAll tests passed!")
  os.exit(0)
end
