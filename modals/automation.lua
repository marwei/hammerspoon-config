autoM = hs.hotkey.modal.new()
autoM.name = "Workflow"

function autoM:entered()
  if show_modal == true then toggle_modal_key_display(autoM) end
end

function autoM:exited()
  if show_modal == true then toggle_modal_key_display(autoM) end
end

autoM:bind('', 'escape', function() autoM:exit() end)
autoM:bind(hyper, 'escape', function() autoM:exit() end)

-- Read current default https handler from LaunchServices plist.
local function currentDefaultBrowser()
  local out = hs.execute(
    "plutil -extract LSHandlers json -o - " ..
    "~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist 2>/dev/null",
    false
  )
  if not out then return nil end
  if out:find('"com.microsoft.edgemac","LSHandlerURLScheme":"https"', 1, true) then
    return "edgemac"
  end
  if out:find('"com.apple.safari","LSHandlerURLScheme":"https"', 1, true) then
    return "safari"
  end
  return nil
end

local function runVPN()
  autoM:exit()
  hs.task.new("/usr/bin/shortcuts", function(exitCode)
    if exitCode == 0 then
      hs.alert.show("VPN connection initiated")
    else
      hs.alert.show("Failed to run VPN shortcut")
    end
  end, {"run", "Connect VPN"}):start()
end

local function runCerebral()
  autoM:exit()
  hs.eventtap.keyStroke({"cmd"}, "c")
  hs.timer.doAfter(0.2, function()
    hs.task.new("/usr/bin/shortcuts", function(exitCode)
      if exitCode == 0 then
        hs.alert.show("Cerebral shortcut executed")
      else
        hs.alert.show("Failed to run Cerebral shortcut")
      end
    end, {"run", "Cerebral"}):start()
  end)
end

local function openClaude()
  autoM:exit()
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
end

local function toggleBrowser()
  autoM:exit()
  local current = currentDefaultBrowser()
  local target = (current == "safari") and "edgemac" or "safari"
  local label = (target == "safari") and "Safari" or "Edge"
  hs.task.new("/opt/homebrew/bin/defaultbrowser", function(exitCode, _, stdErr)
    if exitCode == 0 then
      hs.alert.show("Default Browser: " .. label, 2)
    else
      hs.alert.show("Failed to set browser: " .. (stdErr or "unknown error"))
    end
  end, {target}):start()
end

autoM.items = {
  {key = "V", label = "Connect VPN",                       icon = "lucide:shield-check", action = runVPN},
  {key = "C", label = "Cerebral Shortcut",                 icon = "lucide:brain",        action = runCerebral},
  {key = "L", label = "Open Claude in iTerm",              icon = "lucide:terminal",     action = openClaude},
  {key = "B", label = "Toggle Default Browser",
   icon = "app-pair:com.apple.Safari,com.microsoft.edgemac", action = toggleBrowser},
}

for _, it in ipairs(autoM.items) do
  autoM:bind('', it.key, it.label, it.action)
  autoM:bind(hyper, it.key, it.action)
end

require('lib/icons').prewarm(autoM.items)
