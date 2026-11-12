-- Opt in per character. This module only adds display widgets.
local A=KSThreat
KoolSupport:RegisterModule({
 id="ks_threat",title="KS Threat",apiVersion=1,defaultEnabled=false,requires={},
 onEnable=function()A:Enable()end,
 onDisable=function()A:Disable()end,
})
KoolSupport:RegisterPage({
 id="ks_threat",title="KS Threat",moduleId="ks_threat",
 build=function(parent)A.BuildPage(parent)end,
})
