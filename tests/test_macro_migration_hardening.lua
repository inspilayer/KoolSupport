-- Legacy v0.6.4 migration and unsafe native macro APIs must fail closed.
SlashCmdList={}
InCombatLockdown=function()return false end
local oldBody="#showtooltip\n/cast Renew"
local mystery={value="player-owned"}
KoolSupportDB={
  owned={
    SafeLegacy=true,Unowned=false,TruthyLegacy="yes",
    ["Bad*Name"]=true,Overlong=true,
  },
  generated={
    SafeLegacy=oldBody,Unowned=oldBody,TruthyLegacy=oldBody,
    ["Bad*Name"]=oldBody,Overlong=string.rep("a",260),
  },
  customOrder=12345,customDrafts={MyDraft={body="/cast Rejuvenation"}},
  mystery=mystery,
}
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSMacros/Engine.lua"))()
local M=KSMacros
local db=KoolSupportDB
local migrated=M:Store()
assert(migrated.owned.SafeLegacy==oldBody)
assert(not migrated.owned.Unowned and not migrated.owned.TruthyLegacy)
assert(not migrated.owned["Bad*Name"] and not migrated.owned.Overlong)
assert(not migrated.legacyMigrationV1,"malformed custom order must remain retryable")
assert(db.customOrder==12345 and db.customDrafts.MyDraft.body=="/cast Rejuvenation")
db.customOrder={"MyDraft","MyDraft"}
local migratedAgain=M:Store()
assert(migratedAgain==migrated and migratedAgain.legacyMigrationV1==true)
assert(migratedAgain.drafts.MyDraft=="#showtooltip\n/cast Rejuvenation")
assert(#migratedAgain.draftOrder==1,"duplicate legacy order names should migrate once")
assert(db.mystery==mystery and db.owned.SafeLegacy and db.generated.SafeLegacy==oldBody)
M:Store()
assert(#migratedAgain.draftOrder==1,"migration must be idempotent")

local storage={{name="SafeLegacy",body=oldBody},{name="Unrelated",body="/cast Moonfire"}}
local writes=0
local nativeIndex=function(name)
 for i,mac in ipairs(storage)do if mac.name==name then return i end end
 return 0
end
GetMacroIndexByName=function(name)return nativeIndex(name)end
GetMacroBody=function(index)return storage[index] and storage[index].body end
GetNumMacros=function()return 0,#storage end
MAX_CHARACTER_MACROS=18
CreateMacro=function(name,icon,body,isChar)
 assert(isChar and type(icon)=="string")
 writes=writes+1
 storage[#storage+1]={name=name,body=body}
 return #storage
end
EditMacro=function(index,name,icon,body)
 writes=writes+1
 storage[index].body=body
 return index
end
local ok,why=M:Install("SafeLegacy","/cast Regrowth")
assert(ok and storage[1].body=="#showtooltip\n/cast Regrowth")
assert(migrated.owned.SafeLegacy==storage[1].body)
local baselineWrites=writes
local prevOwned=migrated.owned.SafeLegacy
GetMacroIndexByName=function()error("native lookup failure")end
ok,why=M:Install("NewMacro","/cast Claw")
assert(not ok and why:find("lookup") and writes==baselineWrites)
GetMacroIndexByName=function()return "corrupt" end
ok=M:Install("NewMacro","/cast Claw")
assert(not ok and writes==baselineWrites)
GetMacroIndexByName=function(name)return nativeIndex(name)end

GetMacroBody=function()error("protected native macro read")end
ok,why=M:Install("SafeLegacy","/cast Shred")
assert(not ok and why:find("verify") and writes==baselineWrites)
GetMacroBody=function(index)return storage[index] and storage[index].body end

GetNumMacros=function()error("macro count unavailable")end
ok,why=M:Install("NewMacro","/cast Claw")
assert(not ok and why:find("slots") and writes==baselineWrites)
GetNumMacros=function()return nil,nil end
ok=M:Install("NewMacro","/cast Claw")
assert(not ok and writes==baselineWrites)
GetNumMacros=function()return 0,#storage end

CreateMacro=function()error("game refused creation")end
ok,why=M:Install("NewMacro","/cast Claw")
assert(not ok and why:find("rejected") and not migrated.owned.NewMacro and writes==baselineWrites)
CreateMacro=function(name,icon,body,isChar)
 writes=writes+1;storage[#storage+1]={name=name,body=body};return #storage
end

EditMacro=function()error("game refused edit")end
ok,why=M:Install("SafeLegacy","/cast Shred")
assert(not ok and why:find("rejected") and writes==baselineWrites)
assert(migrated.owned.SafeLegacy==prevOwned)
EditMacro=function(index,name,icon,body)
 writes=writes+1;storage[index].body=body;return index
end
storage[1].body="/cast EditedByPlayer"
ok,why=M:Install("SafeLegacy","/cast Shred")
assert(not ok and why:find("edited") and writes==baselineWrites)
storage[1].body=prevOwned

ok,why=M:InstallBatch({{name="KS-New1",body="/cast Claw"},{name="Unrelated",body="/cast Shred"}})
assert(not ok and why:find("overwrite") and writes==baselineWrites,"batch should preflight all conflicts")
GetMacroIndexByName=function()error("lookup not readable")end
ok,why=M:InstallBatch({{name="KS-New2",body="/cast Claw"}})
assert(not ok and why:find("lookup") and writes==baselineWrites)
GetMacroIndexByName=function(name)return nativeIndex(name)end

GetNumMacros=function()return nil end
ok,why=M:InstallBatch({{name="KS-New2",body="/cast Claw"}})
assert(not ok and why:find("slots") and writes==baselineWrites)
GetNumMacros=function()return 0,#storage end
ok,why=M:InstallBatch({{name="KS-New1",body="/cast Claw"},{name="KS-New2",body="/cast Shred"}})
assert(ok and writes==baselineWrites+2 and migrated.owned["KS-New1"] and migrated.owned["KS-New2"])
assert(db.customOrder[1]=="MyDraft" and db.mystery==mystery)
InCombatLockdown=function()return true end
ok=M:InstallBatch({{name="KS-New3",body="/cast Rejuvenation"}})
assert(not ok and writes==baselineWrites+2,"combat never mutates native macros")
print("PASS macro hardening: legacy ownership, malformed order, safe API errors, atomic preflight, combat")
