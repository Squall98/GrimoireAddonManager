> 🌐 [🇫🇷 Lire en français](../fr/FAQ.md) · [🏠 Home](../Home.md)

# ❓ Frequently asked questions

**I ticked an add-on and nothing changes.**
Click **Reload** at the bottom of the window. The game only loads add-ons when the interface restarts.

**Why do I always have to reload?**
Because of the game. GAM never reloads by itself: it lights up the **Reload** button and counts the changes waiting.

**Can GAM install, update or delete add-ons?**
No. The game does not allow it for any add-on. GAM can only turn on or off add-ons already in your AddOns folder. Use CurseForge or your usual tool to install or update; the “to remove” list is a reminder.

**An add-on is marked “outdated”.**
It was made for another game version. You can still load it with `/gam outdated on`, at your own risk.

**An add-on has no sheet.**
Its own description is shown instead. Click **Edit sheet** to write one yourself; `/gam nosheet` lists the add-ons without a sheet.

**Do I lose my settings if I reinstall GAM?**
No. Settings, profiles, notes, favourites and the log are in `WTF\Account\…\SavedVariables\`, not in the add-on folder.

**Can I give GAM to a friend?**
Yes, copy the `GrimoireAddonManager` folder. Nothing personal is inside. Your friend gets the shipped sheets and ready-made profiles; you can send your own profiles as MAA1 text.

**Are profiles per character?**
They are shared, but when you apply one you choose *This character* or *All characters*.

**What is the difference between “ticked” and “loaded”?**
Ticked: will be on after the next reload. Loaded: running now.

**My command is already used by another add-on.**
GAM refuses a taken name and tells you at startup; the other names still work. Add one: `/gam commands add ma`.

**I want the interface in English (or French).**
Use the **FR / EN** button at the top of the window, or `/gam language enUS` (`auto` follows the game).

**The text is too small or pale.**
Options › Window › Text size; Options › Sheets › Sheet background: plain.

**How do I replay the guided tour?**
`/gam tour`, or Options › Window › *Replay the guided tour*.

**The minimap button is in the way.**
Drag it around the minimap, or untick *Minimap button* in Options. The command and the Esc menu stay.

**Does it work on another version of WoW?**
It is made for WoW Forever (client 1.60.1). On another version it would be seen as outdated and is untested.

**Safe mode turned everything off, how do I go back?**
`/gam back`, then reload.

**An error makes a noise or opens a window every time.**
Options › Errors: *When a new error arrives* (window, chat line, nothing) and the sound option.

**What does GAM not do?**
It never turns itself off, never touches add-ons you did not ask about, and never sends anything on the internet.

Read also: [Errors and troubleshooting](Errors-and-troubleshooting.md).
