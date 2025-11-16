cerebralM = hs.hotkey.modal.new()

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

-- Helper function to capture text input (selection, screenshot OCR, or clipboard)
local function captureInput(callback)
  -- Store original clipboard content
  local originalClipboard = hs.pasteboard.getContents()

  -- Try to copy selected text
  hs.eventtap.keyStroke({"cmd"}, "c")

  hs.timer.doAfter(0.2, function()
    local selectedText = hs.pasteboard.getContents()

    -- Check if we got new content (different from original)
    if selectedText and selectedText ~= "" and selectedText ~= originalClipboard then
      callback(selectedText)
    else
      -- No selection, try screenshot with OCR
      hs.alert.show("No selection - taking screenshot")

      -- Use screencapture for interactive screenshot
      local tempImagePath = os.tmpname() .. ".png"
      local screencaptureTask = hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          -- Screenshot taken, now run OCR using shortcuts
          hs.task.new("/usr/bin/shortcuts", function(ocrExitCode, ocrStdOut, ocrStdErr)
            if ocrExitCode == 0 and ocrStdOut and ocrStdOut ~= "" then
              -- Got OCR text
              callback(ocrStdOut)
            else
              -- OCR failed or empty, fall back to original clipboard
              hs.alert.show("No text in screenshot - using clipboard")
              if originalClipboard and originalClipboard ~= "" then
                callback(originalClipboard)
              else
                hs.alert.show("No content available")
                callback("")
              end
            end
            -- Clean up temp file
            os.remove(tempImagePath)
          end, {"run", "Extract Text from Image", "-i", tempImagePath}):start()
        else
          -- Screenshot cancelled or failed, use clipboard
          if originalClipboard and originalClipboard ~= "" then
            callback(originalClipboard)
          else
            callback("")
          end
        end
      end, {"-i", "-s", tempImagePath}):start()
    end
  end)
end

-- Helper function for Record: selected text > recent clipboard > screenshot
local function captureInputForRecord(callback)
  local originalClipboard = hs.pasteboard.getContents()

  -- Try to copy selected text
  hs.eventtap.keyStroke({"cmd"}, "c")

  hs.timer.doAfter(0.2, function()
    local selectedText = hs.pasteboard.getContents()

    -- Check if we got new selected text
    if selectedText and selectedText ~= "" and selectedText ~= originalClipboard then
      callback(selectedText)
      return
    end

    -- No selection, check clipboard age
    local clipboardAge = hs.timer.secondsSinceEpoch() - lastClipboardChange
    local maxAge = 10 * 60  -- 10 minutes in seconds

    if originalClipboard and originalClipboard ~= "" and clipboardAge < maxAge then
      -- Clipboard is recent, use it
      hs.alert.show("Using clipboard content")
      callback(originalClipboard)
    else
      -- Clipboard is old or empty, take screenshot
      hs.alert.show("Clipboard too old - taking screenshot")

      local tempImagePath = os.tmpname() .. ".png"
      hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          -- Screenshot taken, now run OCR
          hs.task.new("/usr/bin/shortcuts", function(ocrExitCode, ocrStdOut, ocrStdErr)
            if ocrExitCode == 0 and ocrStdOut and ocrStdOut ~= "" then
              callback(ocrStdOut)
            else
              hs.alert.show("No text in screenshot")
              callback(originalClipboard or "")
            end
            os.remove(tempImagePath)
          end, {"run", "Extract Text from Image", "-i", tempImagePath}):start()
        else
          -- Screenshot cancelled
          callback(originalClipboard or "")
        end
      end, {"-i", "-s", tempImagePath}):start()
    end
  end)
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
