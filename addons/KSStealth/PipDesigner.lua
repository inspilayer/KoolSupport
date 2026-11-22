-- KS Stealth Pip Designer. Preview uses constant, non-combat 3/5.
-- All controls mutate only persisted visual settings outside combat.
local S=KSStealth
local FONT=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD="|cffffd87a"
local MUTED="|cff9fb4ad"
local function label(parent,str,x,y,w,big)
 local f=parent:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge" or "GameFontNormal")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(str)
 if f.SetFont then pcall(f.SetFont,f,FONT,big and 23 or 16,"") end
 return f
end
local function box(parent,x,y,w,h)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(w,h)
 if f.SetBackdrop then
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  if f.SetBackdropColor then f:SetBackdropColor(.067,.085,.106,.98) end
  if f.SetBackdropBorderColor then f:SetBackdropBorderColor(.43,.34,.22,.8) end
 end
 return f
end
local function button(parent,text,x,y,w,callback)
 local f=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(w,34)
 f:SetText(text);f:SetScript("OnClick",callback)
 if f.GetFontString then
  local t=f:GetFontString()
  if t and t.SetFont then pcall(t.SetFont,t,FONT,14,"") end
 end
 return f
end
local function format(value)
 return type(value)=="number" and string.format("%.2f",value) or tostring(value)
