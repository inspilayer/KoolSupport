-- Quest Checker uses only Blizzard's own completion flags.
KoolSupport:RegisterModule({
  id="ks_quest_checker",title="KS Quest Checker",apiVersion=1,
  defaultEnabled=true,requires={},
})
KoolSupport:RegisterPage({
  id="quest_checker",title="Quest Checker",moduleId="ks_quest_checker",
  build=function(parent) KSQuestChecker.BuildPage(parent) end,
})
