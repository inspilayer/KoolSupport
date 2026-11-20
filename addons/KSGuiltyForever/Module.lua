KoolSupport:RegisterModule({id="ks_guilty_forever",title="Guilty Forever",apiVersion=1,defaultEnabled=true,requires={}})
KoolSupport:RegisterPage({id="guilty_forever",title="Guilty Forever",moduleId="ks_guilty_forever",
 build=function(parent)KSGuiltyForever.BuildPage(parent)end})
