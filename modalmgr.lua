modalmgr_keys = modalmgr_keys or {{"option", "cmd", "shift", "ctrl"}, "Q"}
modalmgr = hs.hotkey.modal.new(modalmgr_keys[1], modalmgr_keys[2], 'Toggle Modal Supervisor')

function modalmgr:entered()
  modal_stat(white,1)
end

function modalmgr:exited()
  if modal_tray then modal_tray:hide() end
  exit_others()
  if hotkeytext then
    hotkeytext:delete()
    hotkeytext=nil
    hotkeybg:delete()
    hotkeybg=nil
  end
end
modalmgr:bind(modalmgr_keys[1], modalmgr_keys[2], "Toggle Modal Supervisor", function() modalmgr:exit() end)

if appM then
  appM_keys = appM_keys or {{"option", "ctrl", "shift", "cmd"}, "P"}
  if string.len(appM_keys[2]) > 0 then
    modalmgr:bind(appM_keys[1], appM_keys[2], 'Enter Application Mode', function() exit_others() appM:enter() end)
  end
end
if hsearch_loaded then
  hsearch_keys = hsearch_keys or {{"option", "ctrl", "shift", "cmd"}, "G"}
  if string.len(hsearch_keys[2]) > 0 then
    modalmgr:bind(hsearch_keys[1], hsearch_keys[2], 'Launch Hammer Search', function() launchChooser() end)
  end
end
if timerM then
  timerM_keys = timerM_keys or {{"option", "ctrl", "shift", "cmd"}, "I"}
  if string.len(timerM_keys[2]) > 0 then
    modalmgr:bind(timerM_keys[1], timerM_keys[2], 'Enter Timer Mode', function() exit_others() timerM:enter() end)
  end
end
if resizeM then
  resizeM_keys = resizeM_keys or {{"option", "ctrl", "shift", "cmd"}, "M"}
  if string.len(resizeM_keys[2]) > 0 then
    modalmgr:bind(resizeM_keys[1], resizeM_keys[2], 'Enter Resize Mode', function() exit_others() resizeM:enter() end)
  end
end
if cheatsheetM then
  cheatsheetM_keys = cheatsheetM_keys or {{"option", "ctrl", "shift", "cmd"}, "S"}
  if string.len(cheatsheetM_keys[2]) > 0 then
    modalmgr:bind(cheatsheetM_keys[1], cheatsheetM_keys[2], 'Enter Cheatsheet Mode', function() exit_others() cheatsheetM:enter() end)
  end
end
showtime_keys = showtime_keys or {{"option", "ctrl", "shift", "cmd"}, "C"}
if string.len(showtime_keys[2]) > 0 then
  modalmgr:bind(showtime_keys[1], showtime_keys[2], 'Show Digital Clock', function() show_time() end)
end
if viewM then
  viewM_keys = viewM_keys or {{"option", "ctrl", "shift", "cmd"}, "V"}
  if string.len(viewM_keys[2]) > 0 then
    modalmgr:bind(viewM_keys[1], viewM_keys[2], 'Enter View Mode', function() exit_others() viewM:enter() end)
  end
end
toggleconsole_keys = toggleconsole_keys or {{"option", "ctrl", "shift", "cmd"}, "Z"}
if string.len(toggleconsole_keys[2]) > 0 then
  modalmgr:bind(toggleconsole_keys[1], toggleconsole_keys[2], 'Toggle Hammerspoon Console', function() hs.toggleConsole() end)
end
winhints_keys = winhints_keys or {{"option", "ctrl", "shift", "cmd"}, "T"}
if string.len(winhints_keys[2]) > 0 then
  modalmgr:bind(winhints_keys[1], winhints_keys[2], 'Show Windows Hint', function() exit_others() hs.hints.windowHints() end)
end

if modalmgr then
  if launch_modalmgr == nil then launch_modalmgr = true end
  if launch_modalmgr == true then modalmgr:enter() end
end
