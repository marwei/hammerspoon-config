appM = hs.hotkey.modal.new()
local modalpkg = {}
modalpkg.id = "appM"
modalpkg.modal = appM
table.insert(modal_list, modalpkg)

function appM:entered()
  for i=1,#modal_list do
    if modal_list[i].id == "appM" then
      table.insert(activeModals, modal_list[i])
    end
  end
  if hotkeytext then
    hotkeytext:delete()
    hotkeytext=nil
    hotkeybg:delete()
    hotkeybg=nil
  end
  if show_applauncher_tips == nil then show_applauncher_tips = true end
  if show_applauncher_tips == true then showavailableHotkey() end
end

function appM:exited()
  for i=1,#activeModals do
    if activeModals[i].id == "appM" then
      table.remove(activeModals, i)
    end
  end
  if hotkeytext then
    hotkeytext:delete()
    hotkeytext=nil
    hotkeybg:delete()
    hotkeybg=nil
  end
end

appM:bind('', 'escape', function() appM:exit() end)
appM:bind('', 'Q', function() appM:exit() end)
appM:bind('', 'tab', function() showavailableHotkey() end)

if not applist then
  applist = {
    {shortcut = 'f',appname = 'Finder'},
    {shortcut = 's',appname = 'Safari'},
    {shortcut = 't',appname = 'Terminal'},
    {shortcut = 'v',appname = 'Activity Monitor'},
    {shortcut = 'y',appname = 'System Preferences'},
  }
end

for i = 1, #applist do
  appM:bind('', applist[i].shortcut, applist[i].appname, function()
    hs.application.launchOrFocus(applist[i].appname)
    appM:exit()
    if hotkeytext then
      hotkeytext:delete()
      hotkeytext=nil
      hotkeybg:delete()
      hotkeybg=nil
    end
  end)
end
