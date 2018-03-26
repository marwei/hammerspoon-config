appM = hs.hotkey.modal.new()

function appM:entered()
  toggle_modal_light(lawngreen,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function appM:exited()
  toggle_modal_light(lawngreen,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

appM:bind('', 'escape', function() appM:exit() end)

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
  end)
end
