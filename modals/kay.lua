-- Kay Work Co-Pilot Modal
-- Hotkey: hyper + K
-- Provides quick access to AI-powered text processing

kayM = hs.hotkey.modal.new()

local kayColor = {red=0.4, green=0.8, blue=0.6}  -- Teal/green for Kay

function kayM:entered()
  toggle_modal_light(kayColor, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function kayM:exited()
  toggle_modal_light(kayColor, 0.7)
  if show_modal == true then toggle_modal_key_display() end
end

kayM:bind('', 'escape', function() kayM:exit() end)

-- Helper: Run Claude CLI and return result
local function runClaude(prompt, callback)
  local alertId = hs.alert.show("🧠 Thinking...", 999999)
  
  -- Escape single quotes in prompt
  local escapedPrompt = prompt:gsub("'", "'\\''")
  
  hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
    hs.alert.closeSpecific(alertId)
    if exitCode == 0 and stdOut and stdOut ~= "" then
      callback(stdOut)
    else
      hs.alert.show("Claude error: " .. (stdErr or "unknown"), 3)
      callback(nil)
    end
  end, {"-c", "claude -p '" .. escapedPrompt .. "'"}):start()
end

-- Helper: Get selected text or clipboard
local function getInputText(callback)
  local originalClipboard = hs.pasteboard.getContents()
  
  -- Try to copy selected text
  hs.eventtap.keyStroke({"cmd"}, "c")
  
  hs.timer.doAfter(0.2, function()
    local selectedText = hs.pasteboard.getContents()
    
    if selectedText and selectedText ~= "" and selectedText ~= originalClipboard then
      -- Got selected text
      callback(selectedText, "selection")
    elseif originalClipboard and originalClipboard ~= "" then
      -- Fall back to clipboard
      callback(originalClipboard, "clipboard")
    else
      callback(nil, nil)
    end
  end)
end

-- Helper: Show result in overlay with copy button
local function showResult(result, title)
  local screen = hs.mouse.getCurrentScreen()
  local frame = screen:frame()
  local width = 600
  local height = 400
  local x = frame.x + (frame.w - width) / 2
  local y = frame.y + (frame.h - height) / 2
  
  local resultView = hs.webview.new({x=x, y=y, w=width, h=height})
  resultView:windowStyle({"titled", "closable", "resizable"})
  resultView:closeOnEscape(true)
  resultView:allowTextEntry(true)
  
  -- Escape HTML
  local escapedResult = result:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\n", "<br>")
  
  local checkTimer = nil
  
  resultView:html(string.format([[
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          margin: 0;
          padding: 20px;
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          background: linear-gradient(135deg, rgba(64, 204, 153, 0.1) 0%%, rgba(255, 255, 255, 0.95) 100%%);
          height: 100vh;
          box-sizing: border-box;
          display: flex;
          flex-direction: column;
        }
        h2 {
          color: #2d3748;
          margin: 0 0 15px 0;
          font-size: 18px;
          font-weight: 600;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        h2::before {
          content: '⚡';
        }
        .content {
          flex: 1;
          overflow-y: auto;
          padding: 15px;
          background: white;
          border-radius: 12px;
          border: 1px solid rgba(0,0,0,0.1);
          font-size: 14px;
          line-height: 1.6;
          color: #2d3748;
          box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .buttons {
          margin-top: 15px;
          display: flex;
          gap: 10px;
          justify-content: flex-end;
        }
        button {
          padding: 10px 20px;
          font-size: 14px;
          border: none;
          border-radius: 8px;
          cursor: pointer;
          font-weight: 500;
          transition: all 0.15s ease;
        }
        #copy {
          background: #40cc99;
          color: white;
        }
        #copy:hover {
          background: #36b085;
          transform: translateY(-1px);
        }
        #close {
          background: #e2e8f0;
          color: #4a5568;
        }
        #close:hover {
          background: #cbd5e0;
        }
        #paste {
          background: #4299e1;
          color: white;
        }
        #paste:hover {
          background: #3182ce;
          transform: translateY(-1px);
        }
      </style>
    </head>
    <body>
      <h2>%s</h2>
      <div class="content" id="result">%s</div>
      <div class="buttons">
        <button id="close" onclick="document.title='CLOSE'">Close</button>
        <button id="copy" onclick="copyResult()">Copy</button>
        <button id="paste" onclick="document.title='PASTE'">Paste</button>
      </div>
      <script>
        const resultText = %q;
        function copyResult() {
          navigator.clipboard.writeText(resultText).then(() => {
            document.getElementById('copy').textContent = 'Copied!';
            setTimeout(() => {
              document.getElementById('copy').textContent = 'Copy';
            }, 1500);
          });
        }
      </script>
    </body>
    </html>
  ]], title, escapedResult, result))
  
  checkTimer = hs.timer.doEvery(0.1, function()
    local title = resultView:title()
    if title == "CLOSE" then
      checkTimer:stop()
      resultView:delete()
    elseif title == "PASTE" then
      checkTimer:stop()
      hs.pasteboard.setContents(result)
      resultView:delete()
      -- Paste into active app
      hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({"cmd"}, "v")
      end)
    end
  end)
  
  resultView:bringToFront():show()
