-- Simulated Forever nameplates: combo points may be opaque secret values.
SlashCmdList={}
InCombatLockdown=function()return false end
UnitClass=function()return 'Rogue','ROGUE' end
local sample={id='secret'}
local SECRET=setmetatable(sample,{
 __eq=function() error('Lua read/comparison of a secret value!') end,
 __lt=function() error('Lua read/comparison of a secret value!') end,
 __le=function() error('Lua read/comparison of a secret value!') end,
 __tostring=function()error('Lua formatting secret value!')end,
})
local frames={}
local function makeFrame(parent)
 local f={parent=parent,hidden=false,values={},children={}}
 function f:SetSize(w,h)self.w=w;self.h=h end
 function f:SetPoint(...)self.anchors={...}end
 function f:ClearAllPoints()self.anchors=nil end
 function f:SetFrameLevel(i)self.level=i end
 function f:GetFrameLevel()return 1 end
 function f:SetStatusBarTexture(t)self.texture=t end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(a,b)self.min=a;self.max=b end
 function f:SetValue(x) self.values[#self.values+1]=x end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:RegisterEvent(evt)self.events=self.events or {};self.events[evt]=true end
 function f:SetScript(evt,cb)self.scripts=self.scripts or {};self.scripts[evt]=cb end
 if parent then parent.children[#parent.children+1]=f end
 frames[#frames+1]=f
 return f
end
CreateFrame=function(_,_,parent) return makeFrame(parent) end
assert(loadfile('addons/KoolSupport/Core.lua'))()
local styled=0
KoolSupport.BarTheme={StyleBar=function(_,bar,role)
  assert(role=="bleed")
  styled=styled+1
  bar:SetStatusBarTexture("Interface\\\\Buttons\\\\WHITE8X8")
  bar:SetStatusBarColor(.94,.34,.4,1)
 end}
local p1=makeFrame(nil);p1.namePlateUnitToken='nameplate1'
local p2=makeFrame(nil);p2.namePlateUnitToken='nameplate2'
local plates={["nameplate1"]=p1,["nameplate2"]=p2}
C_NamePlate={
 GetNamePlates=function()return {p1,p2}end,
 GetNamePlateForUnit=function(unit)return plates[unit]end,
}
local calls={}
GetComboPoints=function(player,unit)
 assert(player=='player');calls[unit]=(calls[unit] or 0)+1
 return SECRET
end
assert(loadfile('addons/KSStealth/Stealth.lua'))()
assert(loadfile('addons/KSStealth/TalentImpactData.lua'))()
assert(loadfile('addons/KSStealth/UI.lua'))()
assert(loadfile('addons/KSStealth/TalentImpactUI.lua'))()
assert(loadfile('addons/KSStealth/Module.lua'))()
local S=KSStealth
S:OnEvent('PLAYER_LOGIN')
assert(calls.nameplate1 and calls.nameplate2,'must update ALL visible nameplate units')
assert(styled==10,'Stealth must use shared KS bar theme on all ten segments')
assert(#S.plates[p1].bars==5 and #S.plates[p2].bars==5)
for _,b in ipairs(S.plates[p1].bars) do
 assert(b.values[#b.values]==SECRET,'secret passes through to StatusBar with no Lua math')
end
assert(S.plates[p1].bars[1].min==0 and S.plates[p1].bars[1].max==1)
assert(S.plates[p1].bars[5].min==4 and S.plates[p1].bars[5].max==5)
S:OnEvent('NAME_PLATE_UNIT_REMOVED','nameplate1')
assert(S.plates[p1].holder.hidden)
assert(KoolSupport:SetModuleEnabled('ks_stealth',false))
assert(S.plates[p2].holder.hidden)
assert(not KoolSupport:CanOpenPage('stealth'))
assert(KoolSupport:SetModuleEnabled('ks_stealth',true))
assert(KoolSupport:CanOpenPage('stealth'))
assert(S:SetNameplates(false))
assert(S.plates[p2].holder.hidden)
InCombatLockdown=function()return true end
local ok=S:SetNameplates(true)
assert(not ok,'combat blocks display setting toggles')
print('PASS stealth: multi-nameplate, secret passthrough, removal, toggles, combat')
