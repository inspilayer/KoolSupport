-- Optional sleeping bag quest-guide overlay for leveling players.
-- Movable, read-only waypoint assistance; never auto-moves or auto-interacts.
local S=KSSleepingBag
local KS=KoolSupport
local KIT=KS.UIKit
local GOLD="|cffffd87a"
local MUTED="|cffb8c9c4"
local frame
local textTitle,textQuest,textCoords,textHint,arrow,bagIcon,progress
local elapsed=0
local function text(parent,value,x,y,w)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 t:SetWidth(w)
 t:SetJustifyH("LEFT")
 t:SetText(value)
 return t
end
local function btn(parent,name,x,y,w,click)
 if KIT then return KIT:Button(parent,name,x,y,w,click,"secondary",25) end
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,25)
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(name)
 b:SetScript("OnClick",click)
 return b
end
local function setLabel(str)
 if textHint then textHint:SetText(str or "") end
end
local function install()
 if frame then return end
 frame=CreateFrame("Frame","KoolSupportSleepingBagArrow",UIParent,"BackdropTemplate")
 frame:SetSize(310,162)
 frame:SetFrameStrata("MEDIUM")
 frame:SetClampedToScreen(true)
 frame:SetMovable(true)
 frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton")
 if frame.SetBackdrop then
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
   edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(.055,.074,.09,.97)
  frame:SetBackdropBorderColor(.46,.39,.26,1)
 end
 local settings=S:Store()
 frame:SetPoint("CENTER",UIParent,"CENTER",settings.left,settings.top)
 frame:SetScript("OnDragStart",function(self)
  if not KS:IsInCombat() then self:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  local cx,cy=self:GetCenter()
  local ux,uy=UIParent:GetCenter()
  if type(cx)=="number" and type(cy)=="number" and
     type(ux)=="number" and type(uy)=="number" then
   local left=math.max(-1400,math.min(1400,cx-ux))
   local top=math.max(-900,math.min(900,cy-uy))
   local db=S:Store()
   db.left,db.top=left,top
   self:ClearAllPoints()
   self:SetPoint("CENTER",UIParent,"CENTER",left,top)
  end
 end)
 local icon=frame:CreateTexture(nil,"ARTWORK")
 icon:SetSize(23,23)
 icon:SetPoint("TOPLEFT",frame,"TOPLEFT",11,-9)
 icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
 bagIcon=icon
 textTitle=text(frame,GOLD.."COZY SLEEPING BAG|r",43,-12,245)
 progress=text(frame,"",12,-39,286)
 arrow=frame:CreateTexture(nil,"ARTWORK")
 arrow:SetSize(37,37)
 arrow:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-58)
 arrow:SetTexture("Interface\\MINIMAP\\MinimapArrow")
 if arrow.SetVertexColor then arrow:SetVertexColor(.96,.77,.33,1) end
 textQuest=text(frame,"",57,-57,242)
 textCoords=text(frame,"",57,-77,240)
 textHint=text(frame,"",12,-103,289)
 local left=btn(frame,"<",11,-131,38,function()S:ManualStep(-1)end)
 local right=btn(frame,">",53,-131,38,function()S:ManualStep(1)end)
 btn(frame,"AUTO",95,-131,61,function()S:AutoStep()end)
 btn(frame,"MAP PIN",161,-131,88,function()
  local ok,msg=S:Pin()
  if not ok then
   setLabel(MUTED..(msg or "Waypoint API unavailable").."|r")
  end
 end)
 btn(frame,"X",255,-131,43,function()S:SetVisible(false)end)
 frame:SetScript("OnUpdate",function(_,delta)
  elapsed=elapsed+(type(delta)=="number" and delta or 0)
  if elapsed<.25 then return end
  elapsed=0
  S:RefreshArrow()
 end)
 frame:Hide()
