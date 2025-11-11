require('lib/utility')

function toggle_modal_key_display()
  if not cheatsheet_view then
    local hotkey_list = hs.hotkey.getHotkeys()
    local mainScreen = hs.screen.mainScreen()
    local mainRes = mainScreen:fullFrame()
    local localMainRes = mainScreen:absoluteToLocal(mainRes)

    -- Filter hotkeys - only show modal-specific shortcuts
    hotkey_filtered = {}

    -- Global hotkey descriptions to exclude
    local global_descriptions = {
      ["Enter Resize Mode"] = true,
      ["Enter App Launcher Mode"] = true,
      ["Reload Configuration"] = true,
      ["Toggle Hotkeys Cheatsheet"] = true,
      ["Toggle Hammerspoon Console"] = true,
    }

    for i=1,#hotkey_list do
      if hotkey_list[i].idx ~= hotkey_list[i].msg then
        local msg = hotkey_list[i].msg or ""
        -- Extract description part (after the colon)
        local _, desc_part = msg:match("^(.-):%s*(.+)$")
        if not desc_part then
          desc_part = msg
        end

        -- Only include non-global hotkeys
        if not global_descriptions[desc_part] then
          table.insert(hotkey_filtered, hotkey_list[i])
        end
      end
    end

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

    -- Calculate dimensions based on smallest screen
    local padding = 50
    local maxWidth = minScreenWidth * 0.5
    local width = math.min(localMainRes.w * 0.5, maxWidth)
    local height = localMainRes.h * 0.65
    local x = (localMainRes.w - width) / 2
    local y = (localMainRes.h - height) / 2

    local canvasRect = mainScreen:localToAbsolute({x=x, y=y, w=width, h=height})
    cheatsheet_view = hs.canvas.new(canvasRect)

    -- Background with blur effect (macOS style)
    cheatsheet_view[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = {white=0.98, alpha=0.92},
      roundedRectRadii = {xRadius=16, yRadius=16},
    }

    -- Subtle inner shadow for depth
    cheatsheet_view[2] = {
      type = "rectangle",
      action = "stroke",
      strokeColor = {white=0.85, alpha=0.3},
      strokeWidth = 1,
      roundedRectRadii = {xRadius=16, yRadius=16},
      frame = {x=0.5, y=0.5, w=width-1, h=height-1}
    }

    -- Title
    cheatsheet_view[3] = {
      type = "text",
      text = "Keyboard Shortcuts",
      textFont = ".AppleSystemUIFont",
      textSize = 24,
      textColor = {hex="#1d1d1f"},
      textAlignment = "center",
      frame = {x=padding, y=30, w=width-padding*2, h=40}
    }

    -- Build modal hotkey content
    local yOffset = 85
    local lineHeight = 32
    local columnWidth = (width - padding*2) / 2
    local keyColor = {hex="#007AFF"}  -- macOS blue
    local descColor = {hex="#1d1d1f"}

    local elementIndex = 4
    for i=1, #hotkey_filtered do
      local hotkey = hotkey_filtered[i]
      local msg = hotkey.msg or ""

      -- Split into key combination and description
      local key_part, desc_part = msg:match("^(.-):%s*(.+)$")
      if not key_part then
        key_part = msg
        desc_part = ""
      end

      -- Determine column
      local column = ((i-1) % 2)
      local xPos = padding + (column * columnWidth)
      local yPos = yOffset + (math.floor((i-1) / 2) * lineHeight)

      -- Key combination (bold, colored)
      cheatsheet_view[elementIndex] = {
        type = "text",
        text = key_part,
        textFont = ".AppleSystemUIFontBold",
        textSize = 14,
        textColor = keyColor,
        textAlignment = "left",
        frame = {x=xPos, y=yPos, w=80, h=lineHeight}
      }
      elementIndex = elementIndex + 1

      -- Description (regular weight)
      if desc_part ~= "" then
        cheatsheet_view[elementIndex] = {
          type = "text",
          text = desc_part,
          textFont = ".AppleSystemUIFont",
          textSize = 13,
          textColor = descColor,
          textAlignment = "left",
          frame = {x=xPos+85, y=yPos+1, w=columnWidth-90, h=lineHeight}
        }
        elementIndex = elementIndex + 1
      end
    end

    -- Footer hint
    cheatsheet_view[elementIndex] = {
      type = "text",
      text = "Click anywhere to close",
      textFont = ".AppleSystemUIFont",
      textSize = 11,
      textColor = {white=0.5, alpha=0.8},
      textAlignment = "center",
      frame = {x=padding, y=height-40, w=width-padding*2, h=20}
    }

    cheatsheet_view:level(hs.canvas.windowLevels.modalPanel)
    cheatsheet_view:behavior(hs.canvas.windowBehaviors.stationary)
    cheatsheet_view:clickActivating(false)
    cheatsheet_view:canvasMouseEvents(true, true)
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

    -- Calculate dimensions based on smallest screen
    local padding = 50
    local maxWidth = minScreenWidth * 0.5
    local width = math.min(localMainRes.w * 0.5, maxWidth)
    local height = localMainRes.h * 0.45
    local x = (localMainRes.w - width) / 2
    local y = (localMainRes.h - height) / 2

    local canvasRect = mainScreen:localToAbsolute({x=x, y=y, w=width, h=height})
    global_shortcuts_view = hs.canvas.new(canvasRect)

    -- Background with blur effect (macOS style)
    global_shortcuts_view[1] = {
      type = "rectangle",
      action = "fill",
      fillColor = {white=0.98, alpha=0.92},
      roundedRectRadii = {xRadius=16, yRadius=16},
    }

    -- Subtle inner shadow for depth
    global_shortcuts_view[2] = {
      type = "rectangle",
      action = "stroke",
      strokeColor = {white=0.85, alpha=0.3},
      strokeWidth = 1,
      roundedRectRadii = {xRadius=16, yRadius=16},
      frame = {x=0.5, y=0.5, w=width-1, h=height-1}
    }

    -- Title
    global_shortcuts_view[3] = {
      type = "text",
      text = "Global Shortcuts",
      textFont = ".AppleSystemUIFont",
      textSize = 24,
      textColor = {hex="#1d1d1f"},
      textAlignment = "center",
      frame = {x=padding, y=30, w=width-padding*2, h=40}
    }

    -- Define global shortcuts manually
    local global_shortcuts = {
      {key="✦M", desc="Enter Resize Mode"},
      {key="✦T", desc="Enter App Launcher Mode"},
      {key="✦H", desc="Toggle Global Shortcuts"},
      {key="✦R", desc="Reload Configuration"},
      {key="✦Z", desc="Toggle Hammerspoon Console"},
    }

    local yOffset = 85
    local lineHeight = 32
    local columnWidth = (width - padding*2) / 2
    local keyColor = {hex="#007AFF"}  -- macOS blue
    local descColor = {hex="#1d1d1f"}

    local elementIndex = 4
    for i=1, #global_shortcuts do
      local shortcut = global_shortcuts[i]

      -- Determine column
      local column = ((i-1) % 2)
      local xPos = padding + (column * columnWidth)
      local yPos = yOffset + (math.floor((i-1) / 2) * lineHeight)

      -- Key combination (bold, colored)
      global_shortcuts_view[elementIndex] = {
        type = "text",
        text = shortcut.key,
        textFont = ".AppleSystemUIFontBold",
        textSize = 14,
        textColor = keyColor,
        textAlignment = "left",
        frame = {x=xPos, y=yPos, w=80, h=lineHeight}
      }
      elementIndex = elementIndex + 1

      -- Description (regular weight)
      global_shortcuts_view[elementIndex] = {
        type = "text",
        text = shortcut.desc,
        textFont = ".AppleSystemUIFont",
        textSize = 13,
        textColor = descColor,
        textAlignment = "left",
        frame = {x=xPos+85, y=yPos+1, w=columnWidth-90, h=lineHeight}
      }
      elementIndex = elementIndex + 1
    end

    -- Footer hint
    global_shortcuts_view[elementIndex] = {
      type = "text",
      text = "Click anywhere to close",
      textFont = ".AppleSystemUIFont",
      textSize = 11,
      textColor = {white=0.5, alpha=0.8},
      textAlignment = "center",
      frame = {x=padding, y=height-40, w=width-padding*2, h=20}
    }

    global_shortcuts_view:level(hs.canvas.windowLevels.modalPanel)
    global_shortcuts_view:behavior(hs.canvas.windowBehaviors.stationary)
    global_shortcuts_view:clickActivating(false)
    global_shortcuts_view:canvasMouseEvents(true, true)
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
