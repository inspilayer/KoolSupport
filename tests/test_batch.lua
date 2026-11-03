-- Batch preflight must reject conflicts before making any macro changes.
KoolSupportDB={}
SlashCmdList={}
InCombatLockdown=function()return false end
assert(loadfile('addons/KoolSupport/Core.lua'))()
assert(loadfile('addons/KSMacros/Engine.lua'))()
local M=KSMacros
local macros={{name='Existing',body='#showtooltip\n/cast Moonfire'}}
MAX_CHARACTER_MACROS=10
GetMacroIndexByName=function(name)for i,m in ipairs(macros) do if m.name==name then return i end end return 0 end
GetMacroBody=function(index)return macros[index].body end
GetNumMacros=function()return 0,#macros end
CreateMacro=function(name,icon,body,character)macros[#macros+1]={name=name,body=body};return #macros end
EditMacro=function(index,name,icon,body)macros[index].body=body;return index end
local ok,why=M:InstallBatch({{name='KSM-A',body='/cast Renew'},{name='Existing',body='/cast Claw'}})
assert(not ok and why:find('unrelated'))
assert(#macros==1,'preflight must prevent partial batch')
ok,why=M:InstallBatch({{name='KSM-A',body='/cast Renew'},{name='KSM-B',body='/cast Claw'}})
assert(ok and #macros==3)
macros[2].body='/cast PlayerEdited'
ok,why=M:InstallBatch({{name='KSM-C',body='/cast Shred'},{name='KSM-A',body='/cast Rejuvenation'}})
assert(not ok and why:find('edited'))
assert(#macros==3)
InCombatLockdown=function()return true end
ok=M:InstallBatch({{name='KSM-C',body='/cast Shred'}})
assert(not ok)
print('PASS batch: validates ownership/slots/combat before any writes')
