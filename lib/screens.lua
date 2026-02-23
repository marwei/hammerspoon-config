-- Shared screen detection utilities

function getNativeScreen()
  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    if screen:name():match("Built%-in") or screen:name():match("Color LCD") then
      return screen
    end
  end
  return hs.screen.primaryScreen()
end

function getUltraWideScreen()
  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    if not (screen:name():match("Built%-in") or screen:name():match("Color LCD")) then
      return screen
    end
  end
  return hs.screen.primaryScreen()
end
