KoolSupport:RegisterModule({
 id="ks_combat_text",title="KS Combat Text Studio",
 apiVersion=1,defaultEnabled=false,requires={},
 onEnable=function() if KSCombatText then KSCombatText:Refresh() end end,
 onDisable=function() if KSCombatText then KSCombatText:OnModuleDisabled() end end,
})
KoolSupport:RegisterPage({
 id="combat_text",title="Combat Text Studio",moduleId="ks_combat_text",
 build=function(parent)KSCombatText.BuildPage(parent)end,
})
KoolSupport:RegisterPage({
 id="combat_text_tuning",title="Text Fine Tuning",moduleId="ks_combat_text",
 build=function(parent)KSCombatText.BuildTuningPage(parent)end,
})
KoolSupport:RegisterPage({
 id="combat_text_native",title="Blizzard Text Settings",moduleId="ks_combat_text",
 build=function(parent)KSCombatText.BuildNativePage(parent)end,
})
