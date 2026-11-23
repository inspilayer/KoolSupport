-- KS Sleeping Bag Guide: curated Forever 1.60.1 hidden quest chain.
-- Sources: Wowhead Forever guide (2026-11-21), ForeverMastery (2026-11-09),
-- AzerothCompass (2026-11-14). Coordinates are destination estimates.
KSSleepingBag = KSSleepingBag or {}
local S=KSSleepingBag
S.QUESTS={
 noteHorde=79007,noteAlliance=79008,stepping=79192,scramble=79980,
 wet=79974,eagle=79975,final=79976,rekindle=80001,
}
S.STOPS={
 hordeStart={id="hordeStart",name="The Barrens: burned tower",zone="The Barrens",
  map=1413,x=46.4,y=73.9,quest=79007,action="Click Burned-Out Remains and accept ...and that note you found.",
  hint="South of Camp Taurajo, at the ruined tower."},
 allianceStart={id="allianceStart",name="Westfall: wrecked cart",zone="Westfall",
  map=1436,x=37.4,y=50.7,quest=79008,action="Click Burned-Out Remains and accept ...and that note you found.",
  hint="Alexston Farmstead, inside the broken cart."},
 hordeSecond={id="hordeSecond",name="Westfall: second remains",zone="Westfall",
  map=1436,x=37.4,y=50.7,quest=79007,action="Complete the note quest. Inspect the nearby Nailed Plank; accept Stepping Stones.",
  hint="Same cart remains, then the wooden plank."},
 allianceSecond={id="allianceSecond",name="The Barrens: second remains",zone="The Barrens",
  map=1413,x=46.4,y=73.9,quest=79008,action="Complete the note quest. Inspect the nearby Nailed Plank; accept Stepping Stones.",
  hint="Burned tower, south of Camp Taurajo."},
 stonetalonPath={id="stonetalonPath",name="Stonetalon: mountain path",zone="Stonetalon Mountains",
  map=1442,x=50.9,y=52.3,quest=79192,action="Follow the narrow path northeast of Sun Rock Retreat to the hidden camp.",
  hint="This is the route to the camp, not the quest turn-in."},
 stonetalonCamp={id="stonetalonCamp",name="Stonetalon: Pocket Litter",zone="Stonetalon Mountains",
  map=1442,x=40.6,y=52.4,quest=79192,action="Click Pocket Litter on the crate; complete Stepping Stones and accept Scramble.",
  hint="Optional Rekindle (80001) is at the campfire here."},
 stonetalonMound={id="stonetalonMound",name="Stonetalon: Mound of Dirt",zone="Stonetalon Mountains",
  map=1442,x=39.6,y=49.9,quest=79980,action="Climb north of camp to the ledge, jump to the mound, complete Scramble and accept Wet Job.",
  hint="Different elevation from Pocket Litter; use the cliff approach."},
 lochDam={id="lochDam",name="Loch Modan: dam figurine",zone="Loch Modan",
  map=1432,x=49.4,y=12.9,quest=79974,action="Reach the carved eagle figure on the ledge of Stonewrought Dam; complete Wet Job and accept Eagle's Fist.",
  hint="The object is below the dam top, on the Wetlands-facing side."},
 wallEntry={id="wallEntry",name="Hillsbrad: wall climb",zone="Hillsbrad Foothills",
  map=1424,x=87.3,y=49.6,quest=79975,action="Climb the broken cart and masonry at Thoradin's Wall.",
  hint="The wall climb is a jumping puzzle; this marks its entrance."},
 messenger={id="messenger",name="Arathi: Messenger Bag",zone="Arathi Highlands",
  map=1417,x=22.5,y=24.2,quest=79975,action="Click the hanging Messenger Bag at the wall-top camp; accept This Must Be the Place.",
  hint="The camp is at the top of Thoradin's Wall."},
 satchel={id="satchel",name="Arathi: rolled-up satchel",zone="Arathi Highlands",
  map=1417,x=22.5,y=24.2,quest=79976,action="Click the Hastily Rolled-Up Satchel beneath the Messenger Bag to get the Cozy Sleeping Bag!",
  hint="The two final objects are at the same campsite."},
}
S.ROUTES={
 Horde={"hordeStart","hordeSecond","stonetalonPath","stonetalonCamp",
  "stonetalonMound","lochDam","wallEntry","messenger","satchel"},
 Alliance={"allianceStart","allianceSecond","stonetalonPath","stonetalonCamp",
  "stonetalonMound","lochDam","wallEntry","messenger","satchel"},
}
local function ordinary(v)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,v)
  if not ok or secret then return false end
 end
 return true
