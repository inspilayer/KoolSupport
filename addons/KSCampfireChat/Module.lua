local A=KSCampfireChat
KoolSupport:RegisterModule({
 id="ks_campfire_chat",title="Campfire Chat",apiVersion=1,
 defaultEnabled=true,requires={},
})
KoolSupport:RegisterPage({
 id="campfire_chat",title="Campfire Chat",moduleId="ks_campfire_chat",
 build=function(parent)A.BuildPage(parent)end,
})
