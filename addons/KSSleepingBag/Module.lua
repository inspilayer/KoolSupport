KoolSupport:RegisterModule({
 id="ks_sleeping_bag",title="Sleeping Bag Navigator",apiVersion=1,
 defaultEnabled=false,requires={},
 onEnable=function()if KSSleepingBag then KSSleepingBag:Refresh() end end,
 onDisable=function()if KSSleepingBag then KSSleepingBag:OnModuleDisabled() end end,
})
KoolSupport:RegisterPage({id="sleeping_bag",title="Sleeping Bag Navigator",
 moduleId="ks_sleeping_bag",build=function(parent)KSSleepingBag.BuildPage(parent)end})
