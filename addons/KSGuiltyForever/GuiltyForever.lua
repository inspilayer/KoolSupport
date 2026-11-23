-- Private notes only: no automatic ignore, party departure or chat messages.
KSGuiltyForever=KSGuiltyForever or {}
local A=KSGuiltyForever
A.pending={}
A.seen={}
A.warned={}
A.enemyWarned={}
local function safe(v)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,v)
  if not ok or secret then return false end
 end
 return true
end
-- Forever character identity is First Surname, NOT Name-Realm.
-- Old saved First-Surname keys remain readable for backwards compatibility.
function A:NormalizeName(name)
 if not safe(name) or type(name)~="string" then return nil end
 name=name:match("^%s*(.-)%s*$")
 if not name or #name<2 or #name>100 or name:find("[%c|]") then return nil end
 -- Accept older Name-Surname notes and chat/API hyphenated spellings.
 if not name:find("%s") then
  local first,last=name:match("^([^%-]+)%-([^%-]+)$")
  if first and last then name=first.." "..last end
 end
 name=name:gsub("%s+"," ")
 local first,last=name:match("^([^%s]+)%s+([^%s]+)$")
 if first and last then
  if not first:match("^[%w'\128-\255%-]+$") or not last:match("^[%w'\128-\255%-]+$") then return nil end
 elseif not name:match("^[%w'\128-\255%-]+$") then return nil end
 return name
end
function A:Key(name)
 local full=self:NormalizeName(name)
 return full and full:lower() or nil
end
function A:IsFullName(name)
 local full=self:NormalizeName(name)
 return full and full:find(" ",1,true)~=nil or false
end
function A:UnitFullName(name,surname)
 if not safe(name) or not safe(surname) or type(name)~="string" then return nil end
 -- Some Forever paths already include both names in the first return.
 if name:find(" ",1,true) then return self:NormalizeName(name) end
 if type(surname)=="string" and surname~="" then
  return self:NormalizeName(name.." "..surname)
 end
 return self:NormalizeName(name)
end
function A:LegacyKey(name)
 local key=self:Key(name)
 return key and key:gsub(" ","-") or nil
end
function A:Store()
 local db=KoolSupport:GetDatabase()
 db.modules=db.modules or {}
 db.modules.ks_guilty_forever=db.modules.ks_guilty_forever or {}
 local s=db.modules.ks_guilty_forever
 s.notes=s.notes or {}
 return s
end
function A:Save(name,reason,kind)
 local key=self:Key(name)
 if not key or not safe(reason) or type(reason)~="string" then return false end
 reason=reason:sub(1,500):match("^%s*(.-)%s*$")
 if reason=="" then return false end
 if kind=="enemy" and not self:IsFullName(name) then return false end
 local notes=self:Store().notes
 local legacy=self:LegacyKey(name)
 local old=notes[key] or (legacy and notes[legacy])
 local display=self:NormalizeName(name)
 notes[key]={name=display,reason=reason,kind=(kind=="enemy" and "enemy" or (kind=="ignore" and "ignore" or (old and old.kind) or "ignore")),created=(old and old.created) or (time and time() or 0)}
 if legacy and legacy~=key then notes[legacy]=nil end
 return true
end
function A:Get(name)
 local key=self:Key(name)
 if not key then return nil end
 local notes=self:Store().notes
 return notes[key] or notes[self:LegacyKey(name)]
end
function A:Delete(name)
 local key=self:Key(name)
 if key then
  local notes=self:Store().notes
  notes[key]=nil;notes[self:LegacyKey(name)]=nil
  return true
 end
 return false
end
function A:IgnoreSnapshot()
 local count=(C_FriendList and C_FriendList.GetNumIgnores) or GetNumIgnores
 local get=(C_FriendList and C_FriendList.GetIgnoreName) or GetIgnoreName
 if type(count)~="function" or type(get)~="function" then return nil end
 local ok,n=pcall(count)
 if not ok or not safe(n) or type(n)~="number" then return nil end
 local names={}
 for i=1,math.min(n,1000) do
  local success,name=pcall(get,i)
  local key=success and self:Key(name)
  if key then names[key]=name end
 end
 return names
end
function A:Prompt(name)
 local key=self:Key(name)
 if not key then return end
 if not StaticPopupDialogs or not StaticPopup_Show then
  self.pending[key]=nil
  if print then print("Guilty Forever: use /kool guilty to add a note for "..name) end
  return
 end
 StaticPopupDialogs.KS_GUILTY_FOREVER={
  text="Guilty Forever: why did you ignore %s? (Private note.)",
  button1="Save",button2="Skip",hasEditBox=true,maxLetters=500,
  timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
  OnShow=function(d)
   local e=d.editBox or d.EditBox
   if e then e:SetText("");e:SetFocus() end
  end,
  OnAccept=function(d,data)
   local e=d.editBox or d.EditBox
   if e then A:Save(data,e:GetText(),"ignore") end
   A.pending[A:Key(data)]=nil
  end,
  OnCancel=function(_,data)
   local k=A:Key(data)
   if k then A.pending[k]=nil end
  end,
 }
 StaticPopup_Show("KS_GUILTY_FOREVER",name,nil,name)
end
-- Observe the player's explicit /ignore request without replacing Blizzard's
-- slash command or calling ignore APIs ourselves. Some client versions route
-- /ignore through different handlers, so retain the list-update fallback.
function A:OnIgnoreRequested(raw)
 if not KoolSupport:IsModuleEnabled("ks_guilty_forever") then return end
 if not safe(raw) or type(raw)~="string" then return end
 local name=raw:match("^%s*(.-)%s*$")
 local key=self:Key(name)
 if not key or self:Get(name) or self.pending[key] then return end
 self.pending[key]=true
 self:Prompt(name)
