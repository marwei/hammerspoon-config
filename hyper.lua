hyper = {'cmd', 'alt', 'shift', 'ctrl' }

-- Intermediate modal as a proxy to forward `hyper + <key>` event to `cmd + alt + shift + ctrl + <key>` event
local hyper_modal = hs.hotkey.modal.new({}, 'F17')

-- All of the keys, from here:
-- https://github.com/Hammerspoon/hammerspoon/blob/f3446073f3e58bba0539ff8b2017a65b446954f7/extensions/keycodes/internal.m
-- except with ' instead of " (not sure why but it didn't work otherwise)
-- and the function keys greater than F12 removed.
local keys = {
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
  "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "`", "=", "-", "]", "[", "\'", ";", "\\", ",", "/",
  ".", "§", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "pad.", "pad*", "pad+", "pad/",
  "pad-", "pad=", "pad0", "pad1", "pad2", "pad3", "pad4", "pad5", "pad6", "pad7", "pad8", "pad9", "padclear",
  "padenter", "return", "tab", "space", "delete", "help", "home", "pageup", "forwarddelete", "end", "pagedown",
  "left", "right", "down", "up"
}

local hyper_with_key = function(key)
  return function()
    hs.eventtap.keyStroke(hyper, key)
    hyper_modal.triggered = true
  end
end

local enter_hyper_mode = function()
  hyper_modal.triggered = false
  hyper_modal:enter()
end

-- Leave Hyper Mode. Send ESCAPE if Hyper Mode was not triggered (no other keys are pressed)
local exit_hyper_mode = function()
  hyper_modal:exit()
  if not hyper_modal.triggered then
    hs.eventtap.keyStroke({}, 'ESCAPE')
  end
end

-- Enable all the keys in the Hyper Mode
for _, key in pairs(keys) do
  hyper_modal:bind('', key, nil, hyper_with_key(key))
end

-- Bind the Hyper key
-- Enter Hyper Mode when F18 (Capslock) is pressed
-- Leave Hyper Mode when F18 (Capslock) is released
hs.hotkey.bind({}, 'F18', enter_hyper_mode, exit_hyper_mode)

