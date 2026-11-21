-- KS Stealth movable combo HUD: character settings, target changes, opaque points,
-- independent nameplates, drag lock, no combat mutations and module teardown.
SlashCmdList={}
local original={unrelated={keep=true}}
KoolSupportDB=original
InCombatLockdown=function()return false end
UnitClass=function()return "Rogue","ROGUE" end
local target=true
UnitExists=function(unit)assert(unit=="target");return target end
local SECRET=setmetatable({opaque=true},{
  __eq=function()error("never compare combo secret in Lua")end,
  __lt=function()error("never compare combo secret in Lua")end,
  __le=function()error("never compare combo secret in Lua")end,
  __tostring=function()error("never stringify combo secret")end,
})
local reads=0
GetComboPoints=function(src,dst)
 assert(src=="player" and dst=="target","HUD should query selected target only")
 reads=reads+1
 return SECRET
end
local frames={}
local function frame(kind,parent)
 local f={kind=kind,hidden=false,children={},parent=parent}
 function f:SetSize(w,h)self.width,self.height=w,h end
 function f:SetPoint(...)self.anchor={...}end
 function f:ClearAllPoints()self.anchor=nil end
 function f:SetScale(x)self.scale=x end
 function f:SetFrameStrata(x)self.stratum=x end
 function f:SetFrameLevel(x)self.level=x end
 function f:SetMovable(x)self.movable=x end
 function f:RegisterForDrag(x)self.dragButton=x end
 function f:SetClampedToScreen(x)self.clamped=x end
 function f:EnableMouse(x)self.mouse=x end
 function f:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
 function f:SetScript(name,cb)self[name]=cb end
 function f:SetShown(x)self.hidden=not x end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:SetText(x)self.text=x end
 function f:GetText()return self.text end
 function f:SetStatusBarTexture(x)self.barTexture=x end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(a,b)self.min,self.max=a,b end
 function f:SetValue(v)self.value=v;self.values=self.values or {};self.values[#self.values+1]=v end
 function f:SetAllPoints()end
 function f:SetTexture(x)self.texture=x end
 function f:SetVertexColor(...)self.vertexColor={...}end
 function f:SetWidth(x)self.width=x end
 function f:SetJustifyH()end
 function f:SetAutoFocus()end
 function f:SetMaxLetters()end
 function f:ClearFocus()end
 function f:GetEffectiveScale()
  return (self.parent and self.parent.GetEffectiveScale and self.parent:GetEffectiveScale() or 1)*(self.scale or 1)
 end
 function f:GetCenter()return self.centerX or 500,self.centerY or 500 end
 function f:GetWidth()return self.width or 1000 end
 function f:GetHeight()return self.height or 1000 end
 function f:StartMoving()self.moving=true end
 function f:StopMovingOrSizing()self.moving=false end
 function f:CreateTexture()local child=frame("Texture",self);return child end
 function f:CreateFontString()local child=frame("FontString",self);return child end
 if parent then parent.children[#parent.children+1]=f end
 frames[#frames+1]=f
 return f
end
UIParent=frame("UIParent")
UIParent.centerX,UIParent.centerY=500,500
UIParent.width,UIParent.height=1000,1000
TargetFrame=frame("Frame",UIParent)
CreateFrame=function(kind,_,parent)return frame(kind,parent)end
assert(loadfile("addons/KoolSupport/Core.lua"))()
KoolSupport:RegisterModule({id="ks_stealth",title="KS Stealth",apiVersion=1,defaultEnabled=true})
assert(loadfile("addons/KSStealth/Stealth.lua"))()
assert(loadfile("addons/KSStealth/HUD.lua"))()
local S=KSStealth
S.active=false -- stale lifecycle state must self-heal from enabled module
S:UpdateAll()
assert(S.active,"enabled module should initialize HUD even if PLAYER_LOGIN fired early")
local hud=S.comboHUD
assert(hud and not hud.hidden and #hud.bars==5,"HUD must render five segments without nameplates")
assert(hud.anchor[1]=="TOP" and hud.anchor[2]==TargetFrame and hud.anchor[3]=="BOTTOM" and hud.anchor[5]==-4,
 "HUD should be anchored beneath Blizzard target frame by default")
assert(not hud.mouse and hud.dragLabel.hidden,"HUD starts locked")
assert(reads>=1 and hud.bars[1].min==0 and hud.bars[5].max==5)
for _,bar in ipairs(hud.bars) do
 assert(bar.value==SECRET,"opaque point value must pass to Blizzard statusbar without inspection")
end
assert(KoolSupportDB.unrelated.keep==true)
assert(S:Store().hudEnabled and S:Store().hudLocked)
assert(S:SetNameplates(false))
assert(not hud.hidden,"HUD must remain visible when independent nameplates disabled")
target=false
S:OnEvent("PLAYER_TARGET_CHANGED")
assert(hud.hidden,"locked HUD hides without selected target")
assert(S:ShowHUDForPositioning())
assert(S:HUDSettings().hudEnabled and not S:HUDSettings().hudLocked)
assert(not hud.hidden and hud.mouse,"Show HUD must display idle five-pip preview")
for _,bar in ipairs(hud.bars) do assert(bar.value==0) end
assert(S:FinishHUDPositioning())
assert(S:HUDSettings().hudLocked and hud.hidden,"Done hides idle preview")
assert(S:SetHUDLocked(false))
assert(not hud.hidden and hud.mouse and not hud.dragLabel.hidden,
  "unlocked HUD must show empty preview for dragging even without target")
for _,bar in ipairs(hud.bars) do assert(bar.value==0,"preview pips reset with no target")end
hud.OnDragStart(hud)
assert(hud.moving)
hud.centerX,hud.centerY=620,410
hud.OnDragStop(hud)
assert(hud.moving==false)
local config=S:HUDSettings()
assert(config.hudX==120 and config.hudY==-90,"drag should save UIParent-relative location")
assert(config.hudAnchor=="custom","drag should opt in to custom positioning")
assert(hud.anchor[4]==120 and hud.anchor[5]==-90)
-- HUD scale changes must not make the dragged HUD jump to a different spot.
-- GetCenter reports HUD-local coordinates; UIParent center reports parent coords.
assert(S:SetHUDScale(1.4) and hud.scale==1.4)
hud.centerX,hud.centerY=510,325 -- center in HUD-local units, NOT UIParent units
hud.OnDragStart(hud)
hud.OnDragStop(hud)
local expectedX=510*1.4-500
local expectedY=325*1.4-500
assert(math.abs(config.hudX-expectedX)<.01 and math.abs(config.hudY-expectedY)<.01,
 "drag must store screen-consistent offsets, compensating for effective HUD scale")
assert(math.abs(hud.anchor[4]-expectedX/1.4)<.01 and math.abs(hud.anchor[5]-expectedY/1.4)<.01,
 "re-anchoring must not snap when scaled")
-- A scaled UIParent must be compensated too.
UIParent.scale=.8
hud.centerX,hud.centerY=510,325
hud.OnDragStart(hud);hud.OnDragStop(hud)
assert(math.abs(config.hudX-expectedX)<.01 and math.abs(hud.anchor[4]-expectedX/1.4)<.01,
 "UIParent UI scale must not perturb stored position")
UIParent.scale=1
assert(S:SetHUDScale(4) and hud.scale==1.8,"scale must clamp")
assert(S:SetHUDScale(0.1) and hud.scale==0.7)
assert(S:SetHUDLocked(true))
assert(hud.hidden and hud.mouse==false)
target=true
S:OnEvent("PLAYER_REGEN_ENABLED")
assert(not hud.hidden and hud.bars[1].value==SECRET)
assert(S:SetHUDEnabled(false))
assert(hud.hidden)
assert(S:SetHUDEnabled(true))
assert(not hud.hidden)
assert(S:ResetHUDPosition())
assert(config.hudX==0 and config.hudY==-170)
assert(config.hudAnchor=="target" and hud.anchor[2]==TargetFrame,
 "Reset position must put combo HUD beneath target frame")
InCombatLockdown=function()return true end
assert(not S:ShowHUDForPositioning(),"can't force preview during combat")
assert(not S:FinishHUDPositioning(),"can't finish preview during combat")
assert(not S:SetHUDLocked(false),"can't unlock while in combat")
assert(not S:SetHUDScale(1.2),"can't resize while in combat")
assert(not S:SetHUDEnabled(false),"can't hide/show via settings while in combat")
assert(not S:ResetHUDPosition(),"can't reset while in combat")
assert(not S:SaveHUDPosition(),"can't save dragging while in combat")
InCombatLockdown=function()return false end

-- Native options UI must expose an unlock action, without creating any addon.
assert(loadfile("addons/KSStealth/UI.lua"))()
local parent=frame("Frame",UIParent)
S.BuildPage(parent)
local unlock
for _,w in ipairs(frames) do
 if w.kind=="Button" and w.text=="Unlock / move HUD" then unlock=w end
end
local showPreview
for _,w in ipairs(frames) do
 if w.kind=="Button" and w.text=="SHOW HUD / MOVE" then showPreview=w end
end
assert(showPreview and showPreview.OnClick,"Show HUD button must exist")
assert(unlock and unlock.OnClick,"HUD lock control must be exposed in Stealth settings")
showPreview.OnClick(showPreview)
assert(not S:HUDSettings().hudLocked and hud.mouse and not hud.hidden)
assert(S:FinishHUDPositioning())
unlock.OnClick(unlock)
assert(not S:HUDSettings().hudLocked and hud.mouse)
assert(S:SetHUDLocked(true))
S:OnModuleDisabled()
assert(hud.hidden,"disabling KS Stealth hides the movable HUD")
assert(KoolSupportDB.unrelated.keep==true,"all previous character data preserved")
print("PASS KS Stealth HUD: five opaque pips, independent nameplates, preview, move, resize, lock, persist, no combat mutation")
