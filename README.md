# win-setup-scripts

Small PowerShell tools I use when setting up a fresh Windows box.

## Debloat.ps1

Removes preinstalled Windows, OEM and promotional apps you don't want. It has a
GUI and a console mode, and only ever removes what you select. It is an app
remover, not a system optimizer: it does not touch Windows Update, Defender,
services, the registry (beyond one restore-point setting it reverts), scheduled
tasks, telemetry or power settings.

### What it does

- Lists the removable apps that are actually installed on this machine.
- Removes the ones you pick, for all user accounts, and deprovisions them so
  new accounts created later don't get them back.
- Can create a System Restore point first.
- Reports how many were removed, partially removed (removed for current users
  but still provisioned), failed, or weren't installed.

### What it does not do

- It does not touch your files: documents, pictures, downloads, OneDrive
  contents, browser data or saved games are not deleted.
- It never lists core components, so they can't be removed by accident: the
  Microsoft Store, Windows Terminal, Calculator, Photos, Snipping Tool, Windows
  Security, Camera, Notepad, Paint, the Xbox identity/framework packages games
  depend on, and the .NET / Visual C++ runtimes.
- It makes no performance claims. Removing apps frees some disk space and cuts a
  few background/startup entries. Whether you notice a speed difference depends
  on the machine, so the tool doesn't promise one.

### The three categories

- **Recommended (ticked by default).** Broadly unwanted promo and info apps: the
  Bing suite, the Office/Get-Office hub, 3D apps, Solitaire, personal Teams
  (Chat), Skype, Cortana, and preinstalled third-party promo apps (Candy Crush,
  Spotify, Netflix, TikTok and similar).
- **Optional (unticked by default).** Things plenty of people use, or that carry
  a consequence, so you opt in per item: Xbox apps, Phone Link, Media Player,
  Movies & TV, Copilot, the new unified Teams app (which may be your work
  client), Clipchamp, and Power Automate. All OEM apps are optional too, both
  the promo ones and the utilities that manage drivers or firmware (Lenovo
  Vantage, Dell SupportAssist, HP Support Assistant, and the HP/Dell promo
  apps). Also here: apps that hold your own data, since removing them can lose
  it. Sticky Notes, OneNote, Journal, and Mail & Calendar are in this group for
  that reason.
- **Protected (never listed).** The core components above are not in the tool at
  all, so no mode can select them.

`-Recommended` mode selects only the Recommended set; optional and protected
items are not included. If you want an optional app gone, tick it yourself in the
GUI or select it in the console menu.

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

Add `-SkipRestorePoint` to skip the restore point. The script needs admin rights
and will prompt for them. A sign-out or restart helps some changes settle.

### Review before you remove

Read the list before applying. Optional items are unticked on purpose. If you're
not sure what something is, leave it. Windows 10 and Windows 11 ship different
apps, and Microsoft renames packages between builds, so the list you see will
differ from machine to machine. The tool only shows apps that are present and
skips anything that isn't, rather than failing.

### Testing status

Runtime-tested on Windows 11 Enterprise Evaluation 25H2 (build 26200.6584) in a
Hyper-V VM. Verified there:

- A single Optional package and the full `-Recommended` set removed exactly the
  intended packages; current-user, all-users, and provisioned states were
  independently verified afterward.
- Optional, protected, and all other installed apps were left unchanged — no
  unintended additions or removals.
- The restore-point path worked from a machine with System Protection off: it
  enabled protection, created a point, confirmed it by sequence number, and
  removed its temporary creation-frequency setting afterward.
- The reported "removed" count matched independent verification.

Not yet runtime-tested (these are untested paths, not known problems):

- The `partial`, `failed`, and `absent` result branches (only clean removals
  occurred).
- Removal of real OEM and third-party/promo packages (the clean image had none),
  and most individual catalog entries.
- The GUI and `-NoGui` interactive flows, and the admin self-elevation prompt.
- The restore-point failure/abort path.
- Other Windows editions and builds.

Reversibility during testing came from Hyper-V checkpoints, not from the
debloater itself. Appx removal is not guaranteed to be undoable (see "About the
restore point").

### About the restore point

If you ask for a restore point, the script creates one and confirms it was
actually written before removing anything. (Windows normally skips a restore
point if one was made in the last 24 hours; the script lifts that limit for its
own call and puts the setting back.) In unattended `-Recommended` mode, if the
restore point can't be created it stops instead of removing apps without a
safety net. In the GUI and console it warns you and asks whether to continue.

A restore point is a recovery option, not a guarantee. Removing a Store app is
not always cleanly reversible. Some apps can be reinstalled from the Microsoft
Store afterwards, some are gone until the next feature update reprovisions them,
and a restore point rolls back system state but is not proof that every removal
can be perfectly undone. If an app matters to you, don't remove it.
