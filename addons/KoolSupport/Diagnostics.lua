-- KoolSupport launch diagnostics: explicit READ-ONLY, no gameplay API calls.
-- Never inspect enemy secrets, talent state, macro bodies, or user messages.
local KS=KoolSupport
local NAMES={
 {"KoolSupport","KoolSupport Base","base"},
 {"KSMacros","KS Macros","ks_macros"},
 {"KSSupportSessions","KS Support Sessions","ks_support_sessions"},
 {"KSStealth","KS Stealth","ks_stealth"},
 {"KSAfflictions","KS Afflictions","ks_afflictions"},
 {"KSCampfireChat","Campfire Chat","ks_campfire_chat"},
 {"KSThreat","KS Threat","ks_threat"},
}
local function available(fn) return type(fn)=="function" end
local function addonLoaded(name)
 local api=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
 if not available(api) then return nil end
 local ok,result=pcall(api,name)
 if ok and type(result)=="boolean" then return result end
 return nil
end
local function interfaceNumber()
 if not available(GetBuildInfo) then return nil end
 local ok,_,_,_,toc=pcall(GetBuildInfo)
 if ok and type(toc)=="number" then return toc end
 return nil
end
function KS:CollectLaunchChecks()
 local rows={}
 local function add(id,title,status,detail)
  rows[#rows+1]={id=id,title=title,status=status,detail=detail}
 end
 local toc=interfaceNumber()
 if toc then
  add("interface","Live client Interface",toc==16001 and "MATCH" or "REVIEW",
   tostring(toc).." (addon manifests expect 16001; verify in live client)")
 else add("interface","Live client Interface","UNKNOWN","GetBuildInfo unavailable") end
 -- Only KoolSupport is a physical WoW addon. Modules are Lua subdirectories
 -- and cannot be checked with C_AddOns.IsAddOnLoaded(moduleName).
 local rootLoaded=addonLoaded("KoolSupport")
 for _,entry in ipairs(NAMES) do
  local name,title,module=entry[1],entry[2],entry[3]
  if name=="KoolSupport" then
   add(name,title,rootLoaded==false and "MISSING" or
       rootLoaded==nil and "UNVERIFIED" or "ENABLED",
       rootLoaded==false and "KoolSupport root was not loaded" or
       rootLoaded==nil and "Root loaded state unavailable; UI code is active" or
       "Single KoolSupport addon loaded; six modules are bundled inside")
  else
   local def=self:GetModule(module)
   if not def then
    add(name,title,"MISSING","Bundled Lua module did not register in KoolSupport")
   else
    local enabled,reason=self:IsModuleEnabled(module)
    add(name,title,enabled and "ENABLED" or "OFF",
      enabled and "Registered and enabled in the unified KoolSupport addon" or
      ("Bundled; disabled by module setting"..(reason and " ("..reason..")" or "")))
   end
  end
 end
 local capabilities={
  {"spellbook","Learned spellbook",C_SpellBook and
     available(C_SpellBook.GetNumSpellBookSkillLines) and
     available(C_SpellBook.GetSpellBookItemInfo)},
  {"traits","Talent API",C_ClassTalents and C_Traits and
     available(C_ClassTalents.GetActiveConfigID) and
     available(C_Traits.GetNodeInfo)},
  {"tooltip","Spell tooltip extension",TooltipDataProcessor and Enum and Enum.TooltipDataType and
     available(TooltipDataProcessor.AddTooltipPostCall) and Enum.TooltipDataType.Spell~=nil},
  {"nameplates","Visible nameplate API",C_NamePlate and available(C_NamePlate.GetNamePlates) and
    available(C_NamePlate.GetNamePlateForUnit)},
  {"combos","Combo point API",available(GetComboPoints)},
 }
 for _,entry in ipairs(capabilities) do
  add(entry[1],entry[1]=="spellbook" and "Spellbook API" or
    entry[1]=="traits" and "Talent API" or
    entry[1]=="tooltip" and "Spell tooltip API" or
    entry[1]=="nameplates" and "Nameplate API" or "Combo point API",
    entry[3] and "PRESENT" or "UNAVAILABLE",
    entry[3] and "Entry points detected; runtime behavior still unverified" or
      "API entry points missing; feature must fail closed")
 end
 return rows
end
