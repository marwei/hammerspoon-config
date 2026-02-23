require('lib/utility')

-- Helper to create a cheatsheet-style canvas overlay
-- title: display title string
-- heightRatio: fraction of screen height (e.g. 0.65, 0.45)
-- contentBuilder(view, width, height, padding, elementIndex): function that adds content elements, returns final elementIndex
local function createCheatsheetCanvas(title, heightRatio, contentBuilder)
  local mainScreen = hs.screen.mainScreen()
  local mainRes = mainScreen:fullFrame()
  local localMainRes = mainScreen:absoluteToLocal(mainRes)

  -- Find smallest screen width for consistent modal sizing
  local allScreens = hs.screen.allScreens()
  local minScreenWidth = localMainRes.w
  for _, screen in ipairs(allScreens) do
    local screenFrame = screen:fullFrame()
    local localFrame = screen:absoluteToLocal(screenFrame)
    if localFrame.w < minScreenWidth then
      minScreenWidth = localFrame.w
    end
  end

  local padding = 50
  local maxWidth = minScreenWidth * 0.5
  local width = math.min(localMainRes.w * 0.5, maxWidth)
  local height = localMainRes.h * heightRatio
  local x = (localMainRes.w - width) / 2
  local y = (localMainRes.h - height) / 2

  local canvasRect = mainScreen:localToAbsolute({x=x, y=y, w=width, h=height})
  local view = hs.canvas.new(canvasRect)

  -- Background
  view[1] = {
    type = "rectangle",
    action = "fill",
    fillColor = {white=0.98, alpha=0.92},
    roundedRectRadii = {xRadius=16, yRadius=16},
  }

  -- Border
  view[2] = {
    type = "rectangle",
    action = "stroke",
    strokeColor = {white=0.85, alpha=0.3},
    strokeWidth = 1,
    roundedRectRadii = {xRadius=16, yRadius=16},
    frame = {x=0.5, y=0.5, w=width-1, h=height-1}
  }

  -- Title
  view[3] = {
    type = "text",
    text = title,
    textFont = ".AppleSystemUIFont",
    textSize = 24,
    textColor = {hex="#1d1d1f"},
    textAlignment = "center",
    frame = {x=padding, y=30, w=width-padding*2, h=40}
  }

  -- Content
  local elementIndex = contentBuilder(view, width, height, padding, 4)

  -- Footer
  view[elementIndex] = {
    type = "text",
    text = "Click anywhere to close",
    textFont = ".AppleSystemUIFont",
    textSize = 11,
    textColor = {white=0.5, alpha=0.8},
    textAlignment = "center",
    frame = {x=padding, y=height-40, w=width-padding*2, h=20}
  }

  view:level(hs.canvas.windowLevels.modalPanel)
  view:behavior(hs.canvas.windowBehaviors.stationary)
  view:clickActivating(false)
  view:canvasMouseEvents(true, true)

  return view
end

-- Helper to render a two-column grid of key/description pairs
local function renderShortcutGrid(view, items, width, padding, startIndex)
  local yOffset = 85
  local lineHeight = 32
  local columnWidth = (width - padding*2) / 2
  local keyColor = {hex="#007AFF"}
  local descColor = {hex="#1d1d1f"}

  local elementIndex = startIndex
  for i=1, #items do
    local key = items[i].key
    local desc = items[i].desc

    local column = ((i-1) % 2)
    local xPos = padding + (column * columnWidth)
    local yPos = yOffset + (math.floor((i-1) / 2) * lineHeight)

    view[elementIndex] = {
      type = "text",
      text = key,
      textFont = ".AppleSystemUIFontBold",
      textSize = 14,
      textColor = keyColor,
      textAlignment = "left",
      frame = {x=xPos, y=yPos, w=80, h=lineHeight}
    }
    elementIndex = elementIndex + 1

    if desc ~= "" then
      view[elementIndex] = {
        type = "text",
        text = desc,
        textFont = ".AppleSystemUIFont",
        textSize = 13,
        textColor = descColor,
        textAlignment = "left",
        frame = {x=xPos+85, y=yPos+1, w=columnWidth-90, h=lineHeight}
      }
      elementIndex = elementIndex + 1
    end
  end

  return elementIndex
end

