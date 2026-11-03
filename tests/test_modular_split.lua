-- Generic workshop and optional Support Sessions must remain independent.
SlashCmdList={}
InCombatLockdown=function()return false end
KoolSupportDB={
  character="Wildheart", recipientClass="DRUID", spec="Holy",
  owned={['KS-Old']=true},generated={['KS-Old']="#showtooltip\n/cast Renew"},
  customDrafts={['KSC-Old']={body="/cast Rejuvenation"}},customOrder={'KSC-Old'},
  enabledProfiles={['PRIEST:Holy:DRUID']={['KS-Quick']=false}},
}
UnitClass=function()return "Priest","PRIEST" end
assert(loadfile('addons/KoolSupport/Core.lua'))()
for _,filename in ipairs({
 'addons/KSMacros/Engine.lua','addons/KSMacros/Spellbook.lua',
 'addons/KSMacros/Suite.lua','addons/KSMacros/Workshop.lua','addons/KSMacros/Module.lua',
 'addons/KSSupportSessions/Profiles.lua','addons/KSSupportSessions/Session.lua',
 'addons/KSSupportSessions/Module.lua',
}) do assert(loadfile(filename))() end
local K=KoolSupport
local M=KSMacros
local S=KSSupportSessions
assert(K:CanOpenPage('macro_suite'))
assert(K:CanOpenPage('full_spellbook'))
assert(K:CanOpenPage('macro_workshop'))
assert(K:CanOpenPage('support_session'))
assert(K:GetModule('ks_support_sessions').requires[1]=='ks_macros')
local migrated=M:Store()
assert(migrated.drafts['KSC-Old']=='#showtooltip\n/cast Rejuvenation')
assert(migrated.owned['KS-Old']=='#showtooltip\n/cast Renew')
local was=migrated.draftOrder[1]
M:Store()
assert(migrated.draftOrder[1]==was and #migrated.draftOrder==1, 'migration must be idempotent')
assert(KoolSupportDB.customDrafts['KSC-Old'].body=='/cast Rejuvenation','legacy state must remain')
assert(M:SaveDraft('KSM-NewDraft','/cast [@player] Renew'))
local found=false
for _,entry in ipairs(M:GetSuite()) do
  assert(entry.group~='Healing' and entry.group~='Emergency', 'support-specific presets leaked into generic suite')
  if entry.id=='KSM-NewDraft' then found=true end
end
assert(found)
local defs=S:Build('PRIEST','Holy','DRUID','Wildheart')
assert(defs[1].body=='#showtooltip\n/focus Wildheart')
assert(S:GetEnabled(defs[3])==true or S:GetEnabled(defs[3])==false)
local quick
for _,d in ipairs(defs) do
 if d.name=='KS-Quick' then quick=d;break end
end
assert(quick and not S:GetEnabled(quick),'legacy support preference preserved')
local ok,why=K:SetModuleEnabled('ks_macros',false)
assert(not ok and why:find('ks_support_sessions'),'parent cannot be disabled with child on')
assert(K:SetModuleEnabled('ks_support_sessions',false))
assert(not K:CanOpenPage('support_session'))
assert(K:CanOpenPage('macro_suite'))
assert(K:SetModuleEnabled('ks_macros',false))
assert(not K:CanOpenPage('macro_workshop'))
assert(not K:CanOpenPage('full_spellbook'))
assert(K:SetModuleEnabled('ks_macros',true))
assert(K:SetModuleEnabled('ks_support_sessions',true))
local none,reason=S:Build('PRIEST','Holy','DRUID','bad/name')
assert(not none and reason)
print('PASS modular: independent generic pages, optional support dependencies, migration, naming')
