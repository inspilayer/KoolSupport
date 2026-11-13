-- Minimal, tank-first threat color options. No standalone nameplate framework.
local A=KSThreat
local GOLD="|cffffd87a"
local MUTED="|cff9fb4ad"
local function label(parent,text,x,y,w,font)
 local l=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
 l:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 l:SetWidth(w)
 l:SetJustifyH("LEFT")
 l:SetText(text)
 return l
end
local function button(parent,text,x,y,w,cb)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,34)
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(text)
 b:SetScript("OnClick",cb)
 return b
end
function A.BuildPage(parent)
 A:Store()
 label(parent,GOLD.."KS Threat|r  - Tank Nameplate Colors",20,-20,770,"GameFontNormalLarge")
 label(parent,"One lightweight color layer on Blizzard enemy nameplates. No ThreatPlates required.",20,-57,765)
 label(parent,"Enable KS Threat in Modules to activate this character's tank palette.",20,-83,765,"GameFontHighlightSmall")
 local status=label(parent,"",20,-570,765,"GameFontHighlightSmall")
 local settings=A:Store()
 local function toggle(key,btn,title)
  local ok,reason=A:ChangeSetting(key,not A:Store()[key])
  status:SetText(ok and "Threat display setting updated." or tostring(reason))
  btn:SetText(title..": "..(A:Store()[key] and "ON" or "OFF"))
 end
 local combat
 combat=button(parent,"",20,-130,285,function()toggle("onlyCombat",combat,"Only in combat")end)
 combat:SetText("Only in combat: "..(settings.onlyCombat and "ON" or "OFF"))
 local purple
 purple=button(parent,"",323,-130,285,function()toggle("purpleNoThreat",purple,"Purple for no threat")end)
 purple:SetText("Purple for no threat: "..(settings.purpleNoThreat and "ON" or "OFF"))
 label(parent,GOLD.."Tank palette (4 threat states)|r",20,-204,700,"GameFontNormalLarge")
 local rows={
  {3,"RED","You have aggro"},
  {2,"PINK","High threat, not securely tanking"},
  {1,"VIOLET","Some threat, but not tanking"},
  {0,"PURPLE","Little or no threat"},
 }
 for i,entry in ipairs(rows) do
  local c=A.COLORS[entry[1]]
  local y=-242-(i-1)*55
  local swatch=CreateFrame("StatusBar",nil,parent)
  swatch:SetSize(138,22)
  swatch:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y)
  swatch:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  swatch:SetMinMaxValues(0,1)
  swatch:SetValue(1)
  swatch:SetStatusBarColor(c[1],c[2],c[3],1)
  label(parent,entry[2],175,y-1,102,"GameFontNormal")
  label(parent,entry[3],293,y-1,435,"GameFontHighlightSmall")
 end
 label(parent,MUTED.."Threat states are categorical, not a precise percentage meter.",20,-465,765,"GameFontHighlightSmall")
 local summary=label(parent,"",325,-504,460,"GameFontHighlightSmall")
 local details=label(parent,"",20,-545,765,"GameFontHighlightSmall")
 local function inspect()
  local first,second=A:DiagnosticText()
  summary:SetText(first)
  details:SetText(second)
 end
 button(parent,"Diagnose visible plates",20,-493,293,inspect)
 inspect()
end
