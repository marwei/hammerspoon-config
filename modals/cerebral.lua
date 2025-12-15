cerebralM = hs.hotkey.modal.new()

-- Path to OCR script
local ocrScriptPath = os.getenv("HOME") .. "/.hammerspoon/lib/ocr.swift"

-- Track clipboard changes for age detection
local lastClipboardChange = hs.timer.secondsSinceEpoch()
local lastClipboardContent = hs.pasteboard.getContents()

-- Clipboard watcher to track last change time
local clipboardWatcher = hs.timer.doEvery(1, function()
  local currentContent = hs.pasteboard.getContents()
  if currentContent ~= lastClipboardContent then
    lastClipboardContent = currentContent
    lastClipboardChange = hs.timer.secondsSinceEpoch()
  end
end)

function cerebralM:entered()
  toggle_modal_light(cyan, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function cerebralM:exited()
  toggle_modal_light(cyan, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

cerebralM:bind('', 'escape', function() cerebralM:exit() end)

-- Helper function to show overlay menu for choosing input method
local function showInputMethodMenu(callback, showClipboardAge)
  local originalClipboard = hs.pasteboard.getContents()

  -- Try to copy selected text first
  hs.eventtap.keyStroke({"cmd"}, "c")

  hs.timer.doAfter(0.2, function()
    local selectedText = hs.pasteboard.getContents()
    local hasSelection = selectedText and selectedText ~= "" and selectedText ~= originalClipboard

    -- Build menu options
    local options = {}

    if hasSelection then
      local preview = selectedText:gsub("\n", " "):sub(1, 60)
      if #selectedText > 60 then preview = preview .. "..." end
      table.insert(options, {
        title = "Selected Text",
        subtitle = preview,
        method = "selection",
        content = selectedText
      })
    end

    if originalClipboard and originalClipboard ~= "" then
      local preview = originalClipboard:gsub("\n", " "):sub(1, 60)
      if #originalClipboard > 60 then preview = preview .. "..." end
      if showClipboardAge then
        local clipboardAge = math.floor(hs.timer.secondsSinceEpoch() - lastClipboardChange)
        preview = preview .. " (" .. clipboardAge .. "s ago)"
      end
      table.insert(options, {
        title = "Clipboard",
        subtitle = preview,
        method = "clipboard",
        content = originalClipboard
      })
    end

    table.insert(options, {
      title = "Screenshot",
      subtitle = "Take interactive screenshot with OCR",
      method = "screenshot",
      content = nil
    })

    -- Create overlay on active screen
    local screen = hs.mouse.getCurrentScreen()
    local focusedWin = hs.window.focusedWindow()
    if focusedWin then
      screen = focusedWin:screen()
    end
    local frame = screen:frame()
    local width = 500
    local lineHeight = 60
    local height = 100 + (#options * lineHeight) + 20  -- Extra space for ESC hint
    local x = frame.x + (frame.w - width) / 2
    local y = frame.y + (frame.h - height) / 2

    local overlay = hs.canvas.new({x=x, y=y, w=width, h=height})
    overlay:level(hs.canvas.windowLevels.overlay)

    -- Background
    overlay[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = {red=0.1, green=0.1, blue=0.15, alpha=0.95},
      roundedRectRadii = {xRadius=12, yRadius=12}
    }

    -- Title
    overlay[2] = {
      type = "text",
      text = "Choose Input Method",
      textColor = {white=1, alpha=0.9},
      textSize = 16,
      textAlignment = "left",
      frame = {x=20, y=15, w=width-40, h=30}
    }

    -- Separator
    overlay[3] = {
      type = "rectangle",
      action = "fill",
      fillColor = {white=1, alpha=0.1},
      frame = {x=20, y=50, w=width-40, h=1}
    }

    -- Options
    local idx = 4
    for i, opt in ipairs(options) do
      local optY = 65 + ((i-1) * lineHeight)

      -- Option number and title
      overlay[idx] = {
        type = "text",
        text = string.format("%d. %s", i, opt.title),
        textColor = {white=1, alpha=1},
        textSize = 14,
        textAlignment = "left",
        frame = {x=25, y=optY, w=width-50, h=22}
      }
      idx = idx + 1

      -- Subtitle
      overlay[idx] = {
        type = "text",
        text = opt.subtitle,
        textColor = {white=1, alpha=0.6},
        textSize = 11,
        textAlignment = "left",
        frame = {x=25, y=optY+22, w=width-50, h=18}
      }
      idx = idx + 1
    end

    -- Add ESC hint at bottom
    local hintY = 65 + (#options * lineHeight) + 5
    overlay[idx] = {
      type = "text",
      text = "Press ESC to skip content capture",
      textColor = {white=1, alpha=0.4},
      textSize = 10,
      textAlignment = "center",
      frame = {x=20, y=hintY, w=width-40, h=15}
    }

    overlay:show()

    -- Keyboard event tap
    local eventtap
    eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
      local key = event:getCharacters()
      local keyCode = event:getKeyCode()

      -- Handle number keys
      if key and tonumber(key) then
        local num = tonumber(key)
        if num >= 1 and num <= #options then
          overlay:delete()
          eventtap:stop()
          local opt = options[num]
          callback(opt.content, opt.method)
          return true
        end
      end

      -- Handle escape - skip content capture
      if keyCode == 53 then  -- Escape key
        overlay:delete()
        eventtap:stop()
        callback("", "skip")
        return true
      end

      return false
    end)
    eventtap:start()
  end)
end

-- Helper function to capture text input - shows menu to choose input method
local function captureInput(callback)
  showInputMethodMenu(function(content, method)
    if method == "skip" then
      callback("")
    elseif method == "screenshot" then
      local alertId = hs.alert.show("Taking screenshot...", 999999)
      local tempImagePath = os.tmpname() .. ".png"
      hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          -- Screenshot taken, now run OCR using Vision framework
          hs.alert.closeSpecific(alertId)
          alertId = hs.alert.show("Processing OCR...", 999999)
          hs.task.new("/usr/bin/swift", function(ocrExitCode, ocrStdOut, ocrStdErr)
            hs.alert.closeSpecific(alertId)
            if ocrExitCode == 0 and ocrStdOut and ocrStdOut ~= "" then
              hs.alert.show("Text extracted ✓", 1)
              callback(ocrStdOut)
            else
              hs.alert.show("No text in screenshot")
              callback("")
            end
            os.remove(tempImagePath)
          end, {ocrScriptPath, tempImagePath}):start()
        else
          -- Screenshot cancelled
          hs.alert.closeSpecific(alertId)
          hs.alert.show("Screenshot cancelled")
          callback("")
        end
      end, {"-i", "-s", tempImagePath}):start()
    else
      callback(content or "")
    end
  end, false)
end

-- Helper function for Record: shows menu to choose input method (with clipboard age)
local function captureInputForRecord(callback)
  showInputMethodMenu(function(content, method)
    if method == "skip" then
      callback("")
    elseif method == "screenshot" then
      local alertId = hs.alert.show("Taking screenshot...", 999999)
      local tempImagePath = os.tmpname() .. ".png"
      hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          -- Screenshot taken, now run OCR using Vision framework
          hs.alert.closeSpecific(alertId)
          alertId = hs.alert.show("Processing OCR...", 999999)
          hs.task.new("/usr/bin/swift", function(ocrExitCode, ocrStdOut, ocrStdErr)
            hs.alert.closeSpecific(alertId)
            if ocrExitCode == 0 and ocrStdOut and ocrStdOut ~= "" then
              hs.alert.show("Text extracted ✓", 1)
              callback(ocrStdOut)
            else
              hs.alert.show("No text in screenshot")
              callback("")
            end
            os.remove(tempImagePath)
          end, {ocrScriptPath, tempImagePath}):start()
        else
          -- Screenshot cancelled
          hs.alert.closeSpecific(alertId)
          hs.alert.show("Screenshot cancelled")
          callback("")
        end
      end, {"-i", "-s", tempImagePath}):start()
    else
      callback(content or "")
    end
  end, true)
end

-- Helper function to save content and open in VSCode
local function saveAndOpenVSCode(content, callback)
  local vaultPath = os.getenv("HOME") .. "/Desktop/Obsidian/work"
  local tempFilePath = vaultPath .. "/_/temp.html"
  local codePath = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

  -- Ensure directory exists
  os.execute("mkdir -p '" .. vaultPath .. "/_'")

  -- Write content to file
  local file = io.open(tempFilePath, "w")
  if file then
    file:write(content)
    file:close()

    -- Open in VSCode and close other editors (using full path to code)
    local vscodeScript = string.format([[
      ("%s" --reuse-window "%s" || "%s" "%s") && \
      "%s" --command 'workbench.action.closeAllEditors' && \
      "%s" --command 'workbench.action.closeAuxiliaryBar' && \
      "%s" --reuse-window "%s"
    ]], codePath, vaultPath, codePath, vaultPath, codePath, codePath, codePath, tempFilePath)

    hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
      if exitCode == 0 then
        -- VSCode opened, now run the callback (chat command)
        if callback then callback() end
      else
        hs.alert.show("VSCode error: " .. (stdErr or "unknown"))
        print("VSCode stdout:", stdOut)
        print("VSCode stderr:", stdErr)
      end
    end, {"-c", vscodeScript}):start()
  else
    hs.alert.show("Failed to save file")
  end
