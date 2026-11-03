local KS=KoolSupport
KS:RegisterModule({id="ks_support_sessions",title="KS Support Sessions",apiVersion=1,
  defaultEnabled=true,requires={"ks_macros"}})
KS:RegisterPage({id="support_session",title="Support Sessions",moduleId="ks_support_sessions",
  build=KSSupportSessions.BuildPage})