end

-- Helper: Show text input dialog
local function showInputDialog(title, placeholder, prefill, callback)
  local screen = hs.mouse.getCurrentScreen()
  local frame = screen:frame()
  local width = 600
  local height = 300
  local x = frame.x + (frame.w - width) / 2
  local y = frame.y + (frame.h - height) / 2
  
  local inputDialog = hs.webview.new({x=x, y=y, w=width, h=height})
  inputDialog:windowStyle({"titled", "closable"})
  inputDialog:closeOnEscape(true)
  inputDialog:allowTextEntry(true)
  
  local checkTimer = nil
  local escapedPrefill = (prefill or ""):gsub("\\", "\\\\"):gsub("`", "\\`"):gsub("$", "\\$")
  
  inputDialog:html(string.format([[
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {
          margin: 0;
          padding: 20px;
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          background: linear-gradient(135deg, rgba(64, 204, 153, 0.1) 0%%, rgba(255, 255, 255, 0.95) 100%%);
          height: 100vh;
          box-sizing: border-box;
          display: flex;
          flex-direction: column;
        }
        h2 {
          color: #2d3748;
          margin: 0 0 15px 0;
          font-size: 18px;
          font-weight: 600;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        h2::before {
          content: '⚡';
        }
        .textarea-container {
          flex: 1;
        }
        textarea {
          width: 100%%;
          height: 100%%;
          padding: 15px;
          font-size: 14px;
          border: 1px solid rgba(0,0,0,0.1);
          border-radius: 12px;
          resize: none;
          font-family: -apple-system, BlinkMacSystemFont, sans-serif;
          background: white;
          box-sizing: border-box;
          color: #2d3748;
          box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        textarea:focus {
          outline: none;
          border-color: #40cc99;
          box-shadow: 0 0 0 3px rgba(64, 204, 153, 0.2);
        }
        textarea::placeholder {
          color: #a0aec0;
        }
        .buttons {
          margin-top: 15px;
          display: flex;
          gap: 10px;
          justify-content: flex-end;
        }
        button {
          padding: 10px 20px;
          font-size: 14px;
          border: none;
          border-radius: 8px;
          cursor: pointer;
          font-weight: 500;
          transition: all 0.15s ease;
        }
        #submit {
          background: #40cc99;
          color: white;
        }
        #submit:hover {
          background: #36b085;
          transform: translateY(-1px);
        }
        #cancel {
          background: #e2e8f0;
          color: #4a5568;
        }
        #cancel:hover {
          background: #cbd5e0;
        }
        .hint {
          font-size: 11px;
          color: #a0aec0;
          margin-top: 8px;
        }
      </style>
    </head>
    <body>
      <h2>%s</h2>
      <div class="textarea-container">
        <textarea id="input" placeholder="%s" autofocus>%s</textarea>
      </div>
      <div class="hint">⌘+Enter to submit</div>
      <div class="buttons">
        <button id="cancel" onclick="document.title='CANCEL'">Cancel</button>
        <button id="submit" onclick="document.title='SUBMIT:' + document.getElementById('input').value">Submit</button>
      </div>
      <script>
        const input = document.getElementById('input');
        window.onload = () => input.focus();
        setTimeout(() => input.focus(), 50);
        input.addEventListener('keydown', (e) => {
          if (e.metaKey && e.key === 'Enter') {
            document.title = 'SUBMIT:' + input.value;
          }
        });
      </script>
    </body>
    </html>
  ]], title, placeholder, escapedPrefill))
  
  checkTimer = hs.timer.doEvery(0.1, function()
    local title = inputDialog:title()
    if title and title:match("^SUBMIT:") then
      checkTimer:stop()
      local text = title:gsub("^SUBMIT:", "")
      inputDialog:delete()
      callback(text)
    elseif title == "CANCEL" then
      checkTimer:stop()
      inputDialog:delete()
      callback(nil)
    end
  end)
  
  inputDialog:bringToFront():show()
  hs.timer.doAfter(0.1, function()
    inputDialog:hswindow():focus()
  end)
end

-- ============================================
-- Kay Commands
-- ============================================

-- D: Draft - Polish/rewrite text
kayM:bind('', 'D', 'Kay - Draft/Polish', function()
  kayM:exit()
  
  getInputText(function(text, source)
    if not text then
      hs.alert.show("No text selected or in clipboard")
      return
    end
    
    showInputDialog(
      "Kay - Draft",
      "Instructions (e.g., 'make it more professional', 'shorter', 'friendlier')...",
      "",
      function(instructions)
        if not instructions then return end
        
        local prompt = string.format(
          "Rewrite/polish this text. %s\n\nTEXT:\n%s\n\nOutput ONLY the rewritten text, no explanation.",
          instructions ~= "" and ("Instructions: " .. instructions) or "Make it clear and professional.",
          text
        )
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Polished Text")
          end
        end)
      end
    )
  end)
