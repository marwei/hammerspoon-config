-- Helper function to toggle browser
local function toggleBrowser(currentOutput, browsers)
  local current = currentOutput:match("^%s*(.-)%s*$"):lower()  -- Trim and lowercase

  -- Find current browser index
  local currentIndex = 0
  for i, browser in ipairs(browsers) do
    if current:find(browser.id:lower()) or current:find(browser.name:lower()) then
      currentIndex = i
      break
    end
  end

  -- Get next browser (wrap around)
  local nextIndex = (currentIndex % #browsers) + 1
  local nextBrowser = browsers[nextIndex]

  -- Try homebrew path first
  local task = hs.task.new("/opt/homebrew/bin/defaultbrowser", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      hs.alert.show("Default Browser: " .. nextBrowser.name, 2)
    else
      -- Try alternate path for Intel Macs
      hs.task.new("/usr/local/bin/defaultbrowser", function(exitCode2, stdOut2, stdErr2)
        if exitCode2 == 0 then
          hs.alert.show("Default Browser: " .. nextBrowser.name, 2)
        else
          hs.alert.show("Failed to set browser: " .. (stdErr2 or "unknown error"))
        end
      end, {nextBrowser.id}):start()
    end
  end, {nextBrowser.id})

  task:start()
end

-- Workflow actions stored separately (functions can't be in chooser choices)
local workflowActions = {
  vpn = function()
    hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
      if exitCode == 0 then
        hs.alert.show("VPN connection initiated")
      else
        hs.alert.show("Failed to run VPN shortcut")
      end
    end, {"run", "Connect VPN"}):start()
  end,

  cerebral = function()
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.doAfter(0.2, function()
      hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          hs.alert.show("Cerebral shortcut executed")
        else
          hs.alert.show("Failed to run Cerebral shortcut")
        end
      end, {"run", "Cerebral"}):start()
    end)
  end,

  claude = function()
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
  end,

  browser = function()
    local browsers = {
      {id = "safari", name = "Safari"},
      {id = "chrome", name = "Google Chrome"},
      {id = "firefox", name = "Firefox"},
      {id = "brave", name = "Brave Browser"},
      {id = "arc", name = "Arc"}
    }

    hs.task.new("/opt/homebrew/bin/defaultbrowser", function(exitCode, stdOut, stdErr)
      if exitCode ~= 0 then
        hs.task.new("/usr/local/bin/defaultbrowser", function(exitCode2, stdOut2, stdErr2)
          if exitCode2 ~= 0 then
            hs.alert.show("Error: defaultbrowser not installed\nRun: brew install defaultbrowser")
            return
          end
          toggleBrowser(stdOut2, browsers)
        end):start()
        return
      end
      toggleBrowser(stdOut, browsers)
    end):start()
  end
}

-- Define workflow choices (no functions allowed)
local workflowChoices = {
  {
    text = "Connect VPN",
    subText = "Trigger macOS VPN Shortcut",
    id = "vpn"
  },
  {
    text = "Cerebral",
    subText = "Copy selected text and run Cerebral shortcut",
    id = "cerebral"
  },
  {
    text = "Open Claude in Hammerspoon",
    subText = "Open iTerm in ~/.hammerspoon with Claude",
    id = "claude"
  },
  {
    text = "Toggle Default Browser",
    subText = "Cycle through Safari → Chrome → Firefox → Brave → Arc",
    id = "browser"
  }
}

-- Automation chooser menu
autoChooser = hs.chooser.new(function(choice)
  if not choice then return end

  -- Execute the selected action by ID
  if choice.id and workflowActions[choice.id] then
    workflowActions[choice.id]()
  end
end)

-- Configure chooser appearance
autoChooser:placeholderText("Search workflows...")
autoChooser:searchSubText(true)
autoChooser:width(20)
autoChooser:rows(10)

-- Function to show the workflow chooser
function showWorkflowChooser()
  autoChooser:choices(workflowChoices)
  autoChooser:show()
end

-- Keep autoM for backward compatibility with init.lua
autoM = {
  enter = showWorkflowChooser
}
