-- Run from repository root: lua tests/test_macros.lua
SlashCmdList = {}
InCombatLockdown = function() return false end
assert(loadfile('addons/KoolSupport/Core.lua'))()
assert(loadfile('addons/KSMacros/Engine.lua'))()
local M=KSMacros
assert(M:NormalizeTooltip('/cast Claw\n#showtooltip Cat Form') == '#showtooltip Cat Form\n/cast Claw')
assert(M:NormalizeTooltip('#showtooltip\n/cast Claw\n#showtooltip Cat Form') == '#showtooltip Cat Form\n/cast Claw')
assert(M:CastLine('Rejuvenation','focus','help') == '/cast [@focus,help,nodead] Rejuvenation')
assert(M:CastLine('Moonfire','focustarget','harm') == '/cast [@focustarget,harm,nodead] Moonfire')
assert(M:CastLine('/run bad','focus','help') == nil)
assert(M:CastLine('Claw','invalid',nil) == nil)
local storage, n = {}, 0
MAX_CHARACTER_MACROS = 30
GetMacroIndexByName = function(name)
  for i,v in ipairs(storage) do if v.name == name then return i end end
  return 0
end
GetMacroBody = function(i) return storage[i] and storage[i].body end
GetNumMacros = function() return 0, #storage end
CreateMacro = function(name, icon, body, isChar)
  assert(isChar)
  storage[#storage+1]={name=name,body=body}; n=n+1
  return #storage
end
EditMacro = function(i, name, icon, body)
  assert(storage[i]);storage[i].body=body;return i
end
assert(M:SaveDraft('KSM-Heal','#showtooltip\n/cast [@focus,help,nodead] Rejuvenation'))
assert(M:Store().drafts['KSM-Heal'])
assert(M:Install('KSM-Heal', '/cast [@focus,help,nodead] Rejuvenation'))
assert(#storage==1)
assert(storage[1].body:match('^#showtooltip\n'))
assert(M:Install('KSM-Heal','/cast [@focus,help,nodead] Regrowth'))
assert(#storage==1, 'updates should not duplicate')
storage[1].body='/cast HandEdited'
local ok,why=M:Install('KSM-Heal','/cast Claw')
assert(not ok and why:find('edited'), 'must protect manual edits')
storage[#storage+1]={name='UserOwned',body='/cast Claw'}
ok,why=M:Install('UserOwned','/cast Shred')
assert(not ok and why:find('not owned'), 'must protect unrelated names')
ok=M:SaveDraft('TooLong',string.rep('x',256))
assert(not ok, 'macro length limit')
InCombatLockdown=function() return true end
ok=M:Install('KSM-Test','/cast Claw')
assert(not ok, 'combat must block macro writes')
print('PASS macros: tooltip, cast conditions, drafts, safe installation, limits, combat')
