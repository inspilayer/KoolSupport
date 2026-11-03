-- Shared KoolSupport bar language: dark panel, pale/gold labels and readable colored bars.
-- UI frames use Blizzard's native widgets. No automatic protected actions.
local KS=KoolSupport
KS.BarTheme=KS.BarTheme or {}
local T=KS.BarTheme
T.colors={
  health={.26,.76,.53}, dot={.99,.71,.26}, bleed={.94,.34,.40},
  shadow={.69,.42,1}, border={.47,.54,.51}, background={.07,.12,.11}
}
T.texture="Interface\\TargetingFrame\\UI-StatusBar"
function T:StyleBar(bar,role)
  if not bar then return end
  local c=self.colors[role] or self.colors.dot
  bar:SetStatusBarTexture(self.texture)
  bar:SetStatusBarColor(c[1],c[2],c[3],1)
end
function T:FrameBackground(frame,alpha)
  local tex=frame:CreateTexture(nil,"BACKGROUND")
  tex:SetAllPoints()
  local c=self.colors.background
  tex:SetColorTexture(c[1],c[2],c[3],alpha or .8)
  return tex
end