end
function A:InstallIgnoreHooks()
 if self.ignoreHooksInstalled then return end
 self.ignoreHooksInstalled=true
 if type(hooksecurefunc)~="function" then return end
 local function tryHook(tbl,key)
  if type(tbl)~="table" or type(tbl[key])~="function" then return false end
  local ok=pcall(hooksecurefunc,tbl,key,function(name)
   A:OnIgnoreRequested(name)
  end)
  return ok
 end
 -- On supported clients this runs immediately after /ignore executes.
 tryHook(SlashCmdList,"IGNORE")
 -- Catch the alternate built-in ignore paths where available. These are
 -- secure post-hooks only; failures fall back to IGNORELIST_UPDATE.
 tryHook(C_FriendList,"AddIgnore")
 tryHook(C_FriendList,"AddOrDelIgnore")
end
function A:Sync(first)
 local now=self:IgnoreSnapshot()
 if not now then return end
 if first or not self.ready then self.seen=now;self.ready=true;return end
 for key,name in pairs(now) do
  if not self.seen[key] and not self:Get(name) and not self.pending[key]
   and KoolSupport:IsModuleEnabled("ks_guilty_forever") then
   self.pending[key]=true
   self:Prompt(name)
  end
 end
 self.seen=now
end
function A:CheckGroup()
 if not KoolSupport:IsModuleEnabled("ks_guilty_forever") then return end
 local units={}
 if IsInRaid and IsInRaid() then
  for i=1,40 do units[#units+1]="raid"..i end
 elseif IsInGroup and IsInGroup() then
  for i=1,4 do units[#units+1]="party"..i end
 else self.warned={};return end
 local present={}
 for _,unit in ipairs(units) do
  if UnitExists and UnitExists(unit) and UnitName then
   local name,realm=UnitName(unit)
   if safe(name) and safe(realm) and type(name)=="string" then
    local full=self:UnitFullName(name,realm)
    local key=full and self:Key(full)
    local entry=key and self:Get(full)
    if entry then
     present[key]=true
     if not self.warned[key] then
      self.warned[key]=true
      if print then print("|cffff8877Guilty Forever|r: "..entry.name.." joined your group. Reason: "..entry.reason) end
      if UIErrorsFrame then UIErrorsFrame:AddMessage("Guilty Forever: "..entry.name.." (reason in chat)",1,0.4,0.3) end
     end
    end
   end
  end
 end
 for key in pairs(self.warned) do if not present[key] then self.warned[key]=nil end end
end
-- Enemy-faction players cannot reliably be added to Blizzard's ignore list.
-- Use a separate private note kind and inspect only explicitly available unit IDs.
function A:EnemyTarget(unit)
 unit=unit or "target"
 if not (UnitExists and UnitIsPlayer and UnitIsEnemy and UnitName) then return nil end
 local okExists,exists=pcall(UnitExists,unit)
 local okPlayer,player=pcall(UnitIsPlayer,unit)
 local okEnemy,enemy=pcall(UnitIsEnemy,"player",unit)
 if not (okExists and okPlayer and okEnemy and safe(exists) and safe(player)
  and safe(enemy) and exists==true and player==true and enemy==true) then return nil end
 local name,realm=UnitName(unit)
 if not safe(name) or not safe(realm) or type(name)~="string" then return nil end
 local full=self:UnitFullName(name,realm)
 if not full or not self:IsFullName(full) then return nil end
 return full
end
function A:TagEnemyTarget(reason)
 local name=self:EnemyTarget("target")
 if not name then return false,"Target an enemy-faction player first." end
 if not self:Save(name,reason,"enemy") then return false,"Enter a reason for the enemy tag." end
 return true,name
end
function A:CheckEnemyTarget()
 if not KoolSupport:IsModuleEnabled("ks_guilty_forever") then return end
 local name=self:EnemyTarget("target")
 if not name then return end
 local entry=self:Get(name)
 -- Never match a first-name-only note against a different surname.
 if not entry or entry.kind~="enemy" then return end
 -- One reminder per player per session, rather than chat spam while PvPing.
 local key=self:Key(entry.name)
 if self.enemyWarned[key] then return end
 self.enemyWarned[key]=true
 if print then print("|cffff8877Guilty Forever|r: Enemy player "..entry.name.." spotted. Reason: "..entry.reason) end
 if UIErrorsFrame then UIErrorsFrame:AddMessage("Guilty Forever: "..entry.name.." (see chat)",1,0.4,0.3) end
end
function A:Start()
 if self.frame or type(CreateFrame)~="function" then return end
 self.frame=CreateFrame("Frame")
 for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","IGNORELIST_UPDATE","GROUP_ROSTER_UPDATE","PLAYER_TARGET_CHANGED"}) do
  self.frame:RegisterEvent(event)
 end
 self.frame:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then A:InstallIgnoreHooks(); A:Sync(true)
  elseif event=="IGNORELIST_UPDATE" then
   if C_Timer and C_Timer.After then C_Timer.After(0.2,function() A:Sync() end)
   else A:Sync() end
  elseif event=="PLAYER_TARGET_CHANGED" then A:CheckEnemyTarget()
  else A:CheckGroup(); A:CheckEnemyTarget() end
 end)
 self:InstallIgnoreHooks()
 if IsLoggedIn and IsLoggedIn() then self:Sync(true);self:CheckGroup() end
end
A:Start()