function toggle_modal_key_display()
  if not cheatsheet_view then
    local hotkey_list = hs.hotkey.getHotkeys()

    -- Filter hotkeys - only show modal-specific shortcuts
    local hotkey_filtered = {}

    local global_descriptions = {
      ["Enter Resize Mode"] = true,
      ["Enter App Launcher Mode"] = true,
      ["Enter Layout Mode"] = true,
      ["Enter Automation Mode"] = true,
      ["Enter Cerebral Mode"] = true,
      ["Reload Configuration"] = true,
      ["Toggle Hotkeys Cheatsheet"] = true,
      ["Toggle Global Shortcuts"] = true,
      ["Toggle Hammerspoon Console"] = true,
    }

    for i=1,#hotkey_list do
      if hotkey_list[i].idx ~= hotkey_list[i].msg then
        local msg = hotkey_list[i].msg or ""
        local _, desc_part = msg:match("^(.-):%s*(.+)$")
        if not desc_part then
          desc_part = msg
        end
        if not global_descriptions[desc_part] then
          table.insert(hotkey_filtered, hotkey_list[i])
        end
      end
    end

    -- Build items list from filtered hotkeys
    local items = {}
    for _, hotkey in ipairs(hotkey_filtered) do
      local msg = hotkey.msg or ""
      local key_part, desc_part = msg:match("^(.-):%s*(.+)$")
      if not key_part then
        key_part = msg
        desc_part = ""
      end
      table.insert(items, {key=key_part, desc=desc_part})
    end

    cheatsheet_view = createCheatsheetCanvas("Keyboard Shortcuts", 0.65, function(view, width, height, padding, startIndex)
      return renderShortcutGrid(view, items, width, padding, startIndex)
    end)

    cheatsheet_view:mouseCallback(function(canvas, event, id, x, y)
      if event == "mouseDown" then
        cheatsheet_view:delete()
        cheatsheet_view = nil
      end
    end)
    cheatsheet_view:show()
  else
    cheatsheet_view:delete()
    cheatsheet_view = nil
  end
end

function show_global_shortcuts()
  if not global_shortcuts_view then
    local global_shortcuts = {
      {key="✦M", desc="Enter Resize Mode"},
      {key="✦T", desc="Enter App Launcher Mode"},
      {key="✦H", desc="Toggle Global Shortcuts"},
      {key="✦R", desc="Reload Configuration"},
      {key="✦Z", desc="Toggle Hammerspoon Console"},
    }

    global_shortcuts_view = createCheatsheetCanvas("Global Shortcuts", 0.45, function(view, width, height, padding, startIndex)
      return renderShortcutGrid(view, global_shortcuts, width, padding, startIndex)
    end)

    global_shortcuts_view:mouseCallback(function(canvas, event, id, x, y)
      if event == "mouseDown" then
        global_shortcuts_view:delete()
        global_shortcuts_view = nil
        if global_shortcuts_escape then
          global_shortcuts_escape:delete()
          global_shortcuts_escape = nil
        end
      end
    end)

    -- Add ESC key handler to close
    global_shortcuts_escape = hs.hotkey.bind('', 'escape', function()
      if global_shortcuts_view then
        global_shortcuts_view:delete()
        global_shortcuts_view = nil
      end
      if global_shortcuts_escape then
        global_shortcuts_escape:delete()
        global_shortcuts_escape = nil
      end
    end)

    global_shortcuts_view:show()
  else
    global_shortcuts_view:delete()
    global_shortcuts_view = nil
    if global_shortcuts_escape then
      global_shortcuts_escape:delete()
      global_shortcuts_escape = nil
    end
  end
end

function toggle_modal_light(color,alpha)
  if not modal_light then
    local mainScreen = hs.screen.mainScreen()
    local mainRes = mainScreen:fullFrame()
    local localMainRes = mainScreen:absoluteToLocal(mainRes)
    modal_light = hs.canvas.new(mainScreen:localToAbsolute({x=localMainRes.w-120,y=120,w=100,h=100}))
    modal_light[1] = {action="fill",type="circle",fillColor=white}
    modal_light[1].fillColor.alpha=0.7
    modal_light[2] = {action="fill",type="circle",fillColor=white,radius="40%"}
    modal_light:level(hs.canvas.windowLevels.status)
    modal_light:clickActivating(false)
    modal_light:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces + hs.canvas.windowBehaviors.stationary)
    modal_light._default.trackMouseDown = true
    modal_light:show()
    modal_light[2].fillColor = color
    modal_light[2].fillColor.alpha = alpha
  else
    modal_light:delete()
    modal_light = nil
  end
end