end

-- Helper function to run VSCode chat command
local function runVSCodeChat(mode, prompt)
  local codePath = "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

  hs.timer.doAfter(0.5, function()
    local chatCommand = string.format('"%s" --reuse-window --maximize chat -m %s "%s"', codePath, mode, prompt)
    hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
      if exitCode == 0 then
        hs.alert.show("Cerebral: " .. prompt)
      else
        hs.alert.show("Failed to run chat command")
        print("Chat command error:", stdErr)
      end
    end, {"-c", chatCommand}):start()
  end)
end

cerebralM:bind('', 'R', 'Cerebral - Record', function()
  cerebralM:exit()
  captureInputForRecord(function(content)
    if content == "" then
      -- User cancelled by pressing ESC
      return
    end
    saveAndOpenVSCode(content, function()
      runVSCodeChat("agent", "LOG")
    end)
  end)
end)

cerebralM:bind('', 'T', 'Cerebral - Todo', function()
  cerebralM:exit()
  captureInput(function(content)
    saveAndOpenVSCode(content, function()
      runVSCodeChat("agent", "TODO")
    end)
  end)
end)

cerebralM:bind('', 'A', 'Cerebral - Ask', function()
  cerebralM:exit()

  -- Create a larger input dialog using webview
  local activeScreen = hs.screen.mainScreen()  -- Gets screen with keyboard focus
  local screenFrame = activeScreen:frame()
  local width = 600
  local height = 300
  local x = screenFrame.x + (screenFrame.w - width) / 2
  local y = screenFrame.y + (screenFrame.h - height) / 2

  local inputDialog = hs.webview.new({x=x, y=y, w=width, h=height})
  inputDialog:windowStyle({"titled", "closable"})
  inputDialog:closeOnEscape(true)
  inputDialog:allowTextEntry(true)

  -- Poll for button clicks using title changes
  local checkTimer = nil

  inputDialog:html([[
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          margin: 0;
          padding: 20px;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          display: flex;
          flex-direction: column;
          height: 100vh;
          box-sizing: border-box;
        }
        h2 {
          color: white;
          margin: 0 0 15px 0;
          font-size: 20px;
          font-weight: 600;
        }
        textarea {
          flex: 1;
          width: 100%;
          padding: 12px;
          font-size: 14px;
          border: none;
          border-radius: 8px;
          resize: none;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          box-sizing: border-box;
        }
        textarea:focus {
          outline: none;
          box-shadow: 0 0 0 3px rgba(255,255,255,0.3);
        }
        .buttons {
          margin-top: 15px;
          display: flex;
          gap: 10px;
          justify-content: flex-end;
        }
        button {
          padding: 8px 20px;
          font-size: 14px;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 500;
          transition: all 0.2s;
        }
        #submit {
          background: white;
          color: #667eea;
        }
        #submit:hover {
          transform: translateY(-1px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        #cancel {
          background: rgba(255,255,255,0.2);
          color: white;
        }
        #cancel:hover {
          background: rgba(255,255,255,0.3);
        }
      </style>
    </head>
    <body>
      <h2>Cerebral - Ask</h2>
      <textarea id="input" placeholder="Enter your question..." autofocus></textarea>
      <div class="buttons">
        <button id="cancel" onclick="document.title='CANCEL'">Cancel</button>
        <button id="submit" onclick="document.title='SUBMIT:' + document.getElementById('input').value">Submit</button>
      </div>
      <script>
        const input = document.getElementById('input');

        // Ensure textarea is focused
        window.onload = () => {
          input.focus();
        };

        // Also focus immediately
        setTimeout(() => input.focus(), 50);

        input.addEventListener('keydown', (e) => {
          if (e.metaKey && e.key === 'Enter') {
            document.title = 'SUBMIT:' + input.value;
          }
        });
      </script>
    </body>
    </html>
  ]])

  -- Monitor title changes
  checkTimer = hs.timer.doEvery(0.1, function()
    local title = inputDialog:title()
    if title and title:match("^SUBMIT:") then
      checkTimer:stop()
      local text = title:gsub("^SUBMIT:", "")
      if text and text ~= "" then
        inputDialog:delete()
        captureInput(function(content)
          saveAndOpenVSCode(content, function()
            runVSCodeChat("ask", text)
          end)
        end)
      end
    elseif title == "CANCEL" then
      checkTimer:stop()
      inputDialog:delete()
    end
  end)

  inputDialog:bringToFront():show()
end)

cerebralM:bind('', 'E', 'Cerebral - Respond Email', function()
  cerebralM:exit()
  captureInput(function(content)
    saveAndOpenVSCode(content, function()
      runVSCodeChat("ask", "EMAIL")
    end)
  end)
end)

cerebralM:bind('', 'M', 'Cerebral - Respond Teams', function()
  cerebralM:exit()
  captureInput(function(content)
    saveAndOpenVSCode(content, function()
      runVSCodeChat("ask", "TEAMS")
    end)
  end)
end)
