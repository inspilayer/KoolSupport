-- KS Stealth: target nameplate display settings (legacy HUD API compatibility).
-- No detached draggable HUD: all combo segments are owned by target nameplate.
local S=KSStealth
function S:HUDSettings()
 local db=self:Store()
 if db.hudEnabled==nil then db.hudEnabled=true end
 if db.hudPlacement~="above" then db.hudPlacement="below" end
 if type(db.hudScale)~="number" or db.hudScale~=db.hudScale then db.hudScale=1 end
 db.hudScale=math.max(.7,math.min(1.8,db.hudScale))
 return db
end
function S:HUDModuleReady()
 return KoolSupport:IsModuleEnabled("ks_stealth") and self:IsSupportedClass()
end
function S:HideHUD()
 self:HideAll()
end
function S:UpdateHUD()
 self:UpdateTargetNameplate()
end
function S:SetHUDEnabled(value)
 if KoolSupport:IsInCombat() then return false,"Change combo display settings outside combat" end
 self:HUDSettings().hudEnabled=not not value
 self:UpdateAll()
 return true
end
function S:SetHUDPlacement(value)
 if KoolSupport:IsInCombat() then return false,"Move combo points outside combat" end
 if value~="above" and value~="below" then return false,"Use above or below" end
 self:HUDSettings().hudPlacement=value
 self:Relayout()
 return true
end
function S:SetHUDScale(value)
 if KoolSupport:IsInCombat() then return false,"Resize combo points outside combat" end
 if type(value)~="number" or value~=value then return false,"Invalid scale" end
 self:HUDSettings().hudScale=math.max(.7,math.min(1.8,value))
 self:Relayout()
 return true
end
function S:ResetHUDPosition()
 if KoolSupport:IsInCombat() then return false,"Reset combo points outside combat" end
 local db=self:HUDSettings()
 db.hudPlacement="below"
 db.hudScale=1
 -- Obsolete free-floating offsets are deliberately not used or deleted.
 self:Relayout()
 return true
end
-- Older UI calls remain safe but never open a free-floating frame.
function S:ShowHUDForPositioning()
 if not self:HUDModuleReady() then return false,"Enable KS Stealth on a Druid or Rogue." end
 if KoolSupport:IsInCombat() then return false,"Change settings outside combat" end
 self:UpdateAll()
 return true
end
function S:FinishHUDPositioning()
 return true
end
function S:SetHUDLocked(_)
 return false,"Combo points are attached to your target nameplate; no drag lock needed."
end
