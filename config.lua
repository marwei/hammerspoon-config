-- Application modal shortcuts reference (actual bindings in modals/application.lua)
-- A     → Activity Monitor
-- E     → Email (Outlook/Gmail)
-- F     → Autodesk Fusion
-- G     → Granola (conditional)
-- I     → Terminal (iTerm)
-- L     → Microsoft Loop (conditional)
-- P     → Photos
-- S     → Slack
-- T     → Microsoft Teams
-- V     → VSCode
-- W     → Microsoft Word
-- tab   → Notes (Obsidian)
-- space → Browser (Default)
-- return→ Telegram

module_list = {
    "modals/window",
    "modals/application",
    "modals/layout",
    "modals/automation",
    "modals/cerebral",
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
