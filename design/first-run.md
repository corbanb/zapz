# First-run redesign: personas for 2027

**Status:** draft for review. Nothing here is built yet.
**Checked:** every Homebrew name below was confirmed in Homebrew's cask and
core repositories on 2026-11-09. App Store IDs still need confirming on a Mac.

## Decisions so far

| Question | Decision |
|---|---|
| Recommended terminal | **Ghostty** (iTerm2, Warp and Terminal offered) |
| Language versions | **mise** for Node, Python, Bun, Go… (replaces nvm) |
| Containers | **OrbStack** (Docker Desktop offered) |
| Security step | **Yes**: Touch ID for sudo, firewall on, FileVault check |
| Personas | Multi-select; each adds to the essentials |

## Principles for the experience

1. **Say what will happen before it happens.** Every screen ends with what
   the next step does and how long it takes.
2. **Recommend, don't interrogate.** Each question has a marked
   recommendation and a one-line reason. Enter always means "the
   recommended thing".
3. **Be honest about what zapz can't do.** App Store sign-ins, licenses and
   registration-walled downloads are listed up front and turned into a
   checklist at the end, not silent failures.
4. **Everything is reversible.** Backups, marked blocks, and
   `zapz --configure` to change your mind.

## Essentials (everyone)

| Area | Installed | Why |
|---|---|---|
| Foundation | Command Line Tools, Homebrew, `git`, `gh`, `git-lfs` | Everything else builds on these |
| Identity | git name/email, SSH key (Keychain), GitHub sign-in | Ready to clone and push on day one |
| Security | Touch ID for `sudo`, firewall on, FileVault check | Safer defaults with no extra effort |
| Everyday apps | `raycast`, `1password`, `the-unarchiver`, `appcleaner` | Launcher + window snapping + clipboard, passwords, archives, clean uninstalls |
| Browser (choose one) | `google-chrome`, `firefox`, `brave-browser`, or Safari only | Arc is discontinued (Homebrew disables it Dec 22) |
| Command line | `jq ripgrep fd fzf bat eza zoxide btop tlrc mas wget` | Modern, fast versions of everyday tools |
| Font | `font-jetbrains-mono-nerd-font` | Icons and ligatures in the terminal and editor |
| macOS | Dock, Finder and key-repeat defaults; `~/Pictures/Screenshots` | Less clutter, faster keyboard |
| Updates | Weekly background updates (launchd) | Stays current without thinking about it |

**Open questions**
- Is Raycast right for everyone, or optional? (It replaces Spotlight, Rectangle and a clipboard manager; some people dislike launchers.)
- Should a cloud drive be offered here (`google-drive`, `dropbox`), or left out?

## Terminal and shell

**Your terminal** (single choice)

| Option | Cask | One-line pitch |
|---|---|---|
| **Ghostty** (recommended) | `ghostty` | Fast, native and free. zapz sets the font and a theme. |
| iTerm2 | `iterm2` | The classic, with the most features (profiles, triggers, tmux). |
| Warp | `warp` | AI built into the terminal. Needs an account on first open. |
| Keep Terminal | (none) | Apple's built-in Terminal, with the font set. |

**Your shell** (single choice)