end
function S:RefreshArrow()
 if not frame or not frame:IsShown() then return end
 local stop,index,done=self:CurrentStop()
 if done then
  textQuest:SetText("Chain complete!")
  textCoords:SetText("Cozy Sleeping Bag obtained")
  textHint:SetText("You can hide the guide using X.")
  if arrow then arrow:Hide() end
  return
 end
 if not stop then return end
 local db=self:Store()
 local mode=db.manualIndex>0 and "MANUAL" or "AUTO"
 progress:SetText(MUTED..self:Faction().." | Stop "..index.."/"..#self:Route().." | "..mode.."|r")
 textQuest:SetText(stop.name)
 textCoords:SetText(string.format("%s  %.1f, %.1f",stop.zone,stop.x,stop.y))
 local rot,note=self:Direction(stop)
 if rot and type(arrow.SetRotation)=="function" then
  arrow:Show()
  arrow:SetRotation(rot)
 else
  arrow:Hide()
 end
 -- On opposite zone/continent, a straight arrow would be misleading.
 textHint:SetText(MUTED..(note or stop.hint).."|r")
end
function S:Refresh()
 if not KS:IsModuleEnabled("ks_sleeping_bag") then
  if frame then frame:Hide() end
  return
 end
 local db=self:Store()
 if db.visible then
  install()
  frame:Show()
  self:RefreshArrow()
 elseif frame then frame:Hide() end
end
function S:OnModuleDisabled()
 if frame then frame:Hide() end
end
function S.BuildPage(parent)
 local title=text(parent,GOLD.."SLEEPING BAG NAVIGATOR|r",22,-20,875)
 text(parent,"A compact draggable quest-chain arrow for Horde and Alliance. Level 14+.",22,-61,882)
 local card=KIT and KIT:Panel(parent,22,-115,888,310) or
   CreateFrame("Frame",nil,parent)
 if not KIT then card:SetPoint("TOPLEFT",parent,"TOPLEFT",22,-115);card:SetSize(888,310) end
 text(card,GOLD.."NEXT DESTINATION|r",18,-18,780)
 local location=text(card,"",18,-66,820)
 local desc=text(card,"",18,-111,835)
 local tip=text(card,"",18,-155,835)
 local indicator=text(card,"",18,-207,820)
 local function refresh()
  local stop,index,done=S:CurrentStop()
  if done then
   location:SetText("Complete: Cozy Sleeping Bag obtained!")
   desc:SetText("You finished the six main quests.")
   tip:SetText("")
   indicator:SetText("")
  elseif stop then
   location:SetText(stop.name.." ("..stop.zone.." "..stop.x..", "..stop.y..")")
   desc:SetText(stop.action)
   tip:SetText(MUTED..stop.hint.."|r")
   indicator:SetText(GOLD.."Stop "..index.."/"..#S:Route().."|r  |  "..(S:Store().manualIndex>0 and "Manual" or "Automatic").." tracking")
  end
 end
 btn(card,"PREVIOUS",18,-254,142,function()S:ManualStep(-1);refresh()end)
 btn(card,"NEXT STOP",173,-254,142,function()S:ManualStep(1);refresh()end)
 btn(card,"AUTO",330,-254,117,function()S:AutoStep();refresh()end)
 btn(card,"SHOW ARROW",466,-254,175,function()
  local ok,why=S:SetVisible(not S:Store().visible)
  if not ok then tip:SetText(why) end
  refresh()
 end)
 btn(card,"SET MAP PIN",657,-254,186,function()
  local ok,why=S:Pin()
  if not ok then tip:SetText(why or "Unavailable") end
 end)
 text(parent,GOLD.."HOW THE ARROW WORKS|r",22,-467,857)
 text(parent,"Arrow only points when you're in the destination's zone and the game exposes positions.",22,-509,870)
 text(parent,"Across continents it shows the zone and coordinates rather than a misleading straight-line route.",22,-541,878)
 text(parent,"Quest IDs auto-advance when available; use NEXT/PREV for hidden objects and climbs.",22,-573,878)
 text(parent,"Optional quest: Rekindle (#80001) at the Stonetalon camp. The route follows the six main quests.",22,-615,878)
 text(parent,MUTED.."Drag the floating panel with its background; close it with X. Your place is saved per character.|r",22,-649,878)
 refresh()
end
-- Login and quest updates are hints; overlay refreshing uses read-only APIs.
local eventFrame=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_TURNED_IN","PLAYER_LEVEL_UP"}) do
 pcall(eventFrame.RegisterEvent,eventFrame,event)
end
eventFrame:SetScript("OnEvent",function()S:Refresh()end)
