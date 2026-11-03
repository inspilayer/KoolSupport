local KS=KoolSupport
KS:RegisterModule({id="ks_stealth",title="KS Stealth",apiVersion=1,defaultEnabled=true,requires={},
  onEnable=function()KSStealth:OnModuleEnabled()end,
  onDisable=function()KSStealth:OnModuleDisabled()end})
KS:RegisterPage({id="stealth",title="KS Stealth",moduleId="ks_stealth",build=KSStealth.BuildPage})

KS:RegisterPage({id="stealth_talents",title="Talent Impacts",moduleId="ks_stealth",build=KSStealth.BuildTalentPage})