| Option | What it installs |
|---|---|
| **Recommended** | Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship` prompt, fzf and zoxide key bindings, `eza`/`bat` aliases |
| Light | `starship` prompt only |
| Leave it alone | Nothing |

All shell changes go in zapz's marked blocks, so they're easy to remove.

**Open question:** offer `atuin` (searchable shell history across Macs) as an
opt-in?

## Personas

### 1. Software developer
> *"I write and ship code."*

| Core | Optional (offered as add-ons) |
|---|---|
| `visual-studio-code` | `cursor`, `zed`, `jetbrains-toolbox` |
| `orbstack` (or `docker-desktop`) | `postman` |
| `mise` → Node LTS, Python, Bun | `deno`, `go`, `rust` (via mise) |
| `uv`, `pnpm` | `tableplus`, `bruno` |

**Open questions:** Is Python core or optional? Should the editor be a choice
(VS Code / Cursor / Zed) instead of "VS Code plus optional"?

### 2. AI builder
> *"I build with and on top of AI models."*

| Core | Optional |
|---|---|
| `claude` (desktop), `claude-code` | `codex`, `gemini-cli`, `opencode` |
| `chatgpt` | `perplexity` |
| `cursor` | `mstystudio`, `jan` |
| `ollama-app`, `lm-studio` | `llm` CLI |
| `uv` + Python (via mise), `jupyterlab` | `granola` (meeting notes), `wispr-flow` or `superwhisper` (voice dictation) |

**Open questions:** Should local models (Ollama, LM Studio, several GB each)
be core or optional? Should we pull a small starter model?

### 3. Video editor
> *"I cut and finish video."*

| Core | Optional |
|---|---|
| **DaVinci Resolve** (guided download: Blackmagic requires sign-up) | **Final Cut Pro** (App Store, purchase required) |
| `handbrake-app`, `iina` | `adobe-creative-cloud` |
| `ffmpeg` | `vlc`, `yt-dlp` |

**Open questions:** Default to Resolve (free) or Final Cut (paid, App
Store)? Add a "set up your media drive" checklist item?

### 4. Content creator and streamer
> *"I record, stream and publish."*

| Core | Optional |
|---|---|
| `obs` | `elgato-stream-deck`, `elgato-camera-hub`, `elgato-wave-link` |
| `descript`, `capcut` | `loopback`, `audio-hijack` (Rogue Amoeba, paid) |
| `canva` | `audacity` |
| `shottr`, `kap` (screenshots, GIFs) | `loom` |

**Open question:** split podcasters/musicians into their own persona (Logic
Pro, Loopback, Audio Hijack)?

### 5. Designer
> *"I design products, brands and visuals."*

| Core | Optional |
|---|---|
| `figma` | `framer`, `spline` |
| `affinity` (free; replaces Designer/Photo) | `adobe-creative-cloud` |
| `imageoptim`, `fontbase` | **Pixelmator Pro** (App Store) |

Blender is left out for now: Homebrew marks it to be deprecated on
2027-07-01.

### 6. Collaboration (add-on, any persona)
> *"I work with a team."*

`slack`, `zoom`, `notion`, `notion-calendar`, `obsidian`, `discord`, `granola`

### Candidates for more personas (your call)

| Persona | Would include |
|---|---|
| Mobile developer | `xcodes-app` (Xcode versions), `android-studio`, `cocoapods`, `watchman` |
| Data scientist | `positron`, `jupyterlab`, `uv`, Python and R via mise |
| Podcaster / musician | Logic Pro (App Store), `loopback`, `audio-hijack`, `audacity` |
| Maker | `bambu-studio`, `karabiner-elements`, `hammerspoon` |

## Things zapz can't install by itself

| App | Why | What zapz does |
|---|---|---|
| Final Cut Pro, Logic Pro, Pixelmator Pro | App Store purchase + sign-in | Installs with `mas` if you're signed in and own it; otherwise adds a checklist item that opens the App Store page |
| DaVinci Resolve | Download requires registration | Opens the download page; checklist item |
| Licenses and sign-ins (1Password, Adobe, OrbStack, Warp) | Need you | Listed on the finish screen; each opens the app |

## The flow and its copy (draft)

**1. Welcome**
> **Let's get your Mac ready.**
> Three steps: tell me a little about you (about 2 minutes), review the
> plan, then let it run (usually 20–40 minutes). Nothing changes until you
> say go.

**2. About you**
> **First, who's setting up this Mac?**
> Name: Corban Baxter *(from your Mac account)*
> Email for git commits: ________

**3. What you do**
> **What will you use this Mac for?** Pick all that apply, e.g. `1 2 6`.
> You can change this any time with `zapz --configure`.
>
>   1  Software development   editors, containers, languages
>   2  AI tools               Claude, ChatGPT, Cursor, local models
>   3  Video editing          DaVinci Resolve, Final Cut Pro, HandBrake
>   4  Content & streaming    OBS, Descript, CapCut, Canva
>   5  Design                 Figma, Affinity, Pixelmator Pro
>   6  Team collaboration     Slack, Zoom, Notion

**4. Add-ons** (one screen per chosen persona, only optional items)
> **Software development: a few extras?** Recommended ones are marked.
> [x] Cursor   [ ] Zed   [ ] JetBrains Toolbox   [x] TablePlus …

**5. Terminal, shell, browser**: one screen each, as above.

**6. The plan**
> **Here's your Mac.** About 25 minutes and 14 GB.
> *(grouped by category; "already installed" shown dimmed)*
>
> **You'll need to:** sign in to the App Store for Final Cut Pro · finish
> the DaVinci Resolve download (we'll open the page) · sign in to
> 1Password.
>
> Continue? [Y/n]

**7. Running**: same as today, with category headers.

**8. Finish**
> **Your Mac is ready. ⚡**
> 3 things only you can do. Press Enter to open each:
>   1  Sign in to 1Password
>   2  Finish installing DaVinci Resolve
>   3  Turn on FileVault (System Settings → Privacy & Security)

## Build notes (for later)

- Persona files merge: `essentials.yml` + each chosen persona (lists
  concatenated, de-duplicated).
- New config sections: `apps.mas` (App Store IDs), `apps.manual` (name,
  URL, note), `terminal` (app, theme, font), `shell` (framework, prompt,
  plugins), `security` (touch_id_sudo, firewall, filevault_check).
- New steps: **Terminal & shell**, **Security**. `mise` replaces the nvm
  module (with a migration note for existing nvm users).
- Plan screen: estimated time and size per persona (rough, from a lookup
  table).
- Existing presets (`essentials`, `webdev`, `minimal`) become the new
  essentials and developer personas.
