-- KS Afflictions UI: clear everyday controls; advanced details stay in their own view.
-- Native WoW controls only; no protected actions or DoT data in configuration.
local A=KSAfflictions
local GOLD="|cffffd87a"
local GREEN="|cff9de4b3"
local MUTED="|cff9fb4ad"

local function label(parent,txt,x,y,width,font)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(width)
  t:SetJustifyH("LEFT")
  t:SetText(txt)
  return t
end
local function button(parent,txt,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,29)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(txt)
  b:SetScript("OnClick",fn)
  return b
end
local function check(parent,txt,x,y,key,value,fn)
  local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
  c:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  c:SetSize(26,26)
  c.ksKey=key
  c.ksValue=value
  c.ksTitle=txt
  label(parent,txt,x+32,y-3,190,"GameFontHighlight")
  c:SetScript("OnClick",fn)
  return c
end
local function separator(parent,y)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetColorTexture(.39,.32,.17,.52)
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y)
  t:SetSize(760,1)
end

function A.BuildPage(parent)
  A:Store()
  label(parent,GOLD.."KS Afflictions|r",20,-17,340,"GameFontNormalLarge")
  label(parent,MUTED.."Clean display for damage-over-time finishers",20,-49,700)
  separator(parent,-80)

  local feedback=label(parent,"",20,-552,770,"GameFontHighlightSmall")
  local foot=label(parent,MUTED.."During combat: /kool dies prints the tracker's evidence and rejection reason (no secret health).|r",
    20,-574,775,"GameFontHighlightSmall")
  local active=label(parent,"",420,-22,368,"GameFontHighlightSmall")
  local normal=CreateFrame("Frame",nil,parent)
  normal:SetAllPoints(parent)
  local advanced=CreateFrame("Frame",nil,parent)
  advanced:SetAllPoints(parent)
  local activeView="normal"
  local redrawers={}
  local function refresh()
    for _,f in ipairs(redrawers) do f() end
  end
  local function choose(key,value)
    local ok,why=A:ChangeSetting(key,value)
    feedback:SetText(ok and GREEN.."Saved|r" or "|cffff9486"..tostring(why).."|r")
    refresh()
  end
  local function view(name)
    activeView=name
    normal:SetShown(name=="normal")
    advanced:SetShown(name=="advanced")
    refresh()
  end
  redrawers[#redrawers+1]=function()
    local names={centered="DIES only",onframe="On-frame extras",panels="Movable panels"}
    active:SetText(GREEN.."Active: "..(names[A:Store().displayMode] or "Unknown").."|r")
  end

  -- Default view: 3 native radio-like choices, 4 checkboxes, one action.
  label(normal,GOLD.."Display|r",20,-103,250,"GameFontNormalLarge")
  label(normal,"Choose one layout",20,-129,650,"GameFontHighlightSmall")
  local layouts={
    {"centered","DIES only",20},
    {"onframe","On-frame extras",278},
    {"panels","Movable panels",535},
  }
  for _,entry in ipairs(layouts) do
    local value,name,x=entry[1],entry[2],entry[3]
    local c=check(normal,name,x,-161,"displayMode",value,function()choose("displayMode",value)end)
    redrawers[#redrawers+1]=function()c:SetChecked(A:Store().displayMode==value)end
  end
  label(normal,MUTED.."DIES only adds text inside the original health bar. No second bars, icons or windows.|r",
    20,-212,760,"GameFontHighlightSmall")
  separator(normal,-247)
  label(normal,GOLD.."Where to show it|r",20,-269,340,"GameFontNormalLarge")
  local mainToggles={
    {"target","Target",20,-307},
    {"focus","Focus",278,-307},
    {"nameplates","Enemy nameplates",535,-307},
    {"lethal","Enable DIES indicator",20,-350},
  }
  for _,entry in ipairs(mainToggles) do
    local key,txt,x,y=entry[1],entry[2],entry[3],entry[4]
    local c=check(normal,txt,x,y,key,nil,function()choose(key,not A:Store()[key])end)
    redrawers[#redrawers+1]=function()c:SetChecked(A:Store()[key])end
  end
  separator(normal,-400)
  label(normal,GOLD.."Client support|r",20,-416,300,"GameFontNormalLarge")
  local detail=label(normal,"",20,-441,755,"GameFontHighlightSmall")
  redrawers[#redrawers+1]=function()
    local supported=A.SecretCurveSupported and A:SecretCurveSupported()
    local last=A.minimalReasons and A.minimalReasons.target
    if supported then
      detail:SetText(GREEN.."Native secret-health curves found|r"..
        (last and "  |  Last render: "..last or "  |  Live combat confirmation needed"))
    else
      detail:SetText("|cffffbd8bSecret-health curve API unavailable|r; text hides when health is protected")
    end
  end
  local trackerLine=label(normal,"",20,-469,775,"GameFontHighlightSmall")
  redrawers[#redrawers+1]=function()
    if type(A.DiagnosticLine)=="function" then
      trackerLine:SetText(A:DiagnosticLine("target"))
    else
      trackerLine:SetText("Tracker diagnostics unavailable")
    end
  end
  button(normal,"Refresh display check",20,-503,217,function()
    if A.RefreshAll then A:RefreshAll() end
    refresh()
  end)
  button(normal,"Advanced settings",258,-503,194,function()view("advanced")end)

  -- Advanced options: a separate page, not 25 simultaneous option buttons.
  button(advanced,"< Back to simple settings",20,-105,240,function()view("normal")end)
  label(advanced,GOLD.."Advanced appearance|r",20,-158,390,"GameFontNormalLarge")
  label(advanced,MUTED.."These options mainly affect the two extra-bar layouts.|r",
    20,-185,750,"GameFontHighlightSmall")
  local function cycle(key,choices,txt,x,y,w)
    local b=button(advanced,"",x,y,w,function()
      local db=A:Store()
      local idx=1
      for i,v in ipairs(choices) do if v[1]==db[key] then idx=i;break end end
      local nextChoice=choices[idx%#choices+1][1]
      choose(key,nextChoice)
    end)
    redrawers[#redrawers+1]=function()
      local current=A:Store()[key]
      local value="Unknown"
      for _,choice in ipairs(choices) do if choice[1]==current then value=choice[2] end end
      b:SetText(txt..": "..value)
    end
  end
  cycle("style",{{"modern","Modern"},{"classic","Classic"},{"minimal","Minimal"}},"Bar style",20,-217,235)
  cycle("dotColor",{{"purple","Purple"},{"gold","Gold"},{"red","Red"},{"school","School"}},"DoT color",270,-217,235)
  cycle("lethalMode",{{"dies","DIES"},{"skull","Skull"},{"both","Both"},{"off","Off"}},"Alert",520,-217,225)
  local advancedToggles={
    {"showIcons","Spell icons",20,-279},
    {"showLabels","Spell names",275,-279},
    {"lethalTarget","Target alert",530,-279},
    {"lethalFocus","Focus alert",20,-326},
    {"lethalNameplates","Nameplate alert",275,-326},
    {"schoolColors","School colors",530,-326},
  }
  for _,entry in ipairs(advancedToggles) do
    local key,txt,x,y=entry[1],entry[2],entry[3],entry[4]
    local c=check(advanced,txt,x,y,key,nil,function()choose(key,not A:Store()[key])end)
    redrawers[#redrawers+1]=function()c:SetChecked(A:Store()[key])end
  end
  separator(advanced,-375)
  label(advanced,GOLD.."Saved layout adjustments|r",20,-397,390,"GameFontNormalLarge")
  local size=button(advanced,"",20,-438,245,function()
    choose("scale",math.min(1.65,A:Store().scale+.1))
  end)
  local offset=button(advanced,"",278,-438,245,function()
    choose("offsetY",math.min(50,A:Store().offsetY+3))
  end)
  redrawers[#redrawers+1]=function()
    size:SetText(string.format("Increase size  (%.2fx)",A:Store().scale))
    offset:SetText("Move nameplates up  ("..A:Store().offsetY..")")
  end
  button(advanced,"Reset Target",20,-489,153,function()
    local ok,why=A:ResetHUDPosition("target")
    feedback:SetText(ok and "Target panel reset" or tostring(why))
  end)
  button(advanced,"Reset Focus",190,-489,153,function()
    local ok,why=A:ResetHUDPosition("focus")
    feedback:SetText(ok and "Focus panel reset" or tostring(why))
  end)
  label(advanced,MUTED.."Existing size, offsets and panel positions remain saved. WoW combat blocks setting changes.|r",
    362,-494,418,"GameFontHighlightSmall")
  view("normal")
end
