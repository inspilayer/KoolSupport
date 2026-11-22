-- Target-only overhead combo point nameplate, secret-safe, no draggable HUD.
SlashCmdList={}
KoolSupportDB={other={untouched=true}}
InCombatLockdown=function()return false end
UnitClass=function()return "Druid","DRUID" end
local SECRET=setmetatable({opaque=true},{__eq=function()error("secret compared")end,
 __lt=function()error("secret compared")end,__tostring=function()error("secret printed")end})
local frames={}
local function frame(kind,parent)
 local f={kind=kind,parent=parent,hidden=false,children={},values={}}
 function f:SetPoint(...)self.anchor={...}end
 function f:ClearAllPoints()self.anchor=nil end
 function f:SetSize(w,h)self.w,self.h=w,h end
 function f:SetFrameLevel(n)self.level=n end
 function f:GetFrameLevel()return 3 end
 function f:CreateTexture()return frame("Texture",self)end
 function f:CreateFontString()return frame("FontString",self)end
 function f:SetStatusBarTexture(path)self.texture=path end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(lo,hi)self.min,self.max=lo,hi end
 function f:SetValue(value)self.values[#self.values+1]=value end
 function f:SetAllPoints()end
 function f:SetColorTexture(...)self.color={...}end
 function f:SetBackdrop()end
 function f:SetBackdropColor()end
 function f:SetBackdropBorderColor()end
 function f:SetFont()end
 function f:SetText(v)self.text=v end
 function f:SetWidth(w)self.w=w end
 function f:SetJustifyH()end
 function f:SetScript(key,fn)self[key]=fn end
 function f:RegisterEvent(e)self.events=self.events or {};self.events[e]=true end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 if parent then parent.children[#parent.children+1]=f end
 frames[#frames+1]=f
 return f
end
UIParent=frame("Frame")
CreateFrame=function(kind,_,parent)return frame(kind,parent)end
local nameplate=frame("Frame",UIParent)
local health=frame("StatusBar",nameplate)
nameplate.UnitFrame={healthBar=health}
local selected=nameplate
C_NamePlate={
 GetNamePlateForUnit=function(unit)assert(unit=="target");return selected end,
 GetNamePlates=function()return {nameplate}end
}
local reads=0
GetComboPoints=function(src,dst)
 assert(src=="player" and dst=="target")
 reads=reads+1
 return SECRET
end
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSStealth/Stealth.lua"))()
assert(loadfile("addons/KSStealth/HUD.lua"))()
KoolSupport:RegisterModule({id="ks_stealth",title="KS Stealth",apiVersion=1,defaultEnabled=true})
local S=KSStealth
S.active=false
S:UpdateAll()
local record=S.plates[nameplate]
assert(record and record.holder.hidden==false and #record.bars==5)
assert(record.holder.anchor[2]==health and record.holder.anchor[3]=="BOTTOM")
for i,bar in ipairs(record.bars) do
 assert(bar.min==i-1 and bar.max==i)
 assert(bar.values[#bar.values]==SECRET,"opaque combo points must reach native status bars")
end
assert(reads>0)
-- Simulate the Forever client not sending UNIT_COMBO_POINTS after a builder.
-- Only the OnUpdate safety net should refresh the native bars.
local eventFrame
for _,widget in ipairs(frames) do
 if widget.OnUpdate and widget.OnEvent then eventFrame=widget;break end
end
assert(eventFrame and eventFrame.OnUpdate,"combo fallback must register OnUpdate")
local originalReads=reads
eventFrame.OnUpdate(eventFrame,.10)
assert(reads==originalReads,"refresh must be throttled")
eventFrame.OnUpdate(eventFrame,.06)
assert(reads==originalReads+1,"combo bars must update without any event or manual /kool combo")
assert(S.comboHealth.ticks==1 and S.comboHealth.autoUpdates==1)
-- Forever can return nil for C_NamePlate.GetNamePlateForUnit("target")
-- during combat, even though the current target and plate remain valid.
-- The already verified plate must keep receiving the opaque combo value.
local prior=S.comboHealth.autoUpdates
selected=nil
eventFrame.OnUpdate(eventFrame,.16)
assert(S.comboHealth.autoUpdates==prior+1,
 "temporary combat nameplate lookup failure must use the verified cached plate")
assert(not record.holder.hidden,"cached target remains visible during temporary lookup failure")
selected=nameplate
eventFrame.OnUpdate(eventFrame,.16)
assert(S.comboHealth.autoUpdates==prior+2)
-- A real target change invalidates the cached identity; never show prior target.
S:OnEvent("PLAYER_TARGET_CHANGED")
selected=nil
eventFrame.OnUpdate(eventFrame,.16)
assert(record.holder.hidden,"cannot use a cached plate after target changes")
selected=nameplate
eventFrame.OnUpdate(eventFrame,.16)
assert(not record.holder.hidden,"freshly resolved target restores points")
local readBeforeStatus=reads
local healthText=S:ComboHealthText()
assert(healthText:find("ticks=1",1,true) and healthText:find("auto-updates=1",1,true))
assert(reads==readBeforeStatus,"status must not trigger a refresh")
assert(record.bars[1].values[#record.bars[1].values]==SECRET)
-- On nameplate removal, the cache must not survive recycling.
S:OnEvent("PLAYER_TARGET_CHANGED")
selected=nil
eventFrame.OnUpdate(eventFrame,.16)
assert(record.holder.hidden,"target loss after explicit target event hides the previous nameplate")
selected=nameplate
eventFrame.OnUpdate(eventFrame,.16)
assert(not record.holder.hidden,"freshly reacquired target restores pips")
assert(S:HUDSettings().hudPlacement=="below")
assert(S:SetHUDPlacement("above"))
assert(record.holder.anchor[2]==health and record.holder.anchor[1]=="BOTTOM")
assert(S:SetHUDPlacement("below"))
assert(record.holder.anchor[1]=="TOP")
assert(S:SetHUDScale(1.3))
assert(record.bars[1].w>19)
assert(S:ResetHUDPosition())
assert(S:HUDSettings().hudScale==1 and S:HUDSettings().hudPlacement=="below")
assert(S:SetHUDEnabled(false))
assert(record.holder.hidden)
assert(S:SetHUDEnabled(true))
assert(not record.holder.hidden)
selected=nil
S:UpdateAll()
assert(record.holder.hidden,"no selected visible nameplate must hide points")
InCombatLockdown=function()return true end
assert(not S:SetHUDPlacement("above"))
assert(not S:SetHUDScale(1.5))
assert(not S:SetHUDEnabled(false))
assert(not S:ResetHUDPosition())
InCombatLockdown=function()return false end
assert(loadfile("addons/KSStealth/UI.lua"))()
local parent=frame("Frame",UIParent)
S.BuildPage(parent)
local above,below
for _,widget in ipairs(frames) do
 if widget.kind=="Button" and widget.text=="ABOVE HEALTH BAR" then above=widget end
 if widget.kind=="Button" and (widget.text=="[ BELOW HEALTH BAR ]" or widget.text=="BELOW HEALTH BAR") then below=widget end
end
assert(above and below and above.OnClick and below.OnClick)
above.OnClick(above)
assert(S:HUDSettings().hudPlacement=="above")
below.OnClick(below)
assert(S:HUDSettings().hudPlacement=="below")
assert(KoolSupportDB.other.untouched)
print("PASS target-nameplate HUD: five native secret-safe bars, placement, scale, toggles, combat")
