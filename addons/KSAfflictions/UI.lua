-- KS Afflictions native style workshop. Compact, readable, no inner scrolling.
-- DoesItDie's engine remains independent of all these presentation choices.
local A=KSAfflictions
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
  label(parent,"|cffffd87aKS Afflictions|r  — Visual Style",20,-15,760,"GameFontNormalLarge")
  label(parent,"Use compact overlays on target/focus health bars, or keep movable panels. Tracking is unchanged.",20,-46,775)
  local status=label(parent,"",20,-575,770,"GameFontHighlightSmall")
  local redrawers={}
  local function refresh()
    for _,fn in ipairs(redrawers) do fn() end
  end
  local function choose(key,value)
    local ok,reason=A:ChangeSetting(key,value)
    status:SetText(ok and "Display settings updated." or tostring(reason))
    refresh()
  end
  local function options(title,key,choices,y,width)
    label(parent,"|cffffd87a"..title.."|r",20,y,780,"GameFontNormalLarge")
    local left=20
    for _,choice in ipairs(choices) do
      local id,name=choice[1],choice[2]
      local b=button(parent,"",left,y-25,width-7,function()choose(key,id)end)
      redrawers[#redrawers+1]=function()
        b:SetText((A:Store()[key]==id and "> " or "")..name)
      end
      left=left+width
    end
  end
  options("Bar Appearance","style",{
    {"modern","Modern KS"},{"classic","Classic WoW"},{"minimal","Minimal"}
  },-91,246)
  options("Estimated Lethal Indicator","lethalMode",{
    {"dies","DIES"},{"skull","Skull"},{"both","Both"},{"off","Off"}
  },-173,183)
  options("DoT Bar Color","dotColor",{
    {"purple","Purple"},{"gold","Gold"},{"red","Red"},{"school","Spell School"}
  },-255,183)
  label(parent,"|cffffd87aVisibility|r",20,-338,760,"GameFontNormalLarge")
  local switches={
    {"target","Target"},{"focus","Focus"},{"nameplates","Nameplates"},
    {"showIcons","Spell Icons"},{"showLabels","Spell Names"},{"lethal","Lethal Detection"},
    {"lethalTarget","Target Alert"},{"lethalFocus","Focus Alert"},{"lethalNameplates","Nameplate Alert"}
  }
  for i,entry in ipairs(switches) do
    local key,title=entry[1],entry[2]
    local col=(i-1)%3
    local row=math.floor((i-1)/3)
    local b=button(parent,"",20+col*246,-365-row*36,227,function()
      choose(key,not A:Store()[key])
    end)
    redrawers[#redrawers+1]=function()
      b:SetText(title..": "..(A:Store()[key] and "ON" or "OFF"))
    end
  end
  label(parent,"|cffffd87aSize & Position|r",20,-477,770,"GameFontNormalLarge")
  local scale=button(parent,"",20,-504,210,function()
    choose("scale",math.max(.65,A:Store().scale-.1))
  end)
  local big=button(parent,"Bigger",235,-504,110,function()
    choose("scale",math.min(1.65,A:Store().scale+.1))
  end)
  local height=button(parent,"",355,-504,190,function()
    choose("height",math.max(9,A:Store().height-2))
  end)
  button(parent,"Taller",552,-504,102,function()
    choose("height",math.min(25,A:Store().height+2))
  end)
  button(parent,"↑",669,-504,46,function()
    choose("offsetY",math.min(50,A:Store().offsetY+3))
  end)
  button(parent,"↓",720,-504,46,function()
    choose("offsetY",math.max(-20,A:Store().offsetY-3))
  end)
  redrawers[#redrawers+1]=function()
    scale:SetText(string.format("Smaller (%.2fx)",A:Store().scale))
    height:SetText("Shorter ("..A:Store().height.." px)")
  end
  button(parent,"Reset Target",20,-543,145,function()
    local ok,why=A:ResetHUDPosition("target")
    status:SetText(ok and "Target DoTs moved back to its default anchor." or tostring(why))
  end)
  button(parent,"Reset Focus",174,-543,145,function()
    local ok,why=A:ResetHUDPosition("focus")
    status:SetText(ok and "Focus DoTs moved back to its default anchor." or tostring(why))
  end)
  local compact=button(parent,"",333,-543,221,function()
    choose("onFrame",not A:Store().onFrame)
  end)
  redrawers[#redrawers+1]=function()
    compact:SetText("Simplified / On-frame: "..(A:Store().onFrame and "ON" or "OFF"))
  end
  label(parent,"Target + Focus only; if no compatible health bar is found, use the movable HUD.",562,-544,217,"GameFontHighlightSmall")
  refresh()
  label(parent,"|cff9fb4adEstimated damage ≠ guaranteed kill. Protected health stays in WoW StatusBars.|r",20,-604,780,"GameFontHighlightSmall")
end
