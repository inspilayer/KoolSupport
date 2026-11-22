-- KS Stealth: target nameplate combo points. No detached HUD.
local S=KSStealth
local KIT=KoolSupport.UIKit
local FONT=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD="|cffffd87a"
local MUTED="|cff9fb4ad"
local function label(parent,value,x,y,w,big)
 local l=parent:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge" or "GameFontNormal")
 l:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 l:SetWidth(w);l:SetJustifyH("LEFT");l:SetText(value)
 if l.SetFont then pcall(l.SetFont,l,FONT,big and 20 or 14,"") end
 return l
end
local function panel(parent,x,y,w,h)
 if KIT then return KIT:Panel(parent,x,y,w,h) end
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(w,h)
 if f.SetBackdrop then
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  if f.SetBackdropColor then f:SetBackdropColor(.065,.09,.12,.96) end
  if f.SetBackdropBorderColor then f:SetBackdropBorderColor(.46,.35,.19,.9) end
 end
 return f
end
local function button(parent,value,x,y,w,callback)
 if KIT then return KIT:Button(parent,value,x,y,w,callback,"secondary",32) end
 local f=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(w,43)
 f:SetText(value);f:SetScript("OnClick",callback)
 return f
end
function S.BuildPage(parent)
 label(parent,GOLD.."KS STEALTH  /  COMBO POINTS|r",23,-18,900,true)
 label(parent,"One display, attached to the actual overhead health bar of your selected monster.",23,-64,898)
 local settings=panel(parent,22,-115,895,362)
 label(settings,GOLD.."TARGET NAMEPLATE|r",18,-16,800,true)
 label(settings,"Five gold combo segments follow the monster's health bar as it moves.",18,-58,855)
 local status=label(parent,"",23,-503,891)
 local toggle=button(settings,"",18,-108,262,function()end)
 local above=button(settings,"ABOVE HEALTH BAR",297,-108,267,function()end)
 local below=button(settings,"BELOW HEALTH BAR",577,-108,297,function()end)
 local placement=label(settings,"",18,-174,850)
 local size=label(settings,"",18,-215,250)
 button(settings,"- Smaller",297,-208,180,function()
  local ok,why=S:SetHUDScale(S:HUDSettings().hudScale-.1)
  status:SetText(ok and "Combo segments resized." or why)
  size:SetText(string.format("Size: %.1fx",S:HUDSettings().hudScale))
 end)
 button(settings,"+ Larger",493,-208,180,function()
  local ok,why=S:SetHUDScale(S:HUDSettings().hudScale+.1)
  status:SetText(ok and "Combo segments resized." or why)
  size:SetText(string.format("Size: %.1fx",S:HUDSettings().hudScale))
 end)
 button(settings,"RESET TO BELOW",691,-208,183,function()
  local ok,why=S:ResetHUDPosition()
  status:SetText(ok and "Restored below the monster's health bar." or why)
  below:SetText("BELOW HEALTH BAR")
  above:SetText("ABOVE HEALTH BAR")
  placement:SetText("Placement: BELOW the target health bar")
  size:SetText(string.format("Size: %.1fx",S:HUDSettings().hudScale))
 end)
 label(settings,GOLD.."PLAYER ENERGY  /  PROGRESS BAR|r",18,-268,840)
 local energyToggle=button(settings,"",18,-286,246,function()end)
 local energyColor=button(settings,"",278,-286,246,function()end)
 local energySmaller=button(settings,"- ENERGY HEIGHT",538,-286,158,function()end)
 local energyLarger=button(settings,"+ ENERGY HEIGHT",707,-286,165,function()end)
 local energyLabel=label(settings,"",18,-336,849)
 local function syncEnergy()
  local db=S:HUDSettings()
  energyToggle:SetText(db.energyEnabled and "ENERGY BAR: ON" or "ENERGY BAR: OFF")
  energyColor:SetText("ENERGY COLOR: "..(db.energyColor or "gold"):upper())
  energyLabel:SetText("Energy height: "..tostring(db.energyHeight).."  |  Below the five pips on your target's nameplate")
 end
 energyToggle:SetScript("OnClick",function()
  local ok,why=S:SetEnergyEnabled(not S:HUDSettings().energyEnabled)
  status:SetText(ok and "Energy display preference saved." or why)
  syncEnergy()
 end)
 energyColor:SetScript("OnClick",function()
  local order={"gold","lime","amber","cyan"}
  local current=S:HUDSettings().energyColor
  local next=order[1]
  for i,color in ipairs(order) do
   if current==color then next=order[(i%#order)+1];break end
  end
  local ok,why=S:SetEnergyColor(next)
  status:SetText(ok and "Energy color updated." or why)
  syncEnergy()
 end)
 energySmaller:SetScript("OnClick",function()
  local ok,why=S:SetEnergyHeight(S:HUDSettings().energyHeight-2)
  status:SetText(ok and "Energy bar resized." or why)
  syncEnergy()
 end)
 energyLarger:SetScript("OnClick",function()
  local ok,why=S:SetEnergyHeight(S:HUDSettings().energyHeight+2)
  status:SetText(ok and "Energy bar resized." or why)
  syncEnergy()
 end)
 syncEnergy()
 local function refresh()
  local db=S:HUDSettings()
  toggle:SetText(db.hudEnabled and "COMBO DISPLAY: ON" or "COMBO DISPLAY: OFF")
  above:SetText(db.hudPlacement=="above" and "[ ABOVE HEALTH BAR ]" or "ABOVE HEALTH BAR")
  below:SetText(db.hudPlacement=="below" and "[ BELOW HEALTH BAR ]" or "BELOW HEALTH BAR")
  placement:SetText("Placement: "..db.hudPlacement:upper().." the target health bar")
  size:SetText(string.format("Size: %.1fx",db.hudScale))
 end
 toggle:SetScript("OnClick",function()
  local ok,why=S:SetHUDEnabled(not S:HUDSettings().hudEnabled)
  status:SetText(ok and "Target combo point visibility updated." or why)
  refresh()
 end)
 above:SetScript("OnClick",function()
  local ok,why=S:SetHUDPlacement("above")
  status:SetText(ok and "Combo points moved above the health bar." or why)
  refresh()
 end)
 below:SetScript("OnClick",function()
  local ok,why=S:SetHUDPlacement("below")
  status:SetText(ok and "Combo points moved below the health bar." or why)
  refresh()
 end)
 refresh()
 button(parent,"DESIGN PIPS + ENERGY",23,-500,340,function()
  KoolSupport:ShowPage("stealth_designer")
 end)
 button(parent,"RUN COMBO DIAGNOSTICS",381,-500,340,function()
  S:UpdateAll()
  local line=S:ComboDiagnosticText()
  status:SetText(line)
  if type(print)=="function" then print("|cffffd87aKoolSupport|r "..line) end
 end)
 label(parent,GOLD.."HOW TO TEST|r",23,-561,850,true)
 label(parent,"Target a living enemy; build points, then run diagnostics to check the plate and source.",23,-604,893)
 button(parent,"Browse Talent Impacts",23,-645,298,function()
  KoolSupport:ShowPage("stealth_talents")
 end)
 label(parent,MUTED.."Settings save per character. Combat-safe secret points are not read or compared in Lua.|r",
  336,-650,600)
end
