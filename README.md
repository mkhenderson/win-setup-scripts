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
- Optional stuff (Xbox, Phone Link, Media Player) is left unticked by default.
- It can drop a system restore point before it starts.

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