end
function S.BuildDesignerPage(parent)
 local status=label(parent,"",24,-634,890)
 label(parent,GOLD.."PIP DESIGNER  /  KS STEALTH|r",22,-16,910,true)
 label(parent,MUTED.."Design your five combo segments. All changes save per character and appear on the next target.",22,-55,910)
 local previewPanel=box(parent,22,-89,895,135)
 label(previewPanel,GOLD.."LIVE PREVIEW  |  3 OF 5 POINTS|r",16,-14,450)
 label(previewPanel,MUTED.."Preview uses sample points; it never accesses combat values.",16,-104,795)
 local preview=CreateFrame("Frame",nil,previewPanel)
 preview:SetPoint("CENTER",previewPanel,"CENTER",0,-8)
 preview:SetSize(130,20)
 local bars={}
 for i=1,5 do
  local bar=CreateFrame("StatusBar",nil,preview)
  bar:SetMinMaxValues(i-1,i)
  bar:SetValue(3) -- deliberately ordinary preview value
  if bar.CreateTexture then
   bar.backing=bar:CreateTexture(nil,"BACKGROUND")
   bar.backing:SetAllPoints(bar)
   bar.borderArt=bar:CreateTexture(nil,"BACKGROUND",nil,-1)
  end
  bars[i]=bar
 end
 local activeTab="themes"
 local tabs={}
 local bodies={}
 local function refreshPreview()
  local w,h,g=S:PipDimensions()
  preview:SetSize(w*5+g*4,h)
  local style=S:PipStyle()
  for i,bar in ipairs(bars) do
   bar:ClearAllPoints()
   if style.growth=="left" then
    bar:SetPoint("RIGHT",preview,"RIGHT",-(i-1)*(w+g),0)
   else
    bar:SetPoint("LEFT",preview,"LEFT",(i-1)*(w+g),0)
   end
   bar:SetSize(w,h)
   S:StyleComboBar(bar,i)
   if bar.borderArt then
    bar.borderArt:ClearAllPoints()
    bar.borderArt:SetPoint("TOPLEFT",bar,"TOPLEFT",-1,1)
    bar.borderArt:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",1,-1)
   end
  end
 end
 local function refresh()
  refreshPreview()
  for name,b in pairs(tabs) do
   b:SetText(activeTab==name and "[ "..name:upper().." ]" or name:upper())
  end
  for name,body in pairs(bodies) do
   if name==activeTab then body:Show() else body:Hide() end
  end
 end
 local function apply(method,...)
  local ok,why=method(S,...)
  if ok then status:SetText("Saved. Your nameplate combo points will use this style.")
  else status:SetText(why or "Unable to change style.") end
  refresh()
 end
 local nav=box(parent,22,-238,895,51)
 for i,name in ipairs({"themes","geometry","finish"}) do
  tabs[name]=button(nav,name:upper(),13+(i-1)*293,-8,282,function()
   activeTab=name;refresh()
  end)
 end
 local area=box(parent,22,-299,895,321)
 for _,name in ipairs({"themes","geometry","finish"}) do
  bodies[name]=CreateFrame("Frame",nil,area)
  bodies[name]:SetAllPoints(area)
 end
 local themes=bodies.themes
 label(themes,GOLD.."ONE-CLICK STYLES|r",15,-12,420,true)
 local presetOrder={"classic","assassin","jewels","nature","frost","minimal"}
 for i,name in ipairs(presetOrder) do
  button(themes,name:upper(),15+((i-1)%3)*291,-49-math.floor((i-1)/3)*38,280,function()
   apply(S.PresetPips,name)
  end)
 end
 label(themes,GOLD.."COLOR PALETTE|r",15,-133,440,true)
 local colors={"gold","crimson","emerald","violet","frost","silver","ember","rose","toxic"}
 for i,name in ipairs(colors) do
  button(themes,name:upper(),15+((i-1)%3)*291,-171-math.floor((i-1)/3)*38,280,function()
   apply(S.CustomizePips,"palette",name)
  end)
 end
 local geo=bodies.geometry
 label(geo,GOLD.."SIZE & SPACING|r",15,-12,400,true)
 local function stepper(parent,key,title,x,y,step)
  local display=label(parent,"",x,y,145)
  local function sync()
   local style=S:PipStyle()
   display:SetText(title..": "..format(style[key]))
  end
  button(parent,"-",x+157,y+5,56,function()
   apply(S.CustomizePips,key,S:PipStyle()[key]-step);sync()
  end)
  button(parent,"+",x+219,y+5,56,function()
   apply(S.CustomizePips,key,S:PipStyle()[key]+step);sync()
  end)
  sync()
  return sync
 end
 stepper(geo,"width","Width",15,-55,2)
 stepper(geo,"height","Height",455,-55,2)
 stepper(geo,"gap","Spacing",15,-111,1)
 stepper(geo,"offset","Bar offset",455,-111,2)
 label(geo,GOLD.."SEGMENT SHAPE|r",15,-168,300)
 for i,name in ipairs({"bars","slim","square","chunky"}) do
  button(geo,name:upper(),15+(i-1)*218,-195,207,function()
   apply(S.CustomizePips,"shape",name)
  end)
 end
 label(geo,GOLD.."DIRECTION & PLACEMENT|r",15,-245,390)
 button(geo,"LEFT TO RIGHT",395,-240,147,function()apply(S.CustomizePips,"growth","right")end)
 button(geo,"RIGHT TO LEFT",549,-240,148,function()apply(S.CustomizePips,"growth","left")end)
 button(geo,"ABOVE / BELOW",704,-240,177,function()
  local next=S:HUDSettings().hudPlacement=="above" and "below" or "above"
  apply(S.SetHUDPlacement,next)
 end)
 local finish=bodies.finish
 label(finish,GOLD.."FILL TREATMENT|r",15,-12,350,true)
 button(finish,"SMOOTH GRADIENT",15,-49,280,function()apply(S.CustomizePips,"texture","smooth")end)
 button(finish,"SOLID COLOR",310,-49,280,function()apply(S.CustomizePips,"texture","flat")end)
 label(finish,GOLD.."OUTLINE|r",15,-101,360,true)
 for i,name in ipairs({"none","subtle","strong"}) do
  button(finish,name:upper(),15+(i-1)*291,-139,280,function()
   apply(S.CustomizePips,"border",name)
  end)
 end
 stepper(finish,"opacity","Fill opacity",15,-210,.1)
 stepper(finish,"emptyAlpha","Empty opacity",455,-210,.1)
 label(finish,MUTED.."Style changes are visual-only; combo values still go directly into native WoW StatusBars.|r",
  15,-280,870)
 button(parent,"RESET DESIGN",22,-638,180,function()
  apply(S.ResetPipDesign)
 end)
 button(parent,"COMBO SETTINGS",217,-638,180,function()
  KoolSupport:ShowPage("stealth")
 end)
 refresh()
end
