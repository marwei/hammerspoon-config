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
      local aspectRatio = max.w / max.h
      local isUltraWide = aspectRatio > 2.0

      if isUltraWide then
        localf.w = max.w * 0.5
        localf.h = max.h
        localf.x = max.w * 0.25
        localf.y = 0
      else
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
resizeM.name = "Resize"

function resizeM:entered()
  if show_modal == true then toggle_modal_key_display(resizeM) end
end

function resizeM:exited()
  if show_modal == true then toggle_modal_key_display(resizeM) end
end

resizeM:bind('', 'escape', function() resizeM:exit() end)
resizeM:bind(hyper, 'escape', function() resizeM:exit() end)

resizeM.items = {
  {key = "H", label = "Left half",          icon = "lucide:panel-left",   action = function() resize_win('halfleft') end},
  {key = "L", label = "Right half",         icon = "lucide:panel-right",  action = function() resize_win('halfright') end},
  {key = "K", label = "Top half",           icon = "lucide:panel-top",    action = function() resize_win('halfup') end},
  {key = "J", label = "Bottom half",        icon = "lucide:panel-bottom", action = function() resize_win('halfdown') end},
  {key = "H", mod = "⇧", label = "Left quarter",  icon = "lucide:panel-left",  action = function() resize_win('quarterleft') end,  modKey = "shift"},
  {key = "L", mod = "⇧", label = "Right quarter", icon = "lucide:panel-right", action = function() resize_win('quarterright') end, modKey = "shift"},
  {key = "F", label = "Fullscreen",         icon = "lucide:square",       action = function() resize_win('fullscreen') end},
  {key = "C", label = "Center",             icon = "lucide:circle-dot",   action = function() resize_win('center') end},
  {key = "up",    label = "Move to monitor above", icon = "lucide:arrow-up",    action = function() move_win('up') end},
  {key = "down",  label = "Move to monitor below", icon = "lucide:arrow-down",  action = function() move_win('down') end},
  {key = "left",  label = "Move to monitor left",  icon = "lucide:arrow-left",  action = function() move_win('left') end},
  {key = "right", label = "Move to monitor right", icon = "lucide:arrow-right", action = function() move_win('right') end},
}

for _, it in ipairs(resizeM.items) do
  local mod = it.modKey or ''
  resizeM:bind(mod, it.key, it.label, it.action)
  if mod == '' then
    resizeM:bind(hyper, it.key, it.action)
  end
end

require('lib/icons').prewarm(resizeM.items)
