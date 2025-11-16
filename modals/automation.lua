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

autoM:bind('', 'F', 'Cerebral', function()
  -- Copy selected text to clipboard if any
  hs.eventtap.keyStroke({"cmd"}, "c")

  -- Wait a moment for copy to complete, then trigger macOS Shortcut "Cerebral"
  hs.timer.doAfter(0.2, function()
    hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
      if exitCode == 0 then
        hs.alert.show("Cerebral shortcut executed")
      else
        hs.alert.show("Failed to run Cerebral shortcut")
      end
    end, {"run", "Cerebral"}):start()
  end)

  autoM:exit()
end)

autoM:bind('', '/', 'Open Claude in Hammerspoon folder', function()
  local script = [[
    tell application "iTerm"
      activate
      try
        select first window
        set newTab to (create tab with default profile in first window)
        tell current session of newTab
          write text "cd ~/.hammerspoon && Claude"
        end tell
      on error
        create window with default profile
        tell current session of current window
          write text "cd ~/.hammerspoon && Claude"
        end tell
      end try
    end tell
  ]]
  hs.osascript.applescript(script)

  autoM:exit()
end)
