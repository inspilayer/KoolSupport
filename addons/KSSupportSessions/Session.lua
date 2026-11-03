-- Optional named-focus support presets. Never automatically plays another client.
KSSupportSessions=KSSupportSessions or {}
local S=KSSupportSessions
local CLASS_ORDER={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local ACTIVE={DRUID=true,PALADIN=true,SHAMAN=true,PRIEST=true}
local function supportStore()
  local db=KoolSupport:GetDatabase()
  db.modules=db.modules or {}
  db.modules.ks_support_sessions=db.modules.ks_support_sessions or {}
  local s=db.modules.ks_support_sessions
  if not s.migrationDone then
    -- Read legacy preferences but never delete or overwrite the originals.
    if s.character==nil and type(db.character)=="string" then s.character=db.character end
    if s.recipientClass==nil and type(db.recipientClass)=="string" then s.recipientClass=db.recipientClass end
    if s.spec==nil and type(db.spec)=="string" then s.spec=db.spec end
    s.migrationDone=true
  end
  s.enabled=s.enabled or {}
  return s
end
S.Store=supportStore
local function validCharacter(name)
  if type(name)~="string" then return nil end
  name=name:match("^%s*(.-)%s*$")
  if #name<1 or #name>60 or name:find("[%c/;\\%[%]{}<>|]") then return nil end
  return name
end
function S:Build(playerClass,spec,recipientClass,recipientName)
  if not ACTIVE[playerClass] then return nil,"Support presets are available for Druid, Paladin, Shaman and Priest" end
  local name=validCharacter(recipientName)
  if not name then return nil,"Choose the character you are supporting" end
  return KSSupportProfiles.Build(playerClass,spec,recipientClass,name)
end
function S:GetEnabled(def)
  local data=supportStore()
  if data.enabled[def.name]~=nil then return data.enabled[def.name] end
  -- Read legacy class/recipient preferences as a fallback, never modify them.
  local root=KoolSupport:GetDatabase()
  local playerClass=nil
  if type(UnitClass)=="function" then local _,class=UnitClass("player"); playerClass=class end
  local spec=data.spec or (playerClass=="PRIEST" and "Holy" or "Restoration")
  local recipient=data.recipientClass or "WARRIOR"
  local key=(playerClass or "NONE")..":"..spec..":"..recipient
  local settings=type(root.enabledProfiles)=="table" and root.enabledProfiles[key]
  if type(settings)=="table" and settings[def.name]~=nil then return settings[def.name] end
  return def.default~=false
end
function S:SetEnabled(name,value)
  supportStore().enabled[name]=not not value
end
function S:InstallSelected(defs)
  if KoolSupport:IsInCombat() then return false,"Cannot install macros in combat" end
  if type(defs)~="table" then return false,"No templates" end
  local selected={}
  for _,def in ipairs(defs) do
    if self:GetEnabled(def) then selected[#selected+1]={name=def.name,body=def.body} end
  end
  return KSMacros:InstallBatch(selected)
end

function S.BuildPage(parent)
  local function label(v,x,y,w)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(w or 730);f:SetJustifyH("LEFT");f:SetText(v);return f
  end
  local function button(text,x,y,w,fn)
    local f=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    f:SetSize(w,29);f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetText(text);f:SetScript("OnClick",fn);return f
  end
  label("|cffffd87aSupport Session Setup|r",18,-18,740)
  label("Create named-focus healing, utility and follow macros. You still press every button.",18,-52,755)
  local store=supportStore()
  local character=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  character:SetSize(215,26);character:SetPoint("TOPLEFT",parent,"TOPLEFT",18,-105)
  character:SetAutoFocus(false);character:SetText(store.character or "")
  label("Supportee name",18,-82,210)
  local class=UnitClass and select(2,UnitClass("player")) or "DRUID"
  local recipient=store.recipientClass or "WARRIOR"
  local spec=store.spec or "Holy"
  local classButton, specButton, status
  local getSpec=function()return class=="PRIEST" and spec or (class=="DRUID" and "Restoration / hybrid" or (class=="SHAMAN" and "Restoration" or "Holy")) end
  local templates,page={},1
  local list={}
  local draw
  local function refresh()
    local defs,why=S:Build(class,getSpec(),recipient,character:GetText())
    if not defs then templates={};status:SetText(why) else templates=defs end
    page=math.min(page,math.max(1,math.ceil(#templates/8)))
    if classButton then classButton:SetText("Supportee class: "..recipient) end
    if specButton then specButton:SetText("Build: "..getSpec()) end
    draw()
  end
  classButton=button("Supportee class: "..recipient,251,-103,220,function()
    for i,v in ipairs(CLASS_ORDER) do if v==recipient then recipient=CLASS_ORDER[i%#CLASS_ORDER+1];break end end
    refresh()
  end)
  specButton=button("Build: "..getSpec(),487,-103,240,function()
    if class=="PRIEST" then spec=spec=="Holy" and "Discipline" or "Holy" end
    refresh()
  end)
  status=label("",18,-542,780)
  label("Your class: "..tostring(class).."  |  Tick the presets you want generated.",18,-145,755)
  local function updateRows()
    for i,row in ipairs(list) do
      local def=templates[(page-1)*8+i]
      row.check:SetShown(def~=nil);row.name:SetShown(def~=nil)
      if def then
        row.check:SetChecked(S:GetEnabled(def))
        row.name:SetText(def.caption.."   ["..def.group.."]")
        row.check:SetScript("OnClick",function(self)S:SetEnabled(def.name,self:GetChecked())end)
        row.name:SetScript("OnEnter",function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine(def.caption,1,.9,.6)
            GameTooltip:AddLine(def.body,.7,.9,.8,true)
            GameTooltip:Show()
          end
        end)
        row.name:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
      end
    end
  end
  draw=function()updateRows()end
  for i=1,8 do
    local y=-185-(i-1)*39
    local check=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    check:SetPoint("TOPLEFT",parent,"TOPLEFT",18,y)
    local name=label("",65,y-9,700)
    list[i]={check=check,name=name}
  end
  button("Previous",18,-501,125,function()page=math.max(1,page-1);draw()end)
  button("Next",154,-501,125,function()page=math.min(math.max(1,math.ceil(#templates/8)),page+1);draw()end)
  button("Generate selected",528,-499,198,function()
    store.character=validCharacter(character:GetText())
    if not store.character then status:SetText("Enter your supportee's character name");return end
    store.recipientClass=recipient;store.spec=spec
    local defs,why=S:Build(class,getSpec(),recipient,store.character)
    if not defs then status:SetText(why);return end
    local ok,result=S:InstallSelected(defs)
    status:SetText(result)
  end)
  refresh()
end
