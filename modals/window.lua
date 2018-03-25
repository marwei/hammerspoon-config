function move_win(direction)
  local win = hs.window.focusedWindow()
  local screen = win:screen()
  if win then
    if direction == 'up' then win:moveOneScreenNorth() end
    if direction == 'down' then win:moveOneScreenSouth() end
    if direction == 'left' then win:moveOneScreenWest() end
    if direction == 'right' then win:moveOneScreenEast() end
    if direction == 'next' then win:moveToScreen(screen:next()) end
  end
end

function resize_win(direction)
  local win = hs.window.focusedWindow()
  if win then
    local f = win:frame()
    local screen = win:screen()
    local localf = screen:absoluteToLocal(f)
    local max = screen:fullFrame()
    local stepw = max.w/30
    local steph = max.h/30
    if direction == "right" then
      localf.w = localf.w+stepw
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "left" then
      localf.w = localf.w-stepw
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "up" then
      localf.h = localf.h-steph
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "down" then
      localf.h = localf.h+steph
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfright" then
      localf.x = max.w/2 localf.y = 0 localf.w = max.w/2 localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfleft" then
      localf.x = 0 localf.y = 0 localf.w = max.w/2 localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfup" then
      localf.x = 0 localf.y = 0 localf.w = max.w localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "halfdown" then
      localf.x = 0 localf.y = max.h/2 localf.w = max.w localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "cornerNE" then
      localf.x = max.w/2 localf.y = 0 localf.w = max.w/2 localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "cornerSE" then
      localf.x = max.w/2 localf.y = max.h/2 localf.w = max.w/2 localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "cornerNW" then
      localf.x = 0 localf.y = 0 localf.w = max.w/2 localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "cornerSW" then
      localf.x = 0 localf.y = max.h/2 localf.w = max.w/2 localf.h = max.h/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "center" then
      localf.x = (max.w-localf.w)/2 localf.y = (max.h-localf.h)/2
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "fcenter" then
      localf.x = stepw*5 localf.y = steph*5 localf.w = stepw*20 localf.h = steph*20
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "fullscreen" then
      localf.x = 0 localf.y = 0 localf.w = max.w localf.h = max.h
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "shrink" then
      localf.x = localf.x+stepw localf.y = localf.y+steph localf.w = localf.w-(stepw*2) localf.h = localf.h-(steph*2)
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "expand" then
      localf.x = localf.x-stepw localf.y = localf.y-steph localf.w = localf.w+(stepw*2) localf.h = localf.h+(steph*2)
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "mright" then
      localf.x = localf.x+stepw
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "mleft" then
      localf.x = localf.x-stepw
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "mup" then
      localf.y = localf.y-steph
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "mdown" then
      localf.y = localf.y+steph
      local absolutef = screen:localToAbsolute(localf)
      win:setFrame(absolutef)
    end
    if direction == "ccursor" then
      localf.x = localf.x+localf.w/2 localf.y = localf.y+localf.h/2
      hs.mouse.setRelativePosition({x=localf.x,y=localf.y},screen)
    end
  else
    hs.alert.show("No focused window!")
  end
end

resizeM = hs.hotkey.modal.new()
local modalpkg = {}
modalpkg.id = "resizeM"
modalpkg.modal = resizeM
table.insert(modal_list, modalpkg)

function resizeM:entered()
  modal_stat(firebrick,0.7)
  resize_current_winnum = 1
  -- resize_win_list = hs.window.visibleWindows()
  for i=1,#modal_list do
    if modal_list[i].id == "resizeM" then
      table.insert(activeModals, modal_list[i])
    end
  end
  if hotkeytext then
    hotkeytext:delete()
    hotkeytext=nil
    hotkeybg:delete()
    hotkeybg=nil
  end
  if show_resize_tips == nil then show_resize_tips = true end
  if show_resize_tips == true then showavailableHotkey() end
end

function resizeM:exited()
  modal_tray:hide()
  for i=1,#activeModals do
    if activeModals[i].id == "resizeM" then
      table.remove(activeModals, i)
    end
  end
  if hotkeytext then
    hotkeytext:delete()
    hotkeytext=nil
    hotkeybg:delete()
    hotkeybg=nil
  end
