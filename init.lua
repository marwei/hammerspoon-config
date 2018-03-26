require('lib/style')
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

appM_keys = {hyper, "P"}
resizeM_keys = {hyper, "M"}
toggleconsole_keys = {hyper, "Z"}
winhints_keys = {hyper, "T" }

hs.hotkey.bind(hsreload_keys[1], hsreload_keys[2], "Reload Configuration", function() hs.reload() end)
hs.hotkey.bind(showhotkey_keys[1], showhotkey_keys[2], "Toggle Hotkeys Cheatsheet", function() showavailableHotkey() end)
hs.hotkey.bind(toggleconsole_keys[1], toggleconsole_keys[2], 'Toggle Hammerspoon Console', function() hs.toggleConsole() end)
hs.hotkey.bind(winhints_keys[1], winhints_keys[2], 'Show Windows Hint', function() hs.hints.windowHints() end)

hs.hotkey.bind(appM_keys[1], appM_keys[2], 'Enter Application Mode', function() appM:enter() end)
hs.hotkey.bind(resizeM_keys[1], resizeM_keys[2], 'Enter Resize Mode', function() resizeM:enter() end)

globalGC = hs.timer.doEvery(180, collectgarbage)
globalScreenWatcher = hs.screen.watcher.newWithActiveScreen(function(activeChanged)
  if activeChanged then
    exit_others()
    clipshowclear()
    if modal_tray then modal_tray:delete() modal_tray = nil end
    if hotkeytext then hotkeytext:delete() hotkeytext = nil end
    if hotkeybg then hotkeybg:delete() hotkeybg = nil end
    if time_draw then time_draw:delete() time_draw = nil end
    if cheatsheet_view then cheatsheet_view:delete() cheatsheet_view = nil end
  end
end):start()
