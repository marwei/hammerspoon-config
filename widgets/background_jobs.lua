-- Background Jobs Framework
-- Manages automated workflow jobs with shared event infrastructure

-- Global state
background_jobs_state = background_jobs_state or {
  jobs = {},
  job_instances = {},
  enabled = false,
  debug_mode = false,
}

-- Shared event sources (single instances for all jobs)
local window_filter = nil
local polling_timer = nil
local app_watcher = nil

-- Utility Functions

local function debugLog(jobName, message)
  if background_jobs_state.debug_mode then
    local prefix = jobName and ("[" .. jobName .. "] ") or "[Framework] "
    print(prefix .. message)
  end
end

local function showNotification(title, message, duration)
  hs.notify.new(function() end, {
    title = title,
    informativeText = message,
    withdrawAfter = duration or 3,
    hasActionButton = false,
  }):send()
end

local function matchPattern(text, patterns)
  if not text or not patterns then return false end

  for _, pattern in ipairs(patterns) do
    local match = string.match(text, pattern)
    if match then
      return true, pattern
    end
  end

  return false
end

local function getBrowserURL(appName)
  -- AppleScript templates for different browsers
  local browsers = {
    ["Safari"] = 'tell application "Safari" to return URL of front document',
    ["Google Chrome"] = 'tell application "Google Chrome" to return URL of active tab of front window',
    ["Microsoft Edge"] = 'tell application "Microsoft Edge" to return URL of active tab of front window',
    ["Arc"] = 'tell application "Arc" to return URL of active tab of front window',
    ["Brave Browser"] = 'tell application "Brave Browser" to return URL of active tab of front window',
  }

  local script = browsers[appName]
  if not script then
    debugLog(nil, "No AppleScript template for browser: " .. appName)
    return nil
  end

  -- Use pcall for error protection
  local success, ok, result = pcall(function()
    return hs.osascript.applescript(script)
  end)

  if success and ok and result then
    return result
  else
    debugLog(nil, "Failed to get URL from " .. appName .. ": " .. tostring(result))
    return nil
  end
end

-- Export utility functions for jobs to use
_G.background_jobs_utils = {
  debugLog = debugLog,
  showNotification = showNotification,
  matchPattern = matchPattern,
  getBrowserURL = getBrowserURL,
}

-- Job Management Functions

local function loadJob(jobName, jobConfig)
  debugLog(nil, "Loading job: " .. jobName)

  -- Load job module from jobs/ directory
  local jobPath = "jobs." .. jobName
  local success, jobModule = pcall(require, jobPath)

  if not success then
    print("[Framework] ERROR: Failed to load job '" .. jobName .. "': " .. tostring(jobModule))
    return false
  end

  if type(jobModule) ~= "table" then
    print("[Framework] ERROR: Job '" .. jobName .. "' did not return a table")
    return false
  end

  -- Validate required functions
  if not jobModule.init or type(jobModule.init) ~= "function" then
    print("[Framework] ERROR: Job '" .. jobName .. "' missing init() function")
    return false
  end

  -- Store job module
  background_jobs_state.jobs[jobName] = jobModule
  background_jobs_state.job_instances[jobName] = {
    config = jobConfig,
    state = {},
    module = jobModule,
  }

  debugLog(nil, "Job loaded: " .. (jobModule.name or jobName))
  return true
end

local function initializeJob(jobName)
  local instance = background_jobs_state.job_instances[jobName]
  if not instance then return false end

  debugLog(jobName, "Initializing job")

  local success, result = pcall(instance.module.init, instance.config.config or {})

  if not success then
    print("[Framework] ERROR: Job '" .. jobName .. "' init() failed: " .. tostring(result))
    return false
  end

  if result == false then
    print("[Framework] ERROR: Job '" .. jobName .. "' init() returned false")
    return false
  end

  debugLog(jobName, "Job initialized")
  return true
end

local function startJob(jobName)
  local instance = background_jobs_state.job_instances[jobName]
  if not instance then return false end

  if instance.module.start and type(instance.module.start) == "function" then
    debugLog(jobName, "Starting job")

    local success, result = pcall(instance.module.start)

    if not success then
      print("[Framework] ERROR: Job '" .. jobName .. "' start() failed: " .. tostring(result))
      return false
    end

    if result == false then
      print("[Framework] ERROR: Job '" .. jobName .. "' start() returned false")
      return false
    end

    debugLog(jobName, "Job started")
  end

  return true
end

local function stopJob(jobName)
  local instance = background_jobs_state.job_instances[jobName]
  if not instance then return false end

  if instance.module.stop and type(instance.module.stop) == "function" then
    debugLog(jobName, "Stopping job")

    local success, result = pcall(instance.module.stop)

    if not success then
      print("[Framework] ERROR: Job '" .. jobName .. "' stop() failed: " .. tostring(result))
      return false
    end

    debugLog(jobName, "Job stopped")
  end

  return true
end

-- Event Distribution Functions

