-- Private notes only: no automatic ignore, party departure or chat messages.
KSGuiltyForever=KSGuiltyForever or {}
local A=KSGuiltyForever
A.pending={}
A.seen={}
A.warned={}
local function safe(v)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,v)
  if not ok or secret then return false end
 end
 return true
end
function A:Key(name)
 if not safe(name) or type(name)~="string" then return nil end
 name=name:match("^%s*(.-)%s*$")
 if #name<2 or #name>100 or name:find("[%c|]") or not name:match("^[%w'%-]+$") then return nil end
 return name:lower()
end
function A:Store()
 local db=KoolSupport:GetDatabase()
 db.modules=db.modules or {}
 db.modules.ks_guilty_forever=db.modules.ks_guilty_forever or {}
 local s=db.modules.ks_guilty_forever
 s.notes=s.notes or {}
 return s
end
function A:Save(name,reason)
 local key=self:Key(name)
 if not key or not safe(reason) or type(reason)~="string" then return false end
 reason=reason:sub(1,500):match("^%s*(.-)%s*$")
 if reason=="" then return false end
 local old=self:Store().notes[key]
 self:Store().notes[key]={name=name,reason=reason,created=(old and old.created) or (time and time() or 0)}
 return true
end
function A:Get(name)
 local key=self:Key(name)
 return key and self:Store().notes[key] or nil
end
function A:Delete(name)
 local key=self:Key(name)
 if key then self:Store().notes[key]=nil;return true end
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
   if e then A:Save(data,e:GetText()) end
   A.pending[A:Key(data)]=nil
  end,
  OnCancel=function(_,data)
   local k=A:Key(data)
   if k then A.pending[k]=nil end
  end,
 }
 StaticPopup_Show("KS_GUILTY_FOREVER",name,nil,name)
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
    local full=(type(realm)=="string" and realm~="") and name.."-"..realm or name
    local key=self:Key(full)
    local entry=key and self:Store().notes[key]
    if not entry then key=self:Key(name);entry=key and self:Store().notes[key] end
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
function A:Start()
 if self.frame or type(CreateFrame)~="function" then return end
 self.frame=CreateFrame("Frame")
 for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","IGNORELIST_UPDATE","GROUP_ROSTER_UPDATE"}) do
  self.frame:RegisterEvent(event)
 end
 self.frame:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_LOGIN" then A:Sync(true)
  elseif event=="IGNORELIST_UPDATE" then
   if C_Timer and C_Timer.After then C_Timer.After(0.2,function() A:Sync() end)
   else A:Sync() end
  else A:CheckGroup() end
 end)
 if IsLoggedIn and IsLoggedIn() then self:Sync(true);self:CheckGroup() end
end
A:Start()
