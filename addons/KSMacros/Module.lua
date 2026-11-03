local KS = KoolSupport
KS:RegisterModule({
  id = "ks_macros", title = "KS Macros", apiVersion = 1,
  defaultEnabled = true, requires = {},
})
KS:RegisterPage({
  id = "macro_workshop", title = "Macro Workshop", moduleId = "ks_macros",
  build = KSMacros.BuildWorkshop,
})
