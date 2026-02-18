-- VPN Auto-Connect Job
-- Monitors browser URLs and triggers Azure VPN when matched patterns detected

local utils = _G.background_jobs_utils

-- Job state
local state = {
  vpn_connected = false,
  last_checked_url = "",
  last_trigger_time = 0,
  url_patterns = {},
  vpn_shortcut_name = "Connect Azure VPN",
  auto_disconnect = false,
  debounce_seconds = 5,
}

-- Browser list for URL monitoring
local browsers = {
  "Safari",
  "Google Chrome",
  "Microsoft Edge",
  "Arc",
  "Brave Browser",
  "Firefox",
}

local function isBrowser(appName)
  for _, browser in ipairs(browsers) do
    if appName == browser then
      return true
    end
  end
  return false
end

local function getVPNStatus()
  -- Check eng.ms/favicon.ico - returns 403 when VPN disconnected, anything else means connected
  local output, status = hs.execute("curl -s -o /dev/null -w '%{http_code}' --max-time 2 https://eng.ms/favicon.ico")
  local httpCode = output and output:match("%d+")

  if httpCode == "403" then
    utils.debugLog("VPN Auto-Connect", "VPN disconnected (eng.ms returned 403)")
    return "disconnected"
  else
    utils.debugLog("VPN Auto-Connect", "VPN connected (eng.ms returned " .. (httpCode or "error") .. ")")
    return "connected"
  end
end

local function connectVPN()
  -- Check if already connected
  local status = getVPNStatus()
  if status == "connected" then
    utils.debugLog("VPN Auto-Connect", "VPN already connected, skipping")
    state.vpn_connected = true
    return
  end

  -- Debounce rapid triggers
  local now = os.time()
  if now - state.last_trigger_time < state.debounce_seconds then
    utils.debugLog("VPN Auto-Connect", "Debouncing VPN trigger")
    return
  end
  state.last_trigger_time = now

  -- Capture the browser that triggered this before connecting
  local triggeringApp = hs.application.frontmostApplication()

  utils.debugLog("VPN Auto-Connect", "Triggering VPN connection")
  hs.alert.show("connecting vpn")

  -- Use macOS Shortcut (following automation.lua pattern)
  hs.task.new("/usr/bin/shortcuts", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      state.vpn_connected = true
      utils.showNotification("VPN Auto-Connect", "Azure VPN connected successfully")
      utils.debugLog("VPN Auto-Connect", "VPN connected successfully")

      -- Refresh the browser after VPN connects
      hs.timer.doAfter(2, function()
        if triggeringApp and triggeringApp:isRunning() then
          utils.debugLog("VPN Auto-Connect", "Refreshing browser: " .. triggeringApp:name())
          triggeringApp:activate()
          hs.timer.doAfter(0.3, function()
            hs.eventtap.keyStroke({"cmd"}, "r")
          end)
        end
      end)
    else
      utils.showNotification("VPN Auto-Connect", "Failed to connect VPN: " .. (stdErr or "unknown error"))
      print("[VPN Auto-Connect] ERROR: VPN connection failed: " .. (stdErr or "unknown error"))
    end
  end, {"run", state.vpn_shortcut_name}):start()
end

local function disconnectVPN()
  if not state.auto_disconnect then
    return
  end

  local status = getVPNStatus()
  if status ~= "connected" then
    state.vpn_connected = false
    return
  end

  utils.debugLog("VPN Auto-Connect", "Disconnecting VPN")
  -- Note: Implement VPN disconnect logic if auto_disconnect is enabled
  -- This may require a separate macOS Shortcut for disconnection
end

local function checkCurrentURL()
  local focusedApp = hs.application.frontmostApplication()
  if not focusedApp then return end

  local appName = focusedApp:name()
  if not isBrowser(appName) then
    utils.debugLog("VPN Auto-Connect", "Focused app is not a browser: " .. appName)
    return
  end

  -- Get URL from browser
  local url = utils.getBrowserURL(appName)
  if not url then
    utils.debugLog("VPN Auto-Connect", "Failed to get URL from " .. appName)
    return
  end

  -- Skip if URL hasn't changed
  if url == state.last_checked_url then
    return
  end
  state.last_checked_url = url

  utils.debugLog("VPN Auto-Connect", "Checking URL: " .. url)

  -- Check if URL matches any pattern
  local matches, pattern = utils.matchPattern(url, state.url_patterns)
  if matches then
    utils.debugLog("VPN Auto-Connect", "URL matched pattern: " .. pattern)
    connectVPN()
  else
    utils.debugLog("VPN Auto-Connect", "URL did not match any patterns")
  end

  -- Update VPN status
  local status = getVPNStatus()
  state.vpn_connected = (status == "connected")
end

-- Job Interface Implementation

local job = {}

job.name = "VPN Auto-Connect"
job.version = "1.0"

job.init = function(config)
  utils.debugLog("VPN Auto-Connect", "Initializing job with config")

  -- Load configuration
  state.url_patterns = config.url_patterns or {}
  state.auto_disconnect = config.auto_disconnect or false
  state.vpn_shortcut_name = config.vpn_shortcut_name or "Connect Azure VPN"

  if #state.url_patterns == 0 then
    print("[VPN Auto-Connect] WARNING: No URL patterns configured")
  end

  utils.debugLog("VPN Auto-Connect", "Loaded " .. #state.url_patterns .. " URL patterns")
  utils.debugLog("VPN Auto-Connect", "Auto-disconnect: " .. tostring(state.auto_disconnect))
  utils.debugLog("VPN Auto-Connect", "Shortcut name: " .. state.vpn_shortcut_name)

  return true
end

job.start = function()
  utils.debugLog("VPN Auto-Connect", "Starting job")

  -- Initial VPN status check
  local status = getVPNStatus()
  state.vpn_connected = (status == "connected")
  utils.debugLog("VPN Auto-Connect", "Initial VPN status: " .. status)

  return true
end

job.stop = function()
  utils.debugLog("VPN Auto-Connect", "Stopping job")
  return true
end

job.onWindowFocused = function(window, appName)
  -- Only trigger for Microsoft Edge
  if appName ~= "Microsoft Edge" then
    return
  end

  utils.debugLog("VPN Auto-Connect", "Edge activated, checking VPN status")
  connectVPN()
end

return job
