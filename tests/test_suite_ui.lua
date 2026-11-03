-- Mock the actual Macro Suite UI: class-aware icon selection and locked learned requirements.
SlashCmdList={}
InCombatLockdown=function()return false end
KoolSupportDB={}
UnitClass=function()return "Druid","DRUID" end
local widgets={}
local function mk(kind)
  local f={kind=kind,scripts={},shown=true,checked=false,enabled=true}
  function f:SetPoint(...)self.point={...}end
  function f:SetSize(w,h)self.width=w;self.height=h end
  function f:SetWidth(w)self.width=w end
  function f:SetText(x)self.text=x end
  function f:GetText()return self.text end
  function f:SetJustifyH()end
  function f:SetTexture(x)self.texture=x end
  function f:SetTexCoord(...)self.coords={...}end
  function f:SetShown(x)self.shown=x end
  function f:Show()self.shown=true end
  function f:Hide()self.shown=false end
  function f:SetChecked(x)self.checked=x end
  function f:GetChecked()return self.checked end
  function f:SetEnabled(x)self.enabled=x end
  function f:SetScript(name,cb)self.scripts[name]=cb end
  function f:CreateFontString()return mk("text")end
  function f:CreateTexture()return mk("icon")end
  widgets[#widgets+1]=f
  return f
end
CreateFrame=function(kind)return mk(kind)end
local parent=mk("parent")
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSMacros/Engine.lua"))()
assert(loadfile("addons/KSMacros/ClassPresets.lua"))()
local M=KSMacros
local spellbook={}
for _,entry in ipairs(M:GetRecommended()) do
 if entry.spell~="Entangling Roots" then
   for _,name in ipairs(entry.requires) do spellbook[name]={spellID=201} end
 end
end
M.KnownSpellIndex=function()return spellbook end
C_Spell={GetSpellTexture=function(id)return 888 end}
M.ScanSpellbook=function()return {} end
local installed
M.InstallBatch=function(_,batch)installed=batch;return true,"Installed" end
assert(loadfile("addons/KSMacros/Suite.lua"))()
M.BuildSuite(parent)
local install,check,locked,icons,buttons
buttons={}
for _,w in ipairs(widgets) do
 if w.kind=="Button" then buttons[#buttons+1]=w end
 if w.kind=="icon" and w.shown then icons=(icons or 0)+1 end
 if w.text=="Install selected" then install=w end
 if type(w.text)=="string" and w.text:find("Locked",1,true) then locked=w end
 if w.kind=="CheckButton" and w.shown and w.enabled and not check then check=w end
end
assert(install and install.scripts.OnClick,"Install control missing")
assert(icons and icons>=5,"Class spell icons missing from visible rows")
assert(locked,"Unlearned template should be visually locked")
for i,w in ipairs(widgets) do if w.kind=="CheckButton" then print("CHECK",i,tostring(w.shown),tostring(w.enabled),tostring(w.scripts.OnClick)) end end
assert(check and check.scripts.OnClick)
check.checked=true
check.scripts.OnClick(check)
install.scripts.OnClick()
assert(installed and #installed==1 and installed[1].name:match("^KSR%-D%-"),"Selected class template not in batch")
assert(installed[1].icon==888,"Learned spell icon should reach installer")
print("PASS suite UI: class-specific icon, learned lock, explicit install")
