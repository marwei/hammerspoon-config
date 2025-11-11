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

appM:bind('', 'B', 'Browser (Default)', function()
  local defaultBrowser = hs.urlevent.getDefaultHandler('http')
  if defaultBrowser then
    hs.application.launchOrFocusByBundleID(defaultBrowser)
  else
    hs.alert.show('No default browser found')
  end
  appM:exit()
end)

appM:bind('', 'O', 'Notes (Obsidian)', function()
  hs.application.launchOrFocus('Obsidian')
  appM:exit()
end)

appM:bind('', 'I', 'Terminal (iTerm)', function()
  hs.application.launchOrFocus('iTerm')
  appM:exit()
end)

appM:bind('', 'T', 'Microsoft Teams', function()
  hs.application.launchOrFocus('Microsoft Teams')
  appM:exit()
end)

appM:bind('', 'E', 'Email (Outlook/Gmail)', function()
  local outlookPath = '/Applications/Microsoft Outlook.app'
  local file = io.open(outlookPath .. '/Contents/Info.plist', 'r')

  if file then
    file:close()
    hs.application.launchOrFocus('Microsoft Outlook')
  else
    hs.urlevent.openURL('https://mail.google.com')
  end

  appM:exit()
end)

appM:bind('', 'V', 'VSCode', function()
  hs.application.launchOrFocus('Visual Studio Code')
  appM:exit()
end)

-- Helper function to check if app exists
local function appExists(path)
  local file = io.open(path .. '/Contents/Info.plist', 'r')
  if file then
    file:close()
    return true
  end
  return false
end

-- Conditionally bind Microsoft Loop if it exists
local loopPath = '/Users/wei/Applications/Edge Apps.localized/Microsoft Loop.app'
if appExists(loopPath) then
  appM:bind('', 'L', 'Microsoft Loop', function()
    hs.application.launchOrFocus('Microsoft Loop')
    appM:exit()
  end)
end

-- Conditionally bind Granola if it exists
local granolaPath = '/Applications/Granola.app'
if appExists(granolaPath) then
  appM:bind('', 'G', 'Granola', function()
    hs.application.launchOrFocus('Granola')
    appM:exit()
  end)
end
