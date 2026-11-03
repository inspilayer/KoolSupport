-- Sprint 1 talent impact catalog and read-only hover page.
SlashCmdList={}
InCombatLockdown=function()return false end
local class="DRUID"
UnitClass=function()return "Druid",class end
local frames={}
local function frame(kind,parent)
  local f={kind=kind,parent=parent,hidden=false,fonts={},textures={}}
  function f:SetSize(w,h)self.width=w;self.height=h end
  function f:SetPoint(...)self.point={...}end
  function f:SetWidth(w)self.width=w end
  function f:SetJustifyH(value)self.justify=value end
  function f:SetText(value)self.text=value end
  function f:SetTexture(value)self.texture=value end
  function f:Show()self.hidden=false end
  function f:Hide()self.hidden=true end
  function f:SetScript(name,fn)self.scripts=self.scripts or {};self.scripts[name]=fn end
  function f:RegisterEvent()end
  function f:CreateFontString()
    local text=frame("FontString",self)
    self.fonts[#self.fonts+1]=text
    return text
  end
  function f:CreateTexture()
    local tex=frame("Texture",self)
    self.textures[#self.textures+1]=tex
    return tex
  end
  frames[#frames+1]=f
  return f
end
CreateFrame=function(kind,_,parent) return frame(kind,parent) end
GetSpellTexture=function(name)
  if name=="Lacerate" then error("Client texture unavailable") end
  return "ICON:"..name
end
assert(loadfile("addons/KoolSupport/Core.lua"))()
KoolSupport.ShowPage=function(_,page)KoolSupport.lastPage=page end
assert(loadfile("addons/KSStealth/Stealth.lua"))()
assert(loadfile("addons/KSStealth/TalentImpactData.lua"))()
assert(loadfile("addons/KSStealth/UI.lua"))()
assert(loadfile("addons/KSStealth/TalentImpactUI.lua"))()
assert(loadfile("addons/KSStealth/Module.lua"))()
local S=KSStealth
local db=S:Store()
assert(db.talentImpactOverlay==false,"opt-in must default OFF")
assert(#S:GetTalentImpactCatalog("DRUID")==3)
assert(#S:GetTalentImpactCatalog("ROGUE")==4)
assert(#S:GetTalentImpactCatalog("PRIEST")==0)
local sf=S:GetTalentImpactById("DRUID","savage_fury")
assert(sf and sf.maxRank==2)
assert(table.concat(sf.abilities,",")=="Claw,Rake,Shred,Maul,Swipe")
local fr=S:GetTalentImpactById("DRUID","ferocity")
assert(fr and table.concat(fr.abilities,",")=="Maul,Primal Bite,Swipe,Claw,Rake")
local shredding=S:GetTalentImpactById("DRUID","shredding_attacks")
assert(shredding and shredding.abilities[2]=="Lacerate")
assert(S:GetTalentImpactById("ROGUE","savage_fury")==nil,"never cross class catalogs")
local efficient=S:GetTalentImpactById("ROGUE","efficient_strikes")
assert(efficient and efficient.abilities[2]=="Hemorrhage")
local coup=S:GetTalentImpactById("ROGUE","coup_de_grace")
assert(coup and coup.abilities[2]=="Death Mark")
assert(S:GetTalentImpactById("ROGUE",false)==nil)
assert(S:TalentAbilityIcon("Claw")=="ICON:Claw")
assert(S:TalentAbilityIcon("Lacerate")=="Interface\\Icons\\INV_Misc_QuestionMark","texture error falls back")

local page=frame("Frame")
S.BuildTalentPage(page)
assert(#frames>0)
local toggle
for _,f in ipairs(frames) do
  if f.kind=="Button" and f.text=="Talent previews: OFF" then toggle=f end
end
assert(toggle and toggle.scripts.OnClick,"OFF page offers opt-in")
toggle.scripts.OnClick()
assert(db.talentImpactOverlay==true and KoolSupport.lastPage=="stealth_talents")
S:Store().talentImpactOverlay=true
local panel=frame("Frame")
S.BuildTalentPage(panel)
local savage
for _,f in ipairs(frames) do
  if f.kind=="Button" and f.text and f.text:find("Savage Fury",1,true) then savage=f end
end
assert(savage and savage.scripts.OnEnter and savage.scripts.OnLeave)
savage.scripts.OnEnter()
local detail,affected={},{}
for _,f in ipairs(frames) do
  if f.kind=="FontString" then
    if f.text and f.text:find("Savage Fury",1,true) then detail[#detail+1]=f.text end
    if f.text=="Shred" then affected[#affected+1]=f end
  end
end
assert(#detail>=1 and #affected>=1,"hover should draw affected ability list")
savage.scripts.OnLeave()
assert(S:GetTalentImpactById("DRUID","savage_fury").name=="Savage Fury")

-- Saved data and combat safety.
db.talentImpactOverlay=true
db.unknownCustomSetting={kept=true}
InCombatLockdown=function()return true end
local ok=S:SetTalentImpactOverlay(false)
assert(ok==false and db.talentImpactOverlay==true and db.unknownCustomSetting.kept)
InCombatLockdown=function()return false end
assert(S:SetTalentImpactOverlay(false) and db.talentImpactOverlay==false)
class="MAGE"
local unsupported=frame("Frame")
S.BuildTalentPage(unsupported)
assert(#S:GetTalentImpactCatalog()==0)
assert(KoolSupport:CanOpenPage("stealth_talents"))
assert(KoolSupport:SetModuleEnabled("ks_stealth",false))
assert(not KoolSupport:CanOpenPage("stealth_talents"),"plugin disable gates talent page")
print("PASS talent impacts: two-class catalogs, hover UI, opt-in, persistence, module and combat gates")
