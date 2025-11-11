autoM = hs.hotkey.modal.new()

function autoM:entered()
  toggle_modal_light(purple, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function autoM:exited()
  toggle_modal_light(purple, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

autoM:bind('', 'escape', function() autoM:exit() end)

autoM:bind('', 'V', 'Connect VPN', function()
  -- Trigger macOS Shortcut "Connect VPN"
  hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.alert.show("VPN connection initiated")
    else
      hs.alert.show("Failed to run VPN shortcut")
    end
  end, {"run", "Connect VPN"}):start()

  autoM:exit()
end)

autoM:bind('', 'C', 'Cerebral', function()
  -- Trigger macOS Shortcut "Cerebral"
  hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.alert.show("Cerebral shortcut executed")
    else
      hs.alert.show("Failed to run Cerebral shortcut")
    end
  end, {"run", "Cerebral"}):start()

  autoM:exit()
end)
