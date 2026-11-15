# KoolSupport 0.10.13-rc.1 — Base Time Since XP reminder

**Unpublished development candidate; not a new CurseForge Beta.**

## Time Since Last Experience — Base

A small, player-only reminder to encourage getting out of town and leveling:

- When **15 minutes** pass without gaining XP, KoolSupport displays a short center-screen notification (where supported) and a local chat message: **“15 minutes without XP! Get out of town and earn some experience.”**
- Nudges recur at 30, 45, 60 minutes, etc., as long as no XP is earned. Only one notice is emitted after a long pause/AFK rather than a backlog.
- Your actual player XP increase or level-up restarts the 15-minute clock. Spurious unchanged XP events do not reset it. Zoning does not reset it.
- Each login or UI reload starts a fresh timer; it does not nag you about overnight or logged-out time.
- At max level, XP reminders pause automatically. On clients where XP eligibility cannot be established safely, no alert is emitted.
- **Enabled by default per character.** Open `/kool` → **Tools → Time Since XP** (also on the Home page) to view elapsed time, next reminder, turn the feature ON/OFF, or test a notification without changing the timer.
- No movement, quest automation, macro edits, extra addon folders, game-chat broadcasts, or combat health inspection.

## Packaging and safety

Loaded from Base `XPReminder.lua` in the single `KoolSupport.toc`. The existing six nested modules, SavedVariables, third-party MIT Afflictions vendor, KS Threat and macros are unchanged.

CI covers actual gain versus unchanged updates, level-up rollovers, 15-minute boundaries, max-level/disabled/secret conditions, session/zoning behavior, and Base UI controls. Require the full Lua suite and real one-root CurseForge packaging dry run, plus an actual 15-minute Forever client test prior to Beta publishing. No release tag is created automatically.
