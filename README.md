# win-setup-scripts

A couple of PowerShell scripts I use when setting up a fresh Windows install,
mostly so I'm not clicking through the same cleanup by hand every time.

## Debloat.ps1

Gets rid of the preinstalled Windows, OEM, and promo apps nobody asked for
(looking at you, Candy Crush). There's a GUI and a console version, and it only
ever removes what you actually pick. It's an app remover, not one of those
"optimizer" tools: it doesn't touch Windows Update, Defender, services, the
registry (other than one restore-point setting it puts back), scheduled tasks,
telemetry, or power settings.

### What it does

- Shows the removable apps that are actually installed on your machine.
- Removes the ones you pick, for every user account, and deprovisions them so new
  accounts don't get them back later.
- Can make a System Restore point first.
- Tells you how many got removed, partially removed (gone for users but still
  provisioned), failed, or weren't there to begin with.

### What it doesn't do

- It leaves your files alone: documents, pictures, downloads, OneDrive, browser
  data, saved games, none of that gets deleted.
- It never even lists the core stuff, so you can't nuke it by accident: the
  Store, Windows Terminal, Calculator, Photos, Snipping Tool, Windows Security,
  Camera, Notepad, Paint, the Xbox identity/framework bits games need, and the
  .NET / Visual C++ runtimes.
- It doesn't promise to make your PC faster. You get back some disk space and a
  few less startup/background things running. Whether it actually feels snappier
  is between you and your PC.

### The three categories

- **Recommended (ticked by default).** The stuff most people don't want: the Bing
  suite, the Office/Get-Office hub, 3D apps, Solitaire, personal Teams (Chat),
  Skype, Cortana, and preinstalled promo junk (Candy Crush, Spotify, Netflix,
  TikTok, that kind of thing).
- **Optional (unticked by default).** Stuff plenty of people actually use, or that
  could bite you, so you opt in yourself: Xbox apps, Phone Link, Media Player,
  Movies & TV, Copilot, the new unified Teams (might be your work one), Clipchamp,
  and Power Automate. All the OEM apps live here too, both the junk and the
  driver/firmware ones (Lenovo Vantage, Dell SupportAssist, HP Support Assistant,
  and the HP/Dell promo apps). Anything that holds your own data is here as well,
  since removing it can lose it: Sticky Notes, OneNote, Journal, and Mail &
  Calendar.
- **Protected (never listed).** The core stuff above isn't in the tool at all, so
  no mode can pick it.

`-Recommended` mode only touches the Recommended set. Optional and protected stuff
isn't included. If you want an optional app gone, tick it yourself in the GUI or
pick it in the console menu.

### Running it

**GUI (default).** Right-click `Debloat.ps1` and hit **Run with PowerShell**, or
from a terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1
```

**Console menu, no GUI.** Numbered list, pick what you want:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1 -NoGui
```

**No prompts.** Removes the recommended set and exits, handy for a fresh setup:

```powershell
powershell -ExecutionPolicy Bypass -File .\Debloat.ps1 -Recommended
```

Add `-SkipRestorePoint` to skip the restore point. It needs admin and will ask
for it. A sign-out or restart helps some of the changes settle.

### Have a look before you remove

Read the list before you apply it. The optional stuff is unticked for a reason.
If you're not sure what something is, just leave it. Windows 10 and 11 ship
different apps and Microsoft renames packages between builds, so what you see will
be different machine to machine. The tool only shows what's actually installed and
skips the rest instead of erroring out.

### Testing status

Runtime-tested on Windows 11 Enterprise Evaluation 25H2 (build 26200.6584) in a
Hyper-V VM. What I confirmed there:

- Removing a single optional app and the full `-Recommended` set took out exactly
  what they should; I checked current-user, all-users, and provisioned state after
  each.
- Optional, protected, and everything else installed was left alone, nothing extra
  added or removed.
- The restore-point path worked from a machine with System Protection off: it
  turned protection on, made a point, confirmed it by sequence number, and put its
  temporary setting back after.
- The reported "removed" count matched what I actually saw.
- Both the GUI and the console (`-NoGui`) got run end to end: the GUI opened and
  loaded the list with a working select and Apply/confirm, and `-NoGui` showed the
  menu and took a numbered pick.
- Removals in both were real per-user and all-users uninstalls plus deprovisioning,
  the counts matched independent checks, nothing protected or unrelated got
  removed, and the VM went back to its clean checkpoint after.

Not tested yet (just untested, not known problems):

- The `partial`, `failed`, and `absent` result cases (only clean removals
  happened).
- Removing real OEM and third-party/promo apps (the clean image didn't have any),
  and most of the individual catalog entries.
- The admin self-elevation prompt on its own.
- The restore-point failure/abort path.
- Other Windows editions and builds.

Reversibility during testing came from the Hyper-V checkpoint, not the tool itself.
Removing an Appx package isn't guaranteed to be undoable (see the restore point
note below).

### About the restore point

If you ask for a restore point, the script makes one and checks it actually got
written before removing anything. (Windows normally skips a restore point if it
made one in the last 24 hours, so the script lifts that limit for its own call and
puts the setting back after.) In unattended `-Recommended` mode, if it can't make
the restore point it stops instead of removing stuff with no safety net. In the
GUI and console it warns you and asks if you want to keep going.

A restore point is a safety net, not a guarantee. Removing a Store app isn't always
cleanly undoable. Some apps you can reinstall from the Store after, some stay gone
until the next big Windows update puts them back, and a restore point rolls back
system state but isn't proof every removal can be perfectly undone. If an app
matters to you, don't remove it.
