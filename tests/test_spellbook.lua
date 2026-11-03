SlashCmdList={}
InCombatLockdown=function()return false end
assert(loadfile('addons/KoolSupport/Core.lua'))()
assert(loadfile('addons/KSMacros/Engine.lua'))()
Enum={SpellBookSpellBank={Player=1},SpellBookItemType={Spell=1,FutureSpell=2,Flyout=4}}
local items={
 {itemType=1,name='Rejuvenation',spellID=101},
 {itemType=1,name='Prowl',spellID=102,isPassive=false},
 {itemType=1,name='Passive Aura',isPassive=true},
 {itemType=2,name='Future Spell'},
 {itemType=4,name='Spell Flyout'},
}
C_SpellBook={
 GetNumSpellBookSkillLines=function()return 1 end,
 GetSpellBookSkillLineInfo=function(i)return {name='Druid',itemIndexOffset=0,numSpellBookItems=#items} end,
 GetSpellBookItemInfo=function(i,bank)assert(bank==1);return items[i] end,
}
assert(loadfile('addons/KSMacros/Spellbook.lua'))()
local spells=assert(KSMacros:ScanSpellbook())
assert(#spells==2)
assert(spells[1].name=='Prowl' and spells[2].name=='Rejuvenation')
InCombatLockdown=function()return true end
local none,why=KSMacros:ScanSpellbook()
assert(not none and why:find('outside combat'))
InCombatLockdown=function()return false end
C_SpellBook=nil
none,why=KSMacros:ScanSpellbook()
assert(not none and why:find('unavailable'))
print('PASS spellbook: discovered active learned spells; no passives/future spells; safe errors')
