function resize_win(direction)
  local win = hs.window.focusedWindow()
  if win then
    local f = win:frame()
    local screen = win:screen()
    local localf = screen:absoluteToLocal(f)
    local max = screen:fullFrame()
    local split_left = max.w * 0
    local width_left = max.w * 0.5
    local split_center = max.w * 0.25
    local width_center = max.w * 0.5
    local split_right = max.w * 0.5
    local width_right = max.w * 0.5

    if direction == "halfleft" then
      localf.x = split_left localf.y = 0 localf.w = width_left localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfright" then
      localf.x = split_right localf.y = 0 localf.w = width_right localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfup" then
      localf.x = split_center localf.y = 0 localf.w = width_center localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfdown" then
      localf.x = split_center localf.y = max.h/2 localf.w = width_center localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "quarterleft" then
      localf.x = 0 localf.y = 0 localf.w = max.w * 0.25 localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "quarterright" then
      localf.x = max.w * 0.75 localf.y = 0 localf.w = max.w * 0.25 localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "fullscreen" then
      localf.x = 0 localf.y = 0 localf.w = max.w localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef, 0)
    end
    if direction == "center" then
      -- Check if ultra-wide (aspect ratio > 2.0)
      local aspectRatio = max.w / max.h
      local isUltraWide = aspectRatio > 2.0

      if isUltraWide then
        -- Ultra-wide: center 50% (25% to 75%)
        localf.w = max.w * 0.5
        localf.h = max.h
        localf.x = max.w * 0.25
        localf.y = 0
      else
        -- Regular screen: 90% of full screen, centered
        localf.w = max.w * 0.9
        localf.h = max.h * 0.9
        localf.x = (max.w - localf.w) / 2
        localf.y = (max.h - localf.h) / 2
      end

      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef, 0)
    end
  else
    hs.alert.show("No focused window!")
  end
end

function move_win(direction)
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  if win then
    if direction == 'up' then win:moveOneScreenNorth() end
    if direction == 'down' then win:moveOneScreenSouth() end
    if direction == 'left' then win:moveOneScreenWest() end
    if direction == 'right' then win:moveOneScreenEast() end
  end
end

resizeM = hs.hotkey.modal.new()

function resizeM:entered()
  toggle_modal_light(firebrick,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

function resizeM:exited()
  toggle_modal_light(firebrick,0.7)
  if show_modal == true then toggle_modal_key_display() end
end

resizeM:bind('', 'escape', function() resizeM:exit() end)

resizeM:bind('', 'H', 'Left half of screen', function() resize_win('halfleft') end, nil, nil)
resizeM:bind('shift', 'H', 'Left quarter of screen', function() resize_win('quarterleft') end, nil, nil)
resizeM:bind('', 'J', 'Down half of screen', function() resize_win('halfdown') end, nil, nil)
resizeM:bind('', 'K', 'Up half of screen', function() resize_win('halfup') end, nil, nil)
resizeM:bind('', 'L', 'Right half of screen', function() resize_win('halfright') end, nil, nil)
resizeM:bind('shift', 'L', 'Right quarter of screen', function() resize_win('quarterright') end, nil, nil)

resizeM:bind('', 'F', 'Fullscreen', function() resize_win('fullscreen') end, nil, nil)
resizeM:bind('', 'C', 'Center window', function() resize_win('center') end, nil, nil)

resizeM:bind('', 'up', 'Move to monitor above', function() move_win('up') end, nil, nil)
resizeM:bind('', 'down', 'Move to monitor below', function() move_win('down') end, nil, nil)
resizeM:bind('', 'left', 'Move to monitor left', function() move_win('left') end, nil, nil)
resizeM:bind('', 'right', 'Move to monitor right', function() move_win('right') end, nil, nil)

