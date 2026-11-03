local KS = KoolSupport
KS:RegisterModule({
  id="ks_macros",title="KS Macros",apiVersion=1,
  defaultEnabled=true,requires={},
})
KS:RegisterPage({id="macro_suite",title="Macro Suite",moduleId="ks_macros",build=KSMacros.BuildSuite})
KS:RegisterPage({id="full_spellbook",title="Full Spellbook",moduleId="ks_macros",build=KSMacros.BuildSpellbook})
KS:RegisterPage({id="macro_workshop",title="Custom Builder",moduleId="ks_macros",build=KSMacros.BuildWorkshop})
