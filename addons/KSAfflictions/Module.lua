local A=KSAfflictions
KoolSupport:RegisterModule({
 id="ks_afflictions",title="KS Afflictions",apiVersion=1,defaultEnabled=true,requires={},
 onEnable=function() if A.Enable then A:Enable() end end,
 onDisable=function() if A.Disable then A:Disable() end end,
})
KoolSupport:RegisterPage({id="afflictions",title="KS Afflictions",moduleId="ks_afflictions",
 build=function(parent)A.BuildPage(parent)end})