local function distributeWindowFocusEvent(window, appName)
  debugLog(nil, "Window focused: " .. (appName or "unknown"))

  for jobName, instance in pairs(background_jobs_state.job_instances) do
    if instance.module.onWindowFocused and type(instance.module.onWindowFocused) == "function" then
      local success, err = pcall(instance.module.onWindowFocused, window, appName)
      if not success then
        print("[Framework] ERROR: Job '" .. jobName .. "' onWindowFocused() failed: " .. tostring(err))
      end
    end
  end
end

local function distributeTimerTickEvent()
  debugLog(nil, "Timer tick")

  for jobName, instance in pairs(background_jobs_state.job_instances) do
    if instance.module.onTimerTick and type(instance.module.onTimerTick) == "function" then
      local interval = instance.config.polling_interval or 5
      local success, err = pcall(instance.module.onTimerTick, interval)
      if not success then
        print("[Framework] ERROR: Job '" .. jobName .. "' onTimerTick() failed: " .. tostring(err))
      end
    end
  end
end

local function distributeAppLaunchEvent(appName, event)
  debugLog(nil, "App event: " .. event .. " - " .. appName)

  for jobName, instance in pairs(background_jobs_state.job_instances) do
    if event == hs.application.watcher.launched then
      if instance.module.onAppLaunched and type(instance.module.onAppLaunched) == "function" then
        local success, err = pcall(instance.module.onAppLaunched, appName)
        if not success then
          print("[Framework] ERROR: Job '" .. jobName .. "' onAppLaunched() failed: " .. tostring(err))
        end
      end
    elseif event == hs.application.watcher.terminated then
      if instance.module.onAppTerminated and type(instance.module.onAppTerminated) == "function" then
        local success, err = pcall(instance.module.onAppTerminated, appName)
        if not success then
          print("[Framework] ERROR: Job '" .. jobName .. "' onAppTerminated() failed: " .. tostring(err))
        end
      end
    end
  end
end

-- Framework Initialization

local function initializeFramework()
  print("[Framework] Initializing Background Jobs Framework")

  -- Load configuration
  if not background_jobs then
    print("[Framework] ERROR: background_jobs configuration not found in config.lua")
    return false
  end

  background_jobs_state.enabled = background_jobs.enabled or false
  background_jobs_state.debug_mode = background_jobs.debug_mode or false

  if not background_jobs_state.enabled then
    print("[Framework] Background Jobs disabled in config")
    return false
  end

  debugLog(nil, "Debug mode: " .. tostring(background_jobs_state.debug_mode))

  -- Load all enabled jobs
  local jobCount = 0
  for jobName, jobConfig in pairs(background_jobs.jobs or {}) do
    if jobConfig.enabled then
      if loadJob(jobName, jobConfig) then
        if initializeJob(jobName) then
          if startJob(jobName) then
            jobCount = jobCount + 1
          end
        end
      end
    else
      debugLog(nil, "Job disabled: " .. jobName)
    end
  end

  if jobCount == 0 then
    print("[Framework] No jobs enabled")
    return false
  end

  print("[Framework] " .. jobCount .. " job(s) loaded and started")

  -- Setup shared event sources
  setupEventSources()

  print("[Framework] Background Jobs Framework initialized")
  return true
end

function setupEventSources()
  -- Window filter for browser focus events
  debugLog(nil, "Setting up window filter")
  window_filter = hs.window.filter.new(false)
    :setAppFilter('Safari', true)
    :setAppFilter('Google Chrome', true)
    :setAppFilter('Microsoft Edge', true)
    :setAppFilter('Arc', true)
    :setAppFilter('Brave Browser', true)
    :setAppFilter('Firefox', true)

  window_filter:subscribe(hs.window.filter.windowFocused, function(window, appName)
    distributeWindowFocusEvent(window, appName)
  end)

  -- Only create polling timer if at least one job has onTimerTick handler
  local needsTimer = false
  local minInterval = 5
  for _, instance in pairs(background_jobs_state.job_instances) do
    if instance.module.onTimerTick and type(instance.module.onTimerTick) == "function" then
      needsTimer = true
      local interval = instance.config.polling_interval or 5
      if interval < minInterval then
        minInterval = interval
      end
    end
  end

  if needsTimer then
    debugLog(nil, "Setting up polling timer (interval: " .. minInterval .. "s)")
    polling_timer = hs.timer.doEvery(minInterval, function()
      distributeTimerTickEvent()
    end)
  else
    debugLog(nil, "No jobs need polling timer, skipping")
  end

  -- App watcher for launch/terminate events
  debugLog(nil, "Setting up app watcher")
  app_watcher = hs.application.watcher.new(function(appName, event, app)
    distributeAppLaunchEvent(appName, event)
  end)
  app_watcher:start()
end

local function cleanupFramework()
  debugLog(nil, "Cleaning up framework")

  -- Stop all jobs
  for jobName in pairs(background_jobs_state.job_instances) do
    stopJob(jobName)
  end

  -- Cleanup event sources
  if window_filter then
    window_filter:unsubscribeAll()
    window_filter = nil
  end

  if polling_timer then
    polling_timer:stop()
    polling_timer = nil
  end

  if app_watcher then
    app_watcher:stop()
    app_watcher = nil
  end

  debugLog(nil, "Framework cleaned up")
end

-- Initialize framework
initializeFramework()