end

resizeM:bind('', 'escape', function() resizeM:exit() end)
resizeM:bind('', 'Q', function() resizeM:exit() end)
resizeM:bind('', 'tab', function() showavailableHotkey() end)
resizeM:bind('shift', 'Y', 'Shrink Leftward', function() resize_win('left') end, nil, function() resize_win('left') end)
resizeM:bind('shift', 'O', 'Stretch Rightward', function() resize_win('right') end, nil, function() resize_win('right') end)
resizeM:bind('shift', 'U', 'Stretch Downward', function() resize_win('down') end, nil, function() resize_win('down') end)
resizeM:bind('shift', 'I', 'Shrink Upward', function() resize_win('up') end, nil, function() resize_win('up') end)
resizeM:bind('', 'F', 'Fullscreen', function() resize_win('fullscreen') end, nil, nil)
resizeM:bind('', 'C', 'Center Window', function() resize_win('center') end, nil, nil)
resizeM:bind('shift', 'C', 'Resize & Center', function() resize_win('fcenter') end, nil, nil)
resizeM:bind('', 'H', 'Lefthalf of Screen', function() resize_win('halfleft') end, nil, nil)
resizeM:bind('', 'J', 'Downhalf of Screen', function() resize_win('halfdown') end, nil, nil)
resizeM:bind('', 'K', 'Uphalf of Screen', function() resize_win('halfup') end, nil, nil)
resizeM:bind('', 'L', 'Righthalf of Screen', function() resize_win('halfright') end, nil, nil)
resizeM:bind('', 'W', 'NorthWest Corner', function() resize_win('cornerNW') end, nil, nil)
resizeM:bind('', 'S', 'SouthWest Corner', function() resize_win('cornerSW') end, nil, nil)
resizeM:bind('', 'D', 'SouthEast Corner', function() resize_win('cornerSE') end, nil, nil)
resizeM:bind('', 'E', 'NorthEast Corner', function() resize_win('cornerNE') end, nil, nil)
resizeM:bind('', '=', 'Stretch Outward', function() resize_win('expand') end, nil, function() resize_win('expand') end)
resizeM:bind('', '-', 'Shrink Inward', function() resize_win('shrink') end, nil, function() resize_win('shrink') end)
resizeM:bind('shift', 'H', 'Move Leftward', function() resize_win('mleft') end, nil, function() resize_win('mleft') end)
resizeM:bind('shift', 'L', 'Move Rightward', function() resize_win('mright') end, nil, function() resize_win('mright') end)
resizeM:bind('shift', 'J', 'Move Downward', function() resize_win('mdown') end, nil, function() resize_win('mdown') end)
resizeM:bind('shift', 'K', 'Move Upward', function() resize_win('mup') end, nil, function() resize_win('mup') end)
resizeM:bind('', '`', 'Center Cursor', function() resize_win('ccursor') end, nil, nil)
resizeM:bind('', '[', 'Focus Westward', function() cycle_wins_pre() end, nil, function() cycle_wins_pre() end)
resizeM:bind('', ']', 'Focus Eastward', function() cycle_wins_next() end, nil, function() cycle_wins_next() end)
resizeM:bind('', 'up', 'Move to monitor above', function() move_win('up') end, nil, nil)
resizeM:bind('', 'down', 'Move to monitor below', function() move_win('down') end, nil, nil)
resizeM:bind('', 'right', 'Move to monitor right', function() move_win('right') end, nil, nil)
resizeM:bind('', 'left', 'Move to monitor left', function() move_win('left') end, nil, nil)
resizeM:bind('', 'space', 'Move to next monitor', function() move_win('next') end, nil, nil)

function cycle_wins_next()
  resize_win_list[resize_current_winnum]:focus()
  resize_current_winnum = resize_current_winnum + 1
  if resize_current_winnum > #resize_win_list then resize_current_winnum = 1 end
end

function cycle_wins_pre()
  resize_win_list[resize_current_winnum]:focus()
  resize_current_winnum = resize_current_winnum - 1
  if resize_current_winnum < 1 then resize_current_winnum = #resize_win_list end
end

