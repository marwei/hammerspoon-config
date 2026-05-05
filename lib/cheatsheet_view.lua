-- Liquid-glass cheatsheet renderer.
-- Renders modal hotkey cheatsheets via hs.webview with CSS backdrop-filter.

local icons = require('lib/icons')

local M = {}

local view = nil
local visible = false
local pollTimer = nil
local lastSignature = nil

local function ensureView(rect)
  if view then
    view:frame(rect)
    return
  end
  view = hs.webview.new(rect, {developerExtrasEnabled = false})
  view:windowStyle({"borderless"})
  view:transparent(true)
  view:allowTextEntry(false)
  view:level(hs.canvas.windowLevels.modalPanel)
  view:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces +
                hs.canvas.windowBehaviors.stationary)
end

local function itemsSignature(modalName, items, opts)
  local parts = {modalName or "", opts and opts.closeOnClick and "1" or "0"}
  for _, it in ipairs(items) do
    parts[#parts + 1] = (it.key or "") .. "|" .. (it.label or "") .. "|" ..
                       (it.icon or "") .. "|" .. (it.mod or "")
  end
  return table.concat(parts, "\n")
end

local function escapeHtml(s)
  if not s then return "" end
  s = tostring(s)
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  s = s:gsub("'", "&#39;")
  return s
end

local function keyDisplay(key)
  -- Pretty-print special keys
  local map = {
    space = "␣",
    ["return"] = "⏎",
    tab = "⇥",
    escape = "esc",
    up = "↑",
    down = "↓",
    left = "←",
    right = "→",
  }
  local lower = key and key:lower() or ""
  if map[lower] then return map[lower] end
  if #key == 1 then return key:upper() end
  return key
end

local CSS = [[
  :root { color-scheme: light; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { width: 100%; height: 100%; background: transparent; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif;
    color: #1d1d1f;
    padding: 36px;
    background: transparent;
    user-select: none;
  }
  .panel {
    position: relative;
    width: 100%;
    height: 100%;
    padding: 22px 24px 16px;
    background:
      linear-gradient(180deg, rgba(255,255,255,0.35), rgba(255,255,255,0.18)),
      rgba(225, 228, 234, 0.94);
    border: 1px solid rgba(255, 255, 255, 0.55);
    border-radius: 22px;
    box-shadow:
      0 16px 48px rgba(0, 0, 0, 0.30),
      0 4px 12px rgba(0, 0, 0, 0.16),
      inset 0 1px 0 rgba(255, 255, 255, 0.75);
  }
  body.clickable { cursor: pointer; }

  .header { margin-bottom: 14px; }
  .title {
    font-size: 17px;
    font-weight: 600;
    letter-spacing: -0.2px;
    color: #1d1d1f;
  }
  .subtitle {
    font-size: 12px;
    color: rgba(0, 0, 0, 0.5);
    margin-top: 2px;
  }
  .rows {
    display: grid;
    grid-template-columns: 1fr 1fr;
    column-gap: 10px;
    row-gap: 4px;
  }
  .row {
    display: grid;
    grid-template-columns: 36px 1fr 56px;
    align-items: center;
    gap: 12px;
    height: 46px;
    padding: 0 10px;
    border-radius: 12px;
    background: rgba(255, 255, 255, 0.45);
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.55);
  }
  .icon-cell {
    width: 32px;
    height: 32px;
    border-radius: 9px;
    background: linear-gradient(180deg, rgba(255, 255, 255, 0.55), rgba(255, 255, 255, 0.18));
    border: 1px solid rgba(255, 255, 255, 0.7);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #1d1d1f;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.6);
    overflow: hidden;
  }
  .icon-cell svg { width: 18px; height: 18px; }
  .icon-cell img.app-icon { width: 28px; height: 28px; border-radius: 6px; }
  .icon-cell .app-pair {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: -6px;
    position: relative;
    width: 32px;
    height: 32px;
  }
  .icon-cell .app-icon-small {
    width: 22px;
    height: 22px;
    border-radius: 5px;
    border: 1.5px solid rgba(255, 255, 255, 0.85);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
    position: absolute;
  }
  .icon-cell .app-pair .app-icon-small:first-child {
    transform: translateX(-6px) translateY(-2px) rotate(-6deg);
  }
  .icon-cell .app-pair .app-icon-small:last-child {
    transform: translateX(6px) translateY(2px) rotate(6deg);
  }
  .icon-fallback {
    font-size: 13px;
    font-weight: 600;
    color: rgba(0, 0, 0, 0.55);
  }
  .key {
    font-family: "SF Mono", Menlo, monospace;
    font-size: 13px;
    font-weight: 600;
    padding: 4px 10px;
    border-radius: 8px;
    background: rgba(0, 102, 255, 0.13);
    border: 1px solid rgba(0, 102, 255, 0.32);
    color: #0066CC;
    text-align: center;
    width: fit-content;
    min-width: 28px;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.6);
  }
  .key.key-mod {
    background: rgba(120, 70, 200, 0.13);
    border-color: rgba(120, 70, 200, 0.32);
    color: #6B3FB7;
  }
  .label {
    font-size: 14px;
    color: #1d1d1f;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .footer {
    text-align: center;
    font-size: 11px;
    color: rgba(0, 0, 0, 0.45);
    margin-top: 14px;
    padding-top: 12px;
    border-top: 1px solid rgba(0, 0, 0, 0.06);
  }
]]

