resizeextra_lefthalf_keys = resizeextra_lefthalf_keys or {{"cmd", "alt"}, "left"}
if string.len(resizeextra_lefthalf_keys[2]) > 0 then
  hs.hotkey.bind(resizeextra_lefthalf_keys[1], resizeextra_lefthalf_keys[2], "Lefthalf of Screen", function() resize_win('halfleft') end)
end
resizeextra_righthalf_keys = resizeextra_righthalf_keys or {{"cmd", "alt"}, "right"}
if string.len(resizeextra_righthalf_keys[2]) > 0 then
  hs.hotkey.bind(resizeextra_righthalf_keys[1], resizeextra_righthalf_keys[2], "Righthalf of Screen", function() resize_win('halfright') end)
end
resizeextra_fullscreen_keys = resizeextra_fullscreen_keys or {{"cmd", "alt"}, "up"}
if string.len(resizeextra_fullscreen_keys[2]) > 0 then
  hs.hotkey.bind(resizeextra_fullscreen_keys[1], resizeextra_fullscreen_keys[2], "Fullscreen", function() resize_win('fullscreen') end)
end
resizeextra_fcenter_keys = resizeextra_fcenter_keys or {{"cmd", "alt"}, "down"}
if string.len(resizeextra_fcenter_keys[2]) > 0 then
  hs.hotkey.bind(resizeextra_fcenter_keys[1], resizeextra_fcenter_keys[2], "Resize & Center", function() resize_win('fcenter') end)
end
resizeextra_center_keys = resizeextra_center_keys or {{"cmd", "alt"}, "return"}
if string.len(resizeextra_center_keys[2]) > 0 then
  hs.hotkey.bind(resizeextra_center_keys[1], resizeextra_center_keys[2], "Center Window", function() resize_win('center') end)
end

