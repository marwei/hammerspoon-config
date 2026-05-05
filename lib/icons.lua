-- Icon resolver for cheatsheet UI.
--
-- M.html(spec) returns an HTML fragment for use inside a webview <body>.
-- Specs:
--   "app:<bundleID>"            macOS app icon, base64-encoded PNG
--   "app-pair:<bundleA>,<bundleB>"  two app icons rendered side-by-side
--   "lucide:<name>"             inline Lucide SVG (https://lucide.dev, MIT)
--
-- Lucide path strings are bundled below. Add new icons by copying the inner
-- markup of any Lucide SVG (everything between <svg ...> and </svg>).

local M = {}

local appIconCache = {}

local APP_SEARCH_PATHS = {
  "/Applications/",
  "/Applications/Utilities/",
  "/System/Applications/",
  "/System/Applications/Utilities/",
  (os.getenv("HOME") or "") .. "/Applications/",
}

local function imageToDataUrl(img)
  if not img then return nil end
  img:setSize({w = 64, h = 64})
  return img:encodeAsURLString()
end

local function encodeBundleIcon(bundleID)
  local key = "id:" .. bundleID
  if appIconCache[key] ~= nil then return appIconCache[key] end
  local url = imageToDataUrl(hs.image.imageFromAppBundle(bundleID)) or false
  appIconCache[key] = url
  return url
end

local function findAppPath(name)
  if not hs.fs or not hs.fs.attributes then return nil end
  for _, base in ipairs(APP_SEARCH_PATHS) do
    local path = base .. name .. ".app"
    if hs.fs.attributes(path) then return path end
  end
  return nil
end

local function encodeNameIcon(name)
  local key = "name:" .. name
  if appIconCache[key] ~= nil then return appIconCache[key] end
  local path = findAppPath(name)
  local url = false
  if path then
    url = imageToDataUrl(hs.image.iconForFile(path)) or false
  end
  appIconCache[key] = url
  return url
end

local function fallbackIcon(text)
  local letter = (text or "?"):sub(1, 1):upper()
  return string.format('<span class="icon-fallback">%s</span>', letter)
end

local function appIconImg(bundleID, cls)
  local url = encodeBundleIcon(bundleID)
  if not url then return fallbackIcon(bundleID) end
  return string.format('<img class="%s" src="%s">', cls or "app-icon", url)
end

local function appNameIconImg(name, cls)
  local url = encodeNameIcon(name)
  if not url then return fallbackIcon(name) end
  return string.format('<img class="%s" src="%s">', cls or "app-icon", url)
end

-- Lucide SVG inner contents (24x24 viewBox, stroke-based).
local lucide = {
  ["shield-check"] = '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
  ["brain"] = '<path d="M9.5 2A2.5 2.5 0 0 1 12 4.5v15a2.5 2.5 0 0 1-4.96.44 2.5 2.5 0 0 1-2.96-3.08 3 3 0 0 1-.34-5.58 2.5 2.5 0 0 1 1.32-4.24 2.5 2.5 0 0 1 1.98-3A2.5 2.5 0 0 1 9.5 2Z"/><path d="M14.5 2A2.5 2.5 0 0 0 12 4.5v15a2.5 2.5 0 0 0 4.96.44 2.5 2.5 0 0 0 2.96-3.08 3 3 0 0 0 .34-5.58 2.5 2.5 0 0 0-1.32-4.24 2.5 2.5 0 0 0-1.98-3A2.5 2.5 0 0 0 14.5 2Z"/>',
  ["terminal"] = '<polyline points="4 17 10 11 4 5"/><line x1="12" x2="20" y1="19" y2="19"/>',
  ["globe"] = '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  ["panel-left"] = '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M9 3v18"/>',
  ["panel-right"] = '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M15 3v18"/>',
  ["panel-top"] = '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18"/>',
  ["panel-bottom"] = '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 15h18"/>',
  ["square"] = '<rect width="18" height="18" x="3" y="3" rx="2"/>',
  ["circle-dot"] = '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="1" fill="currentColor"/>',
  ["arrow-up"] = '<path d="m5 12 7-7 7 7"/><path d="M12 19V5"/>',
  ["arrow-down"] = '<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>',
  ["arrow-left"] = '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
  ["arrow-right"] = '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
  ["columns-2"] = '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M12 3v18"/>',
  ["mic"] = '<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" x2="12" y1="19" y2="22"/>',
  ["check-square"] = '<path d="m9 11 3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>',
  ["help-circle"] = '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',
  ["mail"] = '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  ["messages-square"] = '<path d="M14 9a2 2 0 0 1-2 2H6l-4 4V4c0-1.1.9-2 2-2h8a2 2 0 0 1 2 2z"/><path d="M18 9h2a2 2 0 0 1 2 2v11l-4-4h-6a2 2 0 0 1-2-2v-1"/>',
  ["inbox"] = '<polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>',
  ["keyboard"] = '<path d="M10 8h.01"/><path d="M12 12h.01"/><path d="M14 8h.01"/><path d="M16 12h.01"/><path d="M18 8h.01"/><path d="M6 8h.01"/><path d="M7 16h10"/><path d="M8 12h.01"/><rect width="20" height="16" x="2" y="4" rx="2"/>',
  ["app-window"] = '<rect x="2" y="4" width="20" height="16" rx="2"/><path d="M10 4v4"/><path d="M2 8h20"/><path d="M6 4v4"/>',
  ["sparkles"] = '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>',
}

local function lucideSvg(name)
  local body = lucide[name]
  if not body then
    body = lucide["square"]
  end
  return string.format(
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">%s</svg>',
    body
  )
end

function M.html(spec)
  if not spec or spec == "" then
    return lucideSvg("square")
  end
  local kind, rest = spec:match("^([^:]+):(.+)$")
  if kind == "app" then
    return appIconImg(rest, "app-icon")
  elseif kind == "app-name" then
    return appNameIconImg(rest, "app-icon")
  elseif kind == "app-pair" then
    local a, b = rest:match("^([^,]+),([^,]+)$")
    if a and b then
      return string.format(
        '<span class="app-pair">%s%s</span>',
        appIconImg(a, "app-icon-small"),
        appIconImg(b, "app-icon-small")
      )
    end
    return appIconImg(rest, "app-icon")
  elseif kind == "lucide" then
    return lucideSvg(rest)
  end
  return lucideSvg("square")
end

function M.clearCache()
  appIconCache = {}
end

-- Pre-resolve icons for an items array so the first cheatsheet render doesn't
-- pay disk I/O + base64 encoding cost for every app icon at once.
function M.prewarm(items)
  if not items then return end
  for _, it in ipairs(items) do
    if it.icon then M.html(it.icon) end
  end
end

return M
