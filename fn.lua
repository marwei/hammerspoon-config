-- Fn related keybindings
local function catcher(event)
  if event:getFlags()['fn'] and event:getCharacters() == "h" then
    return true, {hs.eventtap.event.newKeyEvent({}, "left", true)}
  elseif event:getFlags()['fn'] and event:getCharacters() == "l" then
    return true, {hs.eventtap.event.newKeyEvent({}, "right", true)}
  elseif event:getFlags()['fn'] and event:getCharacters() == "j" then
    return true, {hs.eventtap.event.newKeyEvent({}, "down", true)}
  elseif event:getFlags()['fn'] and event:getCharacters() == "k" then
    return true, {hs.eventtap.event.newKeyEvent({}, "up", true)}
  elseif event:getFlags()['fn'] and event:getCharacters() == "y" then
    return true, {hs.eventtap.event.newScrollEvent({3,0},{},"line")}
  elseif event:getFlags()['fn'] and event:getCharacters() == "o" then
    return true, {hs.eventtap.event.newScrollEvent({-3,0},{},"line")}
  elseif event:getFlags()['fn'] and event:getCharacters() == "u" then
    return true, {hs.eventtap.event.newScrollEvent({0,-3},{},"line")}
  elseif event:getFlags()['fn'] and event:getCharacters() == "i" then
    return true, {hs.eventtap.event.newScrollEvent({0,3},{},"line")}
  elseif event:getFlags()['fn'] and event:getCharacters() == "," then
    local currentpos = hs.mouse.getRelativePosition()
    return true, {hs.eventtap.leftClick(currentpos)}
  elseif event:getFlags()['fn'] and event:getCharacters() == "." then
    local currentpos = hs.mouse.getRelativePosition()
    return true, {hs.eventtap.rightClick(currentpos)}
  end
  return false
end

fn_tapper = hs.eventtap.new({hs.eventtap.event.types.keyDown}, catcher):start()
