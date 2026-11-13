-- Run from repository root: lua tests/test_core.lua
KoolSupportDB = {}
SlashCmdList = {}
InCombatLockdown = function() return false end
local opened
assert(loadfile('addons/KoolSupport/Core.lua'))()
local KS = KoolSupport
KS.Open = function(_, page) opened = page end
assert(KS.API_VERSION == 1)
SlashCmdList.KOOLSUPPORT('')
assert(opened == 'home')
SlashCmdList.KOOLSUPPORT('builder')
assert(opened == 'macro_workshop')
KS:RegisterModule({id='ks_macros',title='KS Macros',apiVersion=1,defaultEnabled=true})
KS:RegisterModule({id='profiles',title='Profiles',apiVersion=1,requires={'ks_macros'},defaultEnabled=true})
KS:RegisterPage({id='macro_workshop',title='Macro Workshop',moduleId='ks_macros',build=function()end})
assert(KS:CanOpenPage('macro_workshop'))
assert(KS:IsModuleEnabled('profiles'))
local ok, reason = KS:SetModuleEnabled('ks_macros',false)
assert(not ok and reason:find('profiles'), 'active dependent must block disabling Macros')
assert(KS:SetModuleEnabled('profiles',false))
assert(KS:SetModuleEnabled('ks_macros',false))
assert(not KS:CanOpenPage('macro_workshop'))
ok, reason=KS:SetModuleEnabled('profiles',true)
assert(not ok and reason:find('ks_macros'), 'cannot enable plugin without prerequisite')
assert(KS:SetModuleEnabled('ks_macros',true))
assert(KS:SetModuleEnabled('profiles',true))
InCombatLockdown=function() return true end
ok=KS:SetModuleEnabled('profiles',false)
assert(not ok, 'combat blocks module settings mutation')
-- Read-only /kool dies must work in combat without changing settings or
-- opening a page. Only nonsecret evidence summaries are printed.
local previousPrint=print
local lines={}
print=function(msg)lines[#lines+1]=msg end
local count=0
KSAfflictions={
 Store=function()return {displayMode="centered"} end,
 RefreshAll=function()count=count+1 end,
 DiagnosticLine=function(_,unit)return unit..": 1 DoT, estimated 400 remaining; HP secret" end,
}
SlashCmdList.KOOLSUPPORT('dies')
assert(count==1 and #lines>=4,"Combat read-only diagnostic should execute")
assert(lines[2]:find("target:",1,true),"Target diagnostic must be reported")
assert(lines[3]:find("focus:",1,true),"Focus diagnostic must be reported")
assert(not lines[2]:find("UnitHealth"),"No raw health is emitted")
print=previousPrint

print('PASS core: registration, prerequisites, page gating, runtime toggles, combat lock')
