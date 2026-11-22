-- Target-only overhead combo point nameplate, secret-safe, no draggable HUD.
SlashCmdList={}
KoolSupportDB={other={untouched=true}}
InCombatLockdown=function()return false end
UnitClass=function()return "Druid","DRUID" end
local SECRET=setmetatable({opaque=true},{__eq=function()error("secret compared")end,
 __lt=function()error("secret compared")end,__tostring=function()error("secret printed")end})
local function opaque()
 return setmetatable({energy=true},{
  __eq=function()error("energy value compared")end,
  __lt=function()error("energy value compared")end,
  __le=function()error("energy value compared")end,
  __add=function()error("energy value added")end,
  __div=function()error("energy value divided")end,
  __tostring=function()error("energy value printed")end,
 })
end
local energyNow,energyMax=opaque(),opaque()
local powerKind=3
UnitPowerType=function(unit)assert(unit=="player");return powerKind end
UnitPower=function(unit,power)assert(unit=="player" and power==3);return energyNow end
UnitPowerMax=function(unit,power)assert(unit=="player" and power==3);return energyMax end
local frames={}
local function frame(kind,parent)
 local f={kind=kind,parent=parent,hidden=false,children={},values={}}
 function f:SetPoint(...)self.anchor={...};self.anchorCalls=(self.anchorCalls or 0)+1 end
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
 function f:RegisterEvent(e)
  if e=="UNIT_COMBO_POINTS" then error("Event does not exist in Forever") end
  self.events=self.events or {};self.events[e]=true
 end
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
assert(loadfile("addons/KSStealth/PipDesigner.lua"))()
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
-- Keeping a resolved nameplate must never re-anchor it every 150ms.
local firstAnchorCalls=record.holder.anchorCalls
S:UpdateAll()
S:UpdateAll()
assert(record.holder.anchorCalls==firstAnchorCalls,"stable targets must not re-anchor on refresh")
-- The outer nameplate may survive a Blizzard healthBar replacement.
local replacementHealth=frame("StatusBar",nameplate)
nameplate.UnitFrame.healthBar=replacementHealth
S:UpdateAll()
assert(record.holder.anchor[2]==replacementHealth,"recycled nameplate must follow the new health bar")
assert(record.holder.anchorCalls==firstAnchorCalls+1,"refresh should correct changed healthBar only once")
S:UpdateAll()
assert(record.holder.anchorCalls==firstAnchorCalls+1,"no repeated positioning after healthBar swap")
assert(record.energyBar,"Energy progress bar should exist under target pips")
assert(record.energyBar.anchor[1]=="TOP" and record.energyBar.anchor[2]==record.holder
 and record.energyBar.anchor[3]=="BOTTOM","energy should stack below combo pips")
