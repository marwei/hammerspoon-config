require('lib/style')
require('lib/screens')
require('lib/modal_display')
require('lib/utility')
require('hyper')
require('fn')
require('config')
for i=1,#module_list do
  require(module_list[i])
end

hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0

hsreload_keys = {hyper, "R"}
showhotkey_keys = {hyper, "H"}

resizeM_keys = {hyper, "M"}
appM_keys = {hyper, "space"}
layoutM_keys = {hyper, "T"}
autoM_keys = {hyper, "F"}
cerebralM_keys = {hyper, "G"}
toggleconsole_keys = {hyper, "Z"}

hs.hotkey.bind(hsreload_keys[1], hsreload_keys[2], "Reload Configuration", function() hs.reload() end)
hs.hotkey.bind(showhotkey_keys[1], showhotkey_keys[2], "Toggle Global Shortcuts", function() show_global_shortcuts() end)
hs.hotkey.bind(toggleconsole_keys[1], toggleconsole_keys[2], 'Toggle Hammerspoon Console', function() hs.toggleConsole() end)

hs.hotkey.bind(resizeM_keys[1], resizeM_keys[2], 'Enter Resize Mode', function() resizeM:enter() end)
hs.hotkey.bind(appM_keys[1], appM_keys[2], 'Enter App Launcher Mode', function() appM:enter() end)
hs.hotkey.bind(layoutM_keys[1], layoutM_keys[2], 'Enter Layout Mode', function() layoutM:enter() end)
hs.hotkey.bind(autoM_keys[1], autoM_keys[2], 'Enter Workflow Mode', function() autoM:enter() end)
hs.hotkey.bind(cerebralM_keys[1], cerebralM_keys[2], 'Enter Cerebral Mode', function() cerebralM:enter() end)

-- Kay Work Co-Pilot
kayM_keys = {hyper, "K"}
hs.hotkey.bind(kayM_keys[1], kayM_keys[2], 'Enter Kay Mode', function() kayM:enter() end)

globalGC = hs.timer.doEvery(180, collectgarbage)
globalScreenWatcher = hs.screen.watcher.newWithActiveScreen(function(activeChanged)
  if activeChanged then
    if modal_tray then modal_tray:delete() modal_tray = nil end
    if hotkeytext then hotkeytext:delete() hotkeytext = nil end
    if hotkeybg then hotkeybg:delete() hotkeybg = nil end
    if time_draw then time_draw:delete() time_draw = nil end
    if cleanup_cheatsheet_view then cleanup_cheatsheet_view() end
  end
end):start()

-- Auto-reload configuration when files change
configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  local doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end):start()

require('lib/cheatsheet_view').prewarm()

hs.alert.show("Config loaded")
