require('lib/style')
require('lib/modal_display')
require('lib/utility')
require('hyper')
require('fn')
require('config')
modal_list = {}
for i=1,#module_list do
  require(module_list[i])
end
require("modalmgr")

hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0

hsreload_keys = {hyper, "R"}
showhotkey_keys = {hyper, "H"}

hs.hotkey.bind(hsreload_keys[1], hsreload_keys[2], "Reload Configuration", function() hs.reload() end)
hs.hotkey.bind(showhotkey_keys[1], showhotkey_keys[2], "Toggle Hotkeys Cheatsheet", function() showavailableHotkey() end)

activeModals = {}

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
