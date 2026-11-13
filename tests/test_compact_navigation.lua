-- Compact host navigation: groups pages instead of showing a wall of buttons.
KoolSupport={
 VERSION="0.10.10-rc.1",pages={},pageOrder={},moduleOrder={},
 modules={},
}
local K=KoolSupport
function K:RegisterPage(page)
 self.pages[page.id]=page
 self.pageOrder[#self.pageOrder+1]=page.id
end
function K:CanOpenPage(id) return self.pages[id]~=nil end
function K:CollectLaunchChecks()return {} end
function K:IsModuleEnabled()return true end
local widgets={}
local function mk(kind)
 local frame={kind=kind,hidden=false}
 function frame:SetPoint(...)self.point={...}end
 function frame:ClearAllPoints()self.point=nil end
 function frame:SetAllPoints(x)self.allPoints=x end
 function frame:SetSize(w,h)self.width=w;self.height=h end
 function frame:SetWidth(w)self.width=w end
 function frame:SetJustifyH()end
 function frame:SetText(value)self.text=value end
 function frame:SetScript(ev,fn)self.scripts=self.scripts or {};self.scripts[ev]=fn end
 function frame:SetFontString(item)self.fontstring=item end
 function frame:EnableMouse(v)self.mouse=v end
 function frame:CreateFontString()return mk("FontString")end
 function frame:SetFrameStrata()end
 function frame:SetMovable()end
 function frame:RegisterForDrag()end
 function frame:SetBackdrop()end
 function frame:SetScale()end
 function frame:Show()self.hidden=false end
 function frame:Hide()self.hidden=true end
 function frame:IsShown()return not self.hidden end
 function frame:GetWidth()return 1600 end
 function frame:GetHeight()return 900 end
 return frame
end
CreateFrame=function(kind)
 local f=mk(kind)
 widgets[#widgets+1]=f
 return f
end
UIParent=mk("Frame")
UISpecialFrames={}
assert(loadfile("addons/KoolSupport/UI.lua"))()
for _,item in ipairs({
 {"macro_suite","Macro Suite"},{"full_spellbook","Spellbook"},
 {"macro_workshop","Builder"},{"support_session","Support Sessions"},
 {"afflictions","KS Afflictions"},{"ks_threat","KS Threat"},
 {"stealth","KS Stealth"},{"stealth_talents","Talents"},
 {"campfire_chat","Campfire Chat"},
}) do
 K:RegisterPage({id=item[1],title=item[2],build=function()end})
end
local function findCaption(term,onlyVisible)
 for _,item in ipairs(widgets) do
  if item.caption and item.caption.text and item.caption.text:find(term,1,true)
    and (not onlyVisible or not item.hidden) then return item end
 end
end
K:Open("home")
assert(findCaption("COMBAT",true) and findCaption("MACROS",true))
assert(not findCaption("KS Afflictions",true),"Collapsed nav should not expose every page")
local combat=findCaption("COMBAT",true)
combat.scripts.OnClick()
assert(findCaption("KS Afflictions",true),"Combat category expands")
assert(findCaption("KS Threat",true) and findCaption("KS Stealth",true))
assert(not findCaption("Builder",true),"Unselected category should remain folded")
local afflictions=findCaption("KS Afflictions",true)
afflictions.scripts.OnClick()
assert(findCaption("KS Afflictions",true),"Active page remains visible")
local macros=findCaption("MACROS",true)
macros.scripts.OnClick()
assert(findCaption("Builder",true))
assert(not findCaption("KS Afflictions",true),"Only one group should expand")
local visible=0
for _,item in ipairs(widgets) do
 if item.caption and not item.hidden then visible=visible+1 end
end
assert(visible<=11,"Compact nav must not render a long column of buttons")
print("PASS compact navigation: grouped sidebar, active page, bounded controls")
