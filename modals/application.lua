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

appM:bind('', 'B', 'Browser (Chrome)', function()
  hs.application.launchOrFocus('Google Chrome')
  appM:exit()
end)

appM:bind('', 'N', 'Notes (Obsidian)', function()
  hs.application.launchOrFocus('Obsidian')
  appM:exit()
end)

appM:bind('', 'T', 'Terminal (iTerm)', function()
  hs.application.launchOrFocus('iTerm')
  appM:exit()
end)