end
local function completed(id)
 local api=(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
 if type(api)~="function" then return nil end
 local ok,value=pcall(api,id)
 if ok and ordinary(value) and type(value)=="boolean" then return value end
 return nil
end
local function active(id)
 local api=C_QuestLog and C_QuestLog.IsOnQuest
 if type(api)=="function" then
  local ok,flag=pcall(api,id)
  if ok and ordinary(flag) and type(flag)=="boolean" then return flag end
 end
 if type(GetQuestLogIndexByID)=="function" then
  local ok,index=pcall(GetQuestLogIndexByID,id)
  if ok and ordinary(index) and type(index)=="number" then return index>0 end
 end
 return false
end
function S:Faction()
 local faction=type(UnitFactionGroup)=="function" and UnitFactionGroup("player") or nil
 return faction=="Alliance" and "Alliance" or "Horde"
end
function S:Store()
 local root=KoolSupport:GetDatabase()
 root.modules=root.modules or {}
 root.modules.ks_sleeping_bag=root.modules.ks_sleeping_bag or {}
 local db=root.modules.ks_sleeping_bag
 if db.visible==nil then db.visible=false end
 if type(db.left)~="number" then db.left=0 end
 if type(db.top)~="number" then db.top=0 end
 if type(db.manualIndex)~="number" then db.manualIndex=0 end
 return db
end
function S:Route()return self.ROUTES[self:Faction()]end
function S:DetectedIndex()
 local q=self.QUESTS
 if completed(q.final)==true then return 10,true end
 if active(q.final) then return 9 end
 if completed(q.eagle)==true then return 8 end
 if active(q.eagle) then return 8 end
 if completed(q.wet)==true then return 6 end
 if active(q.wet) then return 6 end
 if completed(q.scramble)==true then return 6 end
 if active(q.scramble) then return 5 end
 if completed(q.stepping)==true then return 5 end
 if active(q.stepping) then return 4 end
 local note=self:Faction()=="Horde" and q.noteHorde or q.noteAlliance
 if completed(note)==true then return 4 end
 if active(note) then return 2 end
 return 1
end
function S:SelectedIndex()
 local route=self:Route()
 local index,done=self:DetectedIndex()
 if done then return #route+1,true end
 local manual=self:Store().manualIndex
 if manual>0 then return math.max(1,math.min(#route,manual)),false end
 return index,false
end
function S:CurrentStop()
 local index,done=self:SelectedIndex()
 return done and nil or self.STOPS[self:Route()[index]],index,done
end
function S:ManualStep(delta)
 if KoolSupport:IsInCombat() then return false,"Move guide steps outside combat" end
 local index=self:SelectedIndex()
 local nextIndex=math.max(1,math.min(#self:Route(),index+delta))
 self:Store().manualIndex=nextIndex
 self:Refresh()
 return true
end
function S:AutoStep()
 self:Store().manualIndex=0
 self:Refresh()
end
function S:SetVisible(value)
 if KoolSupport:IsInCombat() then return false,"Show or hide guide outside combat" end
 self:Store().visible=not not value
 self:Refresh()
 return true
end
function S:WorldTarget(stop)
 if not C_Map or type(C_Map.GetWorldPosFromMapPos)~="function" or
    type(CreateVector2D)~="function" then return nil end
 local ok,instance,world=pcall(C_Map.GetWorldPosFromMapPos,
    stop.map,CreateVector2D(stop.x/100,stop.y/100))
 if not ok or not world or type(world.GetXY)~="function" then return nil end
 local xyok,x,y=pcall(world.GetXY,world)
 if xyok and ordinary(x) and ordinary(y) and
    type(x)=="number" and type(y)=="number" then
  return instance,x,y
 end
end
function S:Direction(stop)
 if not stop or type(UnitPosition)~="function" or
  type(GetPlayerFacing)~="function" then return nil,"No position data" end
 local map=C_Map and C_Map.GetBestMapForUnit
 if type(map)~="function" then return nil,"Map location unavailable" end
 local ok,mapID=pcall(map,"player")
 if not ok or not ordinary(mapID) or mapID~=stop.map then
  return nil,"Travel to "..stop.zone
 end
 local instance,tx,ty=self:WorldTarget(stop)
 if not tx then return nil,"Map coordinates available" end
 local posok,px,py,_,playerInstance=pcall(UnitPosition,"player")
 local faceok,facing=pcall(GetPlayerFacing)
 if not posok or not faceok or not ordinary(px) or not ordinary(py) or
  not ordinary(facing) or type(px)~="number" or type(py)~="number"
  or type(facing)~="number" or instance~=playerInstance then
  return nil,"Direction unavailable"
 end
 local dx,dy=tx-px,ty-py
 if dx*dx+dy*dy<2500 then return nil,"Near quest object; inspect the area" end
 -- SetRotation expects radians relative to player orientation. The arrow
 -- graphic is vertical at zero, so convert world bearing accordingly.
 local bearing=math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx)
 return bearing-facing-math.pi/2,"Approximate direction (not a travel path)"
end
function S:Pin()
 local stop=self:CurrentStop()
 if not stop then return false,"Sleeping Bag obtained" end
 if type(UiMapPoint)=="table" and type(UiMapPoint.CreateFromCoordinates)=="function"
  and C_Map and type(C_Map.SetUserWaypoint)=="function" then
  local ok,pin=pcall(UiMapPoint.CreateFromCoordinates,stop.map,stop.x/100,stop.y/100)
  if ok and pin then
   local done=pcall(C_Map.SetUserWaypoint,pin)
   if done and C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint)=="function" then
    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint,true)
   end
   if done then return true end
  end
 end
 return false,"Use /mappin "..stop.map.." "..stop.x.." "..stop.y
end
