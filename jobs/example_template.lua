-- Example Job Template
-- Copy this file and rename to create your own background job
-- See jobs/README.md for detailed documentation

local utils = _G.background_jobs_utils

-- Job state (local to this module)
local state = {
  -- Add your state variables here
  example_value = nil,
  counter = 0,
}

-- Job module
local job = {}

job.name = "Example Job"
job.version = "1.0"

-- Required: Initialize job with configuration
job.init = function(config)
  utils.debugLog("Example Job", "Initializing with config")

  -- Access config values from background_jobs.jobs.example_job.config
  -- Example: state.example_value = config.my_setting

  -- Return false to prevent job from starting
  return true
end

-- Optional: Start job (called after successful init)
job.start = function()
  utils.debugLog("Example Job", "Starting job")
  return true
end

-- Optional: Stop job (cleanup)
job.stop = function()
  utils.debugLog("Example Job", "Stopping job")
  return true
end

-- Optional: Called when window focus changes
job.onWindowFocused = function(window, appName)
  utils.debugLog("Example Job", "Window focused: " .. appName)

  -- Example: Get browser URL
  local url = utils.getBrowserURL(appName)
  if url then
    utils.debugLog("Example Job", "Current URL: " .. url)
  end
end

-- Optional: Called at polling interval (configured in config.lua)
job.onTimerTick = function(interval)
  utils.debugLog("Example Job", "Timer tick (interval: " .. interval .. "s)")

  -- Example: Periodic check
  state.counter = state.counter + 1
  if state.counter >= 10 then
    utils.showNotification("Example Job", "Counter reached 10!")
    state.counter = 0
  end
end

-- Optional: Called when application launches
job.onAppLaunched = function(appName)
  utils.debugLog("Example Job", "App launched: " .. appName)

  -- Example: Respond to specific app launch
  if appName == "Slack" then
    utils.showNotification("Example Job", "Slack launched!")
  end
end

-- Optional: Called when application terminates
job.onAppTerminated = function(appName)
  utils.debugLog("Example Job", "App terminated: " .. appName)
end

return job
