require('lib/utility')

local cheatsheet = require('lib/cheatsheet_view')

-- Modal cheatsheet: driven by `modal.items` (array of {key, label, icon}).
-- The modal name is read from `modal.name`. Called from each modal's
-- entered/exited callbacks; idempotent show/hide so click-to-close on the
-- cheatsheet (without exiting the modal) doesn't desync the toggle.
function toggle_modal_key_display(modal)
  if not modal then
    cheatsheet.hide()
    return
  end
  if cheatsheet.isVisible() then
    cheatsheet.hide()
  else
    if modal.items then cheatsheet.show(modal.name, modal.items) end
  end
end

-- Global shortcut overlay (Hyper+H). Static items; manages its own ESC handler.
function show_global_shortcuts()
  if cheatsheet.isVisible() then
    cheatsheet.hide()
    if global_shortcuts_escape then
      global_shortcuts_escape:delete()
      global_shortcuts_escape = nil
    end
    return
  end

  local items = {
    {key = "M", mod = "✦", label = "Enter Resize Mode",        icon = "lucide:panel-left"},
    {key = "Space", mod = "✦", label = "Enter App Launcher",   icon = "lucide:app-window"},
    {key = "F", mod = "✦", label = "Enter Workflow Mode",      icon = "lucide:sparkles"},
    {key = "G", mod = "✦", label = "Enter Cerebral Mode",      icon = "lucide:brain"},
    {key = "H", mod = "✦", label = "Toggle Global Shortcuts",  icon = "lucide:keyboard"},
    {key = "R", mod = "✦", label = "Reload Configuration",     icon = "lucide:circle-dot"},
    {key = "Z", mod = "✦", label = "Toggle Console",           icon = "lucide:terminal"},
  }

  local function dismiss()
    cheatsheet.hide()
    if global_shortcuts_escape then
      global_shortcuts_escape:delete()
      global_shortcuts_escape = nil
    end
  end

  cheatsheet.show("Global Shortcuts", items, {closeOnClick = true, onClose = dismiss})
  global_shortcuts_escape = hs.hotkey.bind('', 'escape', dismiss)
end

-- Cleanup hook so screen-watcher cleanup in init.lua continues to work.
function cleanup_cheatsheet_view()
  cheatsheet.destroy()
  cheatsheet.clearIconCache()
  cheatsheet.prewarm()
end
