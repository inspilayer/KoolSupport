-- KS Afflictions native settings. Centered DIES is the first, uncluttered mode.
-- DoT tracking is independent of this presentation-only page.
local A=KSAfflictions
local GOLD="|cffffd87a"
local MUTED="|cff9fb4ad"

local function label(parent,text,x,y,w,font)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(w)
  t:SetJustifyH("LEFT")
  t:SetText(text)
  return t
end
local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,31)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(text)
  b:SetScript("OnClick",fn)
  return b
end

function A.BuildPage(parent)
  A:Store()
  label(parent,GOLD.."KS Afflictions|r  - Display Settings",20,-15,775,"GameFontNormalLarge")
  label(parent,"Default: no extra bars or windows. DIES appears only with readable, attributable lethal evidence.",20,-45,780)

  local status=label(parent,"",20,-544,765,"GameFontHighlightSmall")
  label(parent,MUTED.."Secret or unsupported enemy health: hide DIES, never guess. Existing advanced preferences are kept.|r",20,-574,765,"GameFontHighlightSmall")
  local redrawers={}
  local function refresh()
    for _,fn in ipairs(redrawers) do fn() end
  end
  local function choose(key,value)
    local ok,reason=A:ChangeSetting(key,value)
    status:SetText(ok and "Display settings updated." or tostring(reason))
    refresh()
  end

  -- Mode selection stays visible regardless of advanced settings tab.
  label(parent,GOLD.."Display mode|r",20,-81,300,"GameFontNormalLarge")
  local modes={
    {"centered","Centered DIES (default)",20,224},
    {"onframe","On-frame Extras",253,218},
    {"panels","Movable Panels",484,222}
  }
  for _,entry in ipairs(modes) do
    local key,title,x,w=entry[1],entry[2],entry[3],entry[4]
    local b=button(parent,"",x,-109,w,function()choose("displayMode",key)end)
    redrawers[#redrawers+1]=function()
      b:SetText((A:Store().displayMode==key and "> " or "")..title)
    end
  end
  label(parent,"Centered shows only DIES; other modes retain DoT strips, icons, and saved panel positions.",
    20,-145,775,"GameFontHighlightSmall")

  local appearance=CreateFrame("Frame",nil,parent)
  appearance:SetAllPoints(parent)
  local controls=CreateFrame("Frame",nil,parent)
  controls:SetAllPoints(parent)
  local selected="appearance"
  local appearanceTab,controlsTab
  local function selectTab(tab)
    selected=tab
    appearance:SetShown(tab=="appearance")
    controls:SetShown(tab=="controls")
    refresh()
  end
  appearanceTab=button(parent,"Advanced Appearance",20,-177,211,function()
    selectTab("appearance")
  end)
  controlsTab=button(parent,"Visibility & Position",242,-177,250,function()
    selectTab("controls")
  end)
  redrawers[#redrawers+1]=function()
    appearanceTab:SetText((selected=="appearance" and "> " or "").."Advanced Appearance")
    controlsTab:SetText((selected=="controls" and "> " or "").."Visibility & Position")
  end

  local function options(host,title,key,choices,y,width)
    label(host,GOLD..title.."|r",20,y,755,"GameFontNormalLarge")
    for i,choice in ipairs(choices) do
      local id,name=choice[1],choice[2]
      local b=button(host,"",20+(i-1)*width,y-28,width-9,function()choose(key,id)end)
      redrawers[#redrawers+1]=function()
        b:SetText((A:Store()[key]==id and "> " or "")..name)
      end
    end
  end
  options(appearance,"Legacy Bar Appearance","style",{
    {"modern","Modern KS"},{"classic","Classic WoW"},{"minimal","Minimal"}
  },-228,246)
  options(appearance,"Estimated Lethal Indicator","lethalMode",{
    {"dies","DIES"},{"skull","Skull"},{"both","Both"},{"off","Off"}
  },-318,184)
  options(appearance,"DoT Bar Color","dotColor",{
    {"purple","Purple"},{"gold","Gold"},{"red","Red"},{"school","Spell School"}
  },-408,184)
  label(appearance,MUTED.."Appearance and icon options apply to On-frame Extras and Movable Panels, not text-only DIES.|r",20,-493,760,"GameFontHighlightSmall")

  label(controls,GOLD.."Visibility|r",20,-211,755,"GameFontNormalLarge")
  local switches={
    {"target","Target"},{"focus","Focus"},{"nameplates","Nameplates"},
    {"showIcons","Spell Icons"},{"showLabels","Spell Names"},{"lethal","Lethal Detection"},
    {"lethalTarget","Target Alert"},{"lethalFocus","Focus Alert"},{"lethalNameplates","Nameplate Alert"}
  }
  for i,entry in ipairs(switches) do
    local key,title=entry[1],entry[2]
    local col=(i-1)%3
    local row=math.floor((i-1)/3)
    local b=button(controls,"",20+col*246,-239-row*39,230,function()
      choose(key,not A:Store()[key])
    end)
    redrawers[#redrawers+1]=function()
      b:SetText(title..": "..(A:Store()[key] and "ON" or "OFF"))
    end
  end
  label(controls,GOLD.."Size & Position|r",20,-369,755,"GameFontNormalLarge")
  local scale=button(controls,"",20,-398,192,function()
    choose("scale",math.max(.65,A:Store().scale-.1))
  end)
  button(controls,"Bigger",220,-398,108,function()
    choose("scale",math.min(1.65,A:Store().scale+.1))
  end)
  local height=button(controls,"",336,-398,184,function()
    choose("height",math.max(9,A:Store().height-2))
  end)
  button(controls,"Taller",528,-398,107,function()
    choose("height",math.min(25,A:Store().height+2))
  end)
  button(controls,"Up",643,-398,55,function()
    choose("offsetY",math.min(50,A:Store().offsetY+3))
  end)
  button(controls,"Down",705,-398,65,function()
    choose("offsetY",math.max(-20,A:Store().offsetY-3))
  end)
  redrawers[#redrawers+1]=function()
    scale:SetText(string.format("Smaller (%.2fx)",A:Store().scale))
    height:SetText("Shorter ("..A:Store().height.." px)")
  end
  button(controls,"Reset Target",20,-443,145,function()
    local ok,why=A:ResetHUDPosition("target")
    status:SetText(ok and "Target panel returned to its default anchor." or tostring(why))
  end)
  button(controls,"Reset Focus",176,-443,145,function()
    local ok,why=A:ResetHUDPosition("focus")
    status:SetText(ok and "Focus panel returned to its default anchor." or tostring(why))
  end)
  label(controls,"Drag the separate Target/Focus panel titles outside combat. Up/Down adjusts nameplates.",338,-448,434,"GameFontHighlightSmall")

  selectTab("appearance")
end