assert(rawequal(record.energyBar.max,energyMax),"native bar must receive opaque maximum unchanged")
assert(rawequal(record.energyBar.values[#record.energyBar.values],energyNow),
 "native bar must receive opaque current energy unchanged")
assert(not record.energyBar.hidden,"energy defaults visible when player has energy power type")
assert(S:Store().energyEnabled)
assert(S:SetEnergyHeight(14))
assert(S:Store().energyHeight==14)
assert(record.energyBar.h==14)
assert(S:SetEnergyColor("cyan"))
assert(S:Store().energyColor=="cyan")
assert(record.energyBar.color[3]>.9)
assert(S:SetEnergyEnabled(false))
assert(record.energyBar.hidden)
assert(S:SetEnergyEnabled(true))
assert(not record.energyBar.hidden)
powerKind=0 -- Caster or bear: no energy bar below target.
S:UpdateAll()
assert(record.energyBar.hidden,"non-energy forms must hide bar")
powerKind=3
S:UpdateAll()
assert(not record.energyBar.hidden,"cat form restores progress bar")
assert(not S:SetEnergyColor("invalid"))
assert(not S:SetEnergyHeight("big"))
-- Simulate the Forever client not sending UNIT_COMBO_POINTS after a builder.
-- Only the OnUpdate safety net should refresh the native bars.
local eventFrame
for _,widget in ipairs(frames) do
 if widget.OnUpdate and widget.OnEvent then eventFrame=widget;break end
end
assert(eventFrame and eventFrame.OnUpdate,"combo fallback must register OnUpdate")
assert(type(S.ComboHealthText)=="function","one rejected event must not truncate the script")
assert(S:ComboHealthText():find("rejected%-events=UNIT_COMBO_POINTS"),"unsupported event must be reported")
local originalReads=reads
eventFrame.OnUpdate(eventFrame,.10)
assert(reads==originalReads,"refresh must be throttled")
eventFrame.OnUpdate(eventFrame,.06)
assert(reads==originalReads+1,"combo bars must update without any event or manual /kool combo")
assert(S.comboHealth.ticks==1 and S.comboHealth.autoUpdates==1)
local readBeforeStatus=reads
local healthText=S:ComboHealthText()
assert(healthText:find("ticks=1",1,true) and healthText:find("auto-updates=1",1,true))
assert(reads==readBeforeStatus,"status must not trigger a refresh")
assert(record.bars[1].values[#record.bars[1].values]==SECRET)
selected=nil
eventFrame.OnUpdate(eventFrame,.16)
assert(record.holder.hidden,"target loss must automatically hide display without manual refresh")
selected=nameplate
eventFrame.OnUpdate(eventFrame,.16)
assert(not record.holder.hidden,"target reappearance must automatically restore pips")
-- Design changes cannot modify protected combo values or automatic refresh.
local firstRecord=record
local before=firstRecord.bars[1].values[#firstRecord.bars[1].values]
assert(S:PresetPips("jewels"))
assert(S:PipStyle().shape=="square")
assert(S:PipStyle().palette=="violet")
assert(S:CustomizePips("width",24))
assert(S:CustomizePips("height",20))
assert(S:CustomizePips("gap",9))
assert(S:CustomizePips("offset",12))
assert(S:CustomizePips("growth","left"))
assert(S:CustomizePips("texture","flat"))
assert(S:CustomizePips("palette","emerald"))
assert(S:CustomizePips("colorMode","rainbow"))
assert(S:CustomizePips("border","strong"))
assert(S:CustomizePips("customR",.45))
assert(S:PipStyle().palette=="custom")
assert(S:CustomizePips("customG",.60))
assert(S:CustomizePips("customB",.80))
assert(not S:CustomizePips("shape","mystery"))
assert(not S:CustomizePips("gap","bad"))
assert(S:PipStyle().growth=="left")
assert(firstRecord.bars[1].anchor[1]=="RIGHT")
assert(firstRecord.bars[1].values[#firstRecord.bars[1].values]==before,
 "changing pip design must never read/rewrite combat values")
assert(S:ResetPipDesign())
assert(S:PipStyle().palette=="gold")
assert(S:PipStyle().width==19)
local persisted=S:Store().pipStyle
assert(type(persisted)=="table","pip designs persist per character")
assert(S:HUDSettings().hudPlacement=="below")
assert(S:SetHUDPlacement("above"))
assert(record.holder.anchor[2]==replacementHealth and record.holder.anchor[1]=="BOTTOM")
assert(record.energyBar.anchor[2]==record.holder and record.energyBar.anchor[1]=="BOTTOM",
 "when above the healthbar, energy must sit above the pips, not between pips and health")
assert(S:SetHUDPlacement("below"))
assert(record.holder.anchor[1]=="TOP")
assert(record.energyBar.anchor[1]=="TOP","below placement keeps energy below pips")
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
assert(not S:SetEnergyEnabled(false))
assert(not S:SetEnergyHeight(7))
assert(not S:SetEnergyColor("gold"))
assert(not S:PresetPips("frost"))
assert(not S:CustomizePips("palette","crimson"))
assert(not S:ResetPipDesign())
assert(not S:SetHUDPlacement("above"))
assert(not S:SetHUDScale(1.5))
assert(not S:SetHUDEnabled(false))
assert(not S:ResetHUDPosition())
InCombatLockdown=function()return false end
assert(loadfile("addons/KSStealth/UI.lua"))()
local previewBefore=#frames
local designerParent=frame("Frame",UIParent)
S.BuildDesignerPage(designerParent)
local previewSegments=0
for i=previewBefore+1,#frames do
 local w=frames[i]
 if w.kind=="StatusBar" and w.values[#w.values]==3 then previewSegments=previewSegments+1 end
end
assert(previewSegments==5,"designer must show five pip previews while idle")

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
