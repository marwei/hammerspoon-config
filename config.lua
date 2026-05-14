local hostname = hs.host.localizedName()

-- Default application shortcuts (used when hostname has no override)
-- Each entry: {key, app, label (optional, defaults to app)}
-- Optional fields: bringAllWindows, screen ("native"/"external"), resize (direction)
-- For URL-based shortcuts: {key, url, label}
app_shortcuts = {
  {key = 'A', app = 'Activity Monitor'},
  {key = 'space', app = 'Safari', label = 'Browser'},
  {key = 'W', app = 'Microsoft Word'},
  {key = 'return', app = 'Obsidian', label = 'Notes (Obsidian)'},
  {key = 'I', app = 'iTerm', label = 'Terminal (iTerm)',
    bringAllWindows = true, screen = 'native', resize = 'fullscreen_native'},
  {key = 'T', app = 'Slack', label = 'Chat'},
  {key = 'E', app = 'Microsoft Outlook', label = 'Email'},
  {key = 'V', app = 'Visual Studio Code', label = 'VSCode', bundleID = 'com.microsoft.VSCode'},
  {key = 'P', app = 'Photos', bringAllWindows = true},
  {key = 'F', app = 'Finder'},
  {key = 'S', app = 'Slack'},
  {key = 'tab', app = 'Telegram',
    bringAllWindows = true, screen = 'native'},
  {key = 'G', app = 'Granola',
    bringAllWindows = true, screen = 'external', resize = 'quarterright'},
  {key = 'L', app = 'Microsoft Loop'},
  {key = 'C', app = 'Claude'},
}

-- Per-hostname overrides (completely replaces the default table)
local app_shortcuts_by_host = {
  ["Wei's Personal Air"] = {
    {key = 'A', app = 'Activity Monitor'},
    {key = 'space', app = 'Google Chrome', label = 'Browser'},
    {key = 'return', app = 'Obsidian', label = 'Notes (Obsidian)'},
    {key = 'I', app = 'iTerm', label = 'Terminal (iTerm)',
      bringAllWindows = true, screen = 'native', resize = 'fullscreen_native'},
    {key = 'T', app = 'Slack'},
    {key = 'V', app = 'Visual Studio Code', label = 'VSCode', bundleID = 'com.microsoft.VSCode'},
    {key = 'tab', app = 'Telegram',
      bringAllWindows = true, screen = 'native'},
    {key = 'M', app = 'Messages'},
    {key = 'C', app = 'Claude'},
    {key = 'F', app = 'Finder'},
  },
  ["Work Air"] = {
    {key = 'A', app = 'Activity Monitor'},
    {key = 'space', app = 'Microsoft Edge', label = 'Browser'},
    {key = 'W', app = 'Microsoft Word'},
    {key = 'return', app = 'Obsidian', label = 'Notes (Obsidian)'},
    {key = 'I', app = 'iTerm', label = 'Terminal (iTerm)',
      bringAllWindows = true, screen = 'native', resize = 'fullscreen_native'},
    {key = 'T', app = 'Microsoft Teams', label = 'Chat'},
    {key = 'E', app = 'Microsoft Outlook', label = 'Email'},
    {key = 'V', app = 'Visual Studio Code', label = 'VSCode', bundleID = 'com.microsoft.VSCode'},
    {key = 'tab', app = 'Telegram',
      bringAllWindows = true, screen = 'native'},
    {key = 'G', app = 'Granola',
      bringAllWindows = true, screen = 'external', resize = 'quarterright'},
    {key = 'L', app = 'Microsoft Loop'},
    {key = 'C', app = 'Claude'},
    {key = 'F', app = 'Finder'},
  },
}

if app_shortcuts_by_host[hostname] then
  app_shortcuts = app_shortcuts_by_host[hostname]
end

module_list = {
    "modals/window",
    "modals/application",
    "modals/layout",
    "modals/automation",
    "modals/cerebral",
    "modals/kay",  -- Kay work co-pilot
    "widgets/background_jobs",  -- Background jobs framework
}

show_modal = true

-- Background Jobs Framework Configuration
background_jobs = {
  enabled = true,       -- Master enable/disable for all jobs
  debug_mode = true,    -- Verbose logging for all jobs

  jobs = {
    vpn_autoconnect = {
      enabled = true,
      config = {
        url_patterns = {
          "aka%.ms/.*",              -- Microsoft short links
          "eng%.ms.*",               -- Microsoft engineering portal
          ".*%.microsoft%.com",      -- All Microsoft domains
          ".*%.sharepoint%.com",     -- SharePoint
          ".*%.office%.com",         -- Office 365
          "dev%.azure%.com",         -- Azure DevOps
          "portal%.azure%.com",      -- Azure Portal
          ".*%.visualstudio%.com",   -- Visual Studio
        },
        auto_disconnect = false,     -- Auto-disconnect when leaving URLs
        vpn_shortcut_name = "Connect VPN",  -- macOS Shortcut name
      }
    },
  }
}
