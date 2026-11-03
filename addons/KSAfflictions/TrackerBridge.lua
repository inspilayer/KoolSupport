-- KS Afflictions compatibility shim for Joe Greive's MIT-licensed DoesItDie tracker.
-- The vendor engine is not a stand-alone addon here; KoolSupport owns all visual frames.
-- This intentionally provides NO casting, rotation selection, nameplate enumeration, or hidden combat arithmetic.
local addonName, ns = ...
local safeColors = {
  [1]={1,.40,.42}, [2]={1,.86,.44}, [4]={1,.48,.24}, [8]={.27,.88,.55},
  [16]={.42,.76,1}, [32]={.77,.48,1}, [64]={.57,.67,1}, [20]={1,.58,.3}
}
ns.display = {
  schoolColors=safeColors,
  setDb=function(db) ns.db=db end,
  attach=function() return true end,
  animate=function() end,
  forgetTracedDamage=function() end,
  hasHealthBar=function() return false end,
}
ns.refresh = function()
  if ns.tracking and ns.tracking.housekeep then ns.tracking.housekeep(GetTime()) end
end
ns.playFlash = function() end
-- The old addon settings window is replaced by the KS module page.
ns.registerOptions = function() end
ns.openOptions = function()
  if KoolSupport and KoolSupport.Open then KoolSupport:Open("afflictions") end
end
