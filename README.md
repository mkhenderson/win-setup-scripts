# win-setup-scripts

Small PowerShell tools I use when setting up a fresh Windows box.

## Debloat.ps1

A little GUI for removing the built-in apps most people don't use (News,
Weather, the Office hub, Solitaire, Teams personal, Cortana and so on).

- Nothing happens until you tick boxes and click **Apply**.
- Only the apps you tick are removed.
- Essentials are never listed, so you can't nuke them by mistake: the Store,
  Windows Terminal, Calculator, Photos, Snipping Tool, Windows Security and
  the .NET / Visual C++ runtimes.
- It can drop a system restore point before it starts.

### What's ticked by default

The list covers Microsoft apps, the Bing suite, preinstalled third-party junk
(Candy Crush, Spotify, TikTok and friends) and common HP / Dell / Lenovo extras.
Defaults follow the same lines the debloat community draws:

- **On by default:** clearly unused promo and info apps.
- **Off by default:** anything that holds your data (Sticky Notes, Mail,
  OneNote), things plenty of people use (Xbox, Phone Link, Media Player), and a
  few that are touchy to remove (Get Help, Bing web search) or that manage your
  hardware (Lenovo Vantage, Dell SupportAssist, HP Support Assistant).

Only apps actually installed on the machine show up, so the list is short on
most PCs. The default tiers were cross-checked against the Raphire/Win11Debloat
and ChrisTitusTech/winutil app lists.

### Running it

**GUI (default).** Right-click `Debloat.ps1` and choose **Run with PowerShell**,
or from a terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1
```

**Console menu, no GUI.** Numbered list, pick what you want:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1 -NoGui
```

**No prompts.** Removes the recommended set and exits, handy for a setup run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1 -Recommended
```

Add `-SkipRestorePoint` to skip the restore point. It needs admin rights and
will prompt for them.

Removal applies to all user accounts on the machine and also deprovisions the
apps so new accounts don't get them back. A sign-out or restart helps the
changes settle.