end)

-- E: Email - Draft email response
kayM:bind('', 'E', 'Kay - Email Response', function()
  kayM:exit()
  
  getInputText(function(text, source)
    if not text then
      hs.alert.show("No email selected or in clipboard")
      return
    end
    
    showInputDialog(
      "Kay - Email Response",
      "What should the response say? (key points, tone, etc.)",
      "",
      function(instructions)
        if not instructions then return end
        
        local prompt = string.format([[
Draft a professional email response to this email.

ORIGINAL EMAIL:
%s

RESPONSE SHOULD:
%s

Write ONLY the email response (no subject line, just the body). Keep it concise and professional.
]], text, instructions)
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Email Response")
          end
        end)
      end
    )
  end)
end)

-- S: Slack - Draft Slack message
kayM:bind('', 'S', 'Kay - Slack Message', function()
  kayM:exit()
  
  getInputText(function(text, source)
    showInputDialog(
      "Kay - Slack Message",
      "What do you want to say? (context from clipboard/selection will be used)",
      "",
      function(instructions)
        if not instructions then return end
        
        local prompt
        if text and text ~= "" then
          prompt = string.format([[
Draft a Slack message based on this context:

CONTEXT:
%s

MESSAGE SHOULD:
%s

Write ONLY the Slack message. Keep it conversational but professional. Use appropriate emoji sparingly.
]], text, instructions)
        else
          prompt = string.format([[
Draft a Slack message:

%s

Write ONLY the Slack message. Keep it conversational but professional. Use appropriate emoji sparingly.
]], instructions)
        end
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Slack Message")
          end
        end)
      end
    )
  end)
end)

-- A: Ask - General question
kayM:bind('', 'A', 'Kay - Ask', function()
  kayM:exit()
  
  getInputText(function(text, source)
    showInputDialog(
      "Kay - Ask",
      "Ask anything...",
      "",
      function(question)
        if not question or question == "" then return end
        
        local prompt
        if text and text ~= "" then
          prompt = string.format("Context:\n%s\n\nQuestion: %s", text, question)
        else
          prompt = question
        end
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Answer")
          end
        end)
      end
    )
  end)
end)

-- X: Explain - Explain selected text/code
kayM:bind('', 'X', 'Kay - Explain', function()
  kayM:exit()
  
  getInputText(function(text, source)
    if not text then
      hs.alert.show("No text selected or in clipboard")
      return
    end
    
    local prompt = string.format([[
Explain this clearly and concisely:

%s

Provide a clear explanation suitable for someone who needs to understand this quickly.
]], text)
    
    runClaude(prompt, function(result)
      if result then
        showResult(result, "Explanation")
      end
    end)
  end)
end)

-- T: Translate - Translate text
kayM:bind('', 'T', 'Kay - Translate', function()
  kayM:exit()
  
  getInputText(function(text, source)
    if not text then
      hs.alert.show("No text selected or in clipboard")
      return
    end
    
    showInputDialog(
      "Kay - Translate",
      "Target language (e.g., 'Spanish', 'French', 'Mandarin')...",
      "English",
      function(targetLang)
        if not targetLang or targetLang == "" then return end
        
        local prompt = string.format([[
Translate this text to %s:

%s

Output ONLY the translation, nothing else.
]], targetLang, text)
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Translation (" .. targetLang .. ")")
          end
        end)
      end
    )
  end)
end)

-- F: Fix - Fix grammar/spelling
kayM:bind('', 'F', 'Kay - Fix Grammar', function()
  kayM:exit()
  
  getInputText(function(text, source)
    if not text then
      hs.alert.show("No text selected or in clipboard")
      return
    end
    
    local prompt = string.format([[
Fix any grammar, spelling, or punctuation errors in this text. Preserve the original meaning and tone.

TEXT:
%s

Output ONLY the corrected text, nothing else.
]], text)
    
    runClaude(prompt, function(result)
      if result then
        showResult(result, "Fixed Text")
      end
    end)
  end)
end)

-- Q: Quick - Quick action with custom prompt
kayM:bind('', 'Q', 'Kay - Quick Action', function()
  kayM:exit()
  
  getInputText(function(text, source)
    showInputDialog(
      "Kay - Quick Action",
      "What do you want to do with this text?",
      "",
      function(action)
        if not action or action == "" then return end
        
        local prompt
        if text and text ~= "" then
          prompt = string.format("%s\n\nTEXT:\n%s", action, text)
        else
          prompt = action
        end
        
        runClaude(prompt, function(result)
          if result then
            showResult(result, "Result")
          end
        end)
      end
    )
  end)
end)