local function buildHtml(modalName, items, opts)
  opts = opts or {}
  local rowsHtml = {}
  for _, it in ipairs(items) do
    local iconHtml = icons.html(it.icon or "")
    local keyClass = "key"
    if it.mod then keyClass = "key key-mod" end
    local keyHtml = (it.mod and (it.mod .. " ") or "") .. escapeHtml(keyDisplay(it.key))
    local labelHtml = escapeHtml(it.label or "")
    table.insert(rowsHtml, string.format(
      '<div class="row"><div class="icon-cell">%s</div><div class="label">%s</div><div class="%s">%s</div></div>',
      iconHtml, labelHtml, keyClass, keyHtml
    ))
  end

  local title = escapeHtml(modalName or "Keyboard Shortcuts")
  local subtitle = modalName and "Keyboard Shortcuts" or "Press a key, ESC to close"
  local bodyAttrs = opts.closeOnClick
    and ' class="clickable" onclick="document.title=\'CLOSE\'"'
    or ""
  local footerText = opts.closeOnClick
    and "Click anywhere or press ESC to close"
    or "Press a key, or ESC to close"

  return string.format([[
    <!DOCTYPE html>
    <html><head><meta charset="utf-8"><style>%s</style></head>
    <body%s>
      <div class="panel">
        <div class="header">
          <div class="title">%s</div>
          <div class="subtitle">%s</div>
        </div>
        <div class="rows">%s</div>
        <div class="footer">%s</div>
      </div>
    </body></html>
  ]], CSS, bodyAttrs, title, escapeHtml(subtitle), table.concat(rowsHtml, ""), escapeHtml(footerText))
end

local SURROUND = 36

local function computeFrame(itemCount)
  local mainScreen = hs.screen.mainScreen()
  local fullFrame = mainScreen:fullFrame()
  local localFrame = mainScreen:absoluteToLocal(fullFrame)

  local panelWidth = math.min(localFrame.w * 0.7, 880)
  local rows = math.ceil(itemCount / 2)
  local rowsHeight = rows * 50
  local panelHeight = 22 + 44 + rowsHeight + 14 + 28 + 16
  panelHeight = math.min(panelHeight, localFrame.h * 0.85 - SURROUND * 2)

  local width = panelWidth + SURROUND * 2
  local height = panelHeight + SURROUND * 2

  local x = (localFrame.w - width) / 2
  local y = (localFrame.h - height) / 2
  return mainScreen:localToAbsolute({x = x, y = y, w = width, h = height})
end

function M.show(modalName, items, opts)
  opts = opts or {}

  local rect = computeFrame(#items)
  ensureView(rect)

  local sig = itemsSignature(modalName, items, opts)
  if sig ~= lastSignature then
    view:html(buildHtml(modalName, items, opts))
    lastSignature = sig
  end
  view:show()
  visible = true

  if pollTimer then pollTimer:stop(); pollTimer = nil end
  if opts.closeOnClick then
    pollTimer = hs.timer.doEvery(0.1, function()
      if not view or not visible then
        if pollTimer then pollTimer:stop(); pollTimer = nil end
        return
      end
      local title = view:title()
      if title == "CLOSE" then
        M.hide()
        if opts.onClose then opts.onClose() end
      end
    end)
  end
end

function M.hide()
  if pollTimer then
    pollTimer:stop()
    pollTimer = nil
  end
  if view then
    view:hide()
  end
  visible = false
end

function M.isVisible()
  return visible
end

function M.clearIconCache()
  icons.clearCache()
  lastSignature = nil
end

function M.destroy()
  if pollTimer then pollTimer:stop(); pollTimer = nil end
  if view then
    view:delete()
    view = nil
  end
  visible = false
  lastSignature = nil
end

-- Pre-warm WebKit content process so the first show after idle isn't slow.
-- Creates a hidden, off-screen webview at startup so WebKit's helper processes
-- stay resident.
function M.prewarm()
  if view then return end
  ensureView({x = -10000, y = -10000, w = 100, h = 100})
  view:html("<html><body></body></html>")
end

return M
