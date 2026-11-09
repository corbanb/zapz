---
layout: docs
title: Personas and Extras
icon: fas fa-user-check
description: What each choice in the setup wizard installs
---

The setup wizard asks "What will you use this Mac for?" and lets you pick any
number of personas, then offers a few extras (packs). Each one adds to the
essentials, which every Mac gets. This page lists what each choice installs,
taken from the files in
[`catalog/`](https://github.com/corbanb/zapz/tree/main/catalog).

- **Always installed** items come with the persona or pack as soon as you pick
  it.
- The other tables are the follow-up questions the wizard asks for that
  choice. **★** marks a recommended item: it's ticked by default, and pressing
  Enter takes the ★ items. Answer `0` to pick none.
- **Installed with** says how zapz gets each item:
  - **Homebrew** / **Homebrew cask**: installed during setup.
  - **mise**: a language or tool version, installed by the Languages step
    (see [`languages.tools`]({{ site.baseurl }}/configuration/#languages)).
  - **App Store**: installed with `mas` if you're signed in to the App Store
    and own the app; otherwise added to the checklist with a link to its page.
  - **Guided download**: not installable automatically. Its download page is
    added to the checklist at the end of setup, and zapz offers to open it.
  - **Command to run**: shown in the checklist at the end for you to run
    yourself.
- "checklist: …" in Notes is a step zapz adds to "Things only you can do" at
  the end of setup, such as signing in.

Picking the same item from two personas installs it once. To add or change
an item, see [Add an app to a persona]({{ site.baseurl }}/docs/recipes/#add-an-app-to-a-persona-catalog).

## Essentials

*what every Mac gets*

Everyone gets these, whatever they pick. Setup also always handles the
Command Line Tools, Homebrew, git, an SSH key and the security defaults, and
the wizard's own questions add your terminal (Ghostty, iTerm2 or Warp) and,
for the shell setup, `starship` (plus `zsh-autosuggestions` and
`zsh-syntax-highlighting` for Recommended). See
[The setup wizard]({{ site.baseurl }}/docs/#the-setup-wizard).

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| git | Homebrew (`git`) |  |
| GitHub CLI | Homebrew (`gh`) |  |
| git-lfs | Homebrew (`git-lfs`) |  |
| jq | Homebrew (`jq`) |  |
| ripgrep | Homebrew (`ripgrep`) |  |
| fd | Homebrew (`fd`) |  |
| fzf | Homebrew (`fzf`) |  |
| bat | Homebrew (`bat`) |  |
| eza | Homebrew (`eza`) |  |
| zoxide | Homebrew (`zoxide`) |  |
| btop | Homebrew (`btop`) |  |
| tlrc | Homebrew (`tlrc`) |  |
| mas | Homebrew (`mas`) |  |
| wget | Homebrew (`wget`) |  |
| 1Password | Homebrew cask (`1password`) | checklist: Sign in to 1Password |
| The Unarchiver | Homebrew cask (`the-unarchiver`) |  |
| AppCleaner | Homebrew cask (`appcleaner`) |  |
| JetBrains Mono Nerd Font | Homebrew cask (`font-jetbrains-mono-nerd-font`) |  |

**Which browser do you want?** (choose one)

| Item | Installed with | Notes |
| --- | --- | --- |
| Chrome ★ | Homebrew cask (`google-chrome`) | works everywhere |
| Firefox | Homebrew cask (`firefox`) | independent and private |
| Brave | Homebrew cask (`brave-browser`) | blocks ads and trackers |
| Safari only | Nothing installed | nothing extra to install |

**Cloud storage?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Google Drive | Homebrew cask (`google-drive`) | checklist: Sign in to Google Drive |
| Dropbox | Homebrew cask (`dropbox`) | checklist: Sign in to Dropbox |


## Personas

### Software development

*editors, containers, languages*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| VS Code | Homebrew cask (`visual-studio-code`) |  |
| mise | Homebrew (`mise`) |  |
| Node.js, Bun, pnpm, Python | mise (`node@lts`, `bun@latest`, `pnpm@latest`, `python@3.13`) |  |
| uv | Homebrew (`uv`) |  |

**Containers?** (choose one)

| Item | Installed with | Notes |
| --- | --- | --- |
| OrbStack ★ | Homebrew cask (`orbstack`) | light and fast; free for personal use; checklist: Open OrbStack to finish setup |
| Docker Desktop | Homebrew cask (`docker-desktop`) | the official tool; paid for larger companies; checklist: Open Docker Desktop to finish setup |
| None | Nothing installed |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Cursor ★ | Homebrew cask (`cursor`) | AI code editor |
| Zed | Homebrew cask (`zed`) | fast, collaborative editor |
| JetBrains Toolbox | Homebrew cask (`jetbrains-toolbox`) | IntelliJ, WebStorm, PyCharm and more |
| Bruno ★ | Homebrew cask (`bruno`) | API client |
| Postman | Homebrew cask (`postman`) | API platform |
| TablePlus | Homebrew cask (`tableplus`) | database app |
| DBeaver | Homebrew cask (`dbeaver-community`) | free database app |
| Deno | mise (`deno@latest`) |  |
| Go | mise (`go@latest`) |  |
| Rust | mise (`rust@latest`) |  |

### AI building

*Claude, ChatGPT, Cursor, agent tools*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Claude | Homebrew cask (`claude`) | checklist: Sign in to Claude |
| Claude Code | Homebrew cask (`claude-code`) |  |
| ChatGPT | Homebrew cask (`chatgpt`) | checklist: Sign in to ChatGPT |
| Cursor | Homebrew cask (`cursor`) |  |
| mise | Homebrew (`mise`) |  |
| Node.js and Python | mise (`node@lts`, `python@3.13`) |  |
| uv | Homebrew (`uv`) |  |
| JupyterLab | Homebrew (`jupyterlab`) |  |

**Run several coding agents at once?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Conductor ★ | Homebrew cask (`conductor`) | parallel Claude Code and Codex agents |
| T3 Code | Homebrew cask (`t3-code`) | one app for Claude Code, Codex and Cursor |
| Paperclip | Command to run: `npx paperclipai@latest onboard --yes` | runs AI agents as a company (open source) |

**More AI tools?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Codex CLI | Homebrew cask (`codex`) | OpenAI's coding agent |
| Antigravity CLI | Homebrew cask (`antigravity-cli`) | Google's Gemini agents in the terminal |
| OpenCode | Homebrew (`opencode`) | open-source coding agent |
| Cursor CLI | Homebrew cask (`cursor-cli`) |  |
| Perplexity | Homebrew cask (`perplexity`) | AI answer engine |
| llm | Homebrew (`llm`) | talk to models from the command line |
| Msty Studio | Homebrew cask (`mstystudio`) | local and online models in one app |
| Jan | Homebrew cask (`jan`) | open-source ChatGPT alternative |

### Mobile apps

*Xcode, Android Studio, Flutter*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Xcodes | Homebrew cask (`xcodes-app`) |  |
| xcodes | Homebrew (`xcodes`) |  |
| Install Xcode | Command to run: `xcodes install --latest` | asks for your Apple ID |
| Android Studio | Homebrew cask (`android-studio`) |  |
| Android platform tools | Homebrew cask (`android-platform-tools`) |  |
| CocoaPods | Homebrew (`cocoapods`) |  |
| watchman | Homebrew (`watchman`) |  |
| fastlane | Homebrew (`fastlane`) |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Flutter | Homebrew cask (`flutter`) | one codebase for iOS and Android |
| Expo (EAS CLI) | mise (`node@lts`, `npm:eas-cli`) | React Native builds; also adds mise (Homebrew (`mise`)) |
| VS Code ★ | Homebrew cask (`visual-studio-code`) |  |
| Cursor | Homebrew cask (`cursor`) | AI code editor |

### Game development

*Unity, Godot, Unreal*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Unity Hub | Homebrew cask (`unity-hub`) | checklist: Sign in to Unity Hub and install an editor |
| Godot | Homebrew cask (`godot`) |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Epic Games Launcher | Homebrew cask (`epic-games`) | for Unreal Engine; checklist: Install Unreal Engine from the Epic Games Launcher |
| Blockbench | Homebrew cask (`blockbench`) | low-poly 3D models |
| Tiled | Homebrew cask (`tiled`) | level editor |
| Aseprite | Guided download ([page](https://www.aseprite.org/)) | pixel art (paid) |
| Blender | Homebrew cask (`blender`) | 3D; Homebrew may drop it in July 2027 |

### Data science

*Positron, Jupyter, DuckDB*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Positron | Homebrew cask (`positron`) |  |
| JupyterLab | Homebrew (`jupyterlab`) |  |
| DuckDB | Homebrew (`duckdb`) |  |
| DBeaver | Homebrew cask (`dbeaver-community`) |  |
| uv | Homebrew (`uv`) |  |
| mise | Homebrew (`mise`) |  |
| Python | mise (`python@3.13`) |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Quarto ★ | Homebrew cask (`quarto`) | reports and notebooks |
| R | Homebrew cask (`r-app`) |  |
| RStudio | Homebrew cask (`rstudio`) |  |
| Tableau | Homebrew cask (`tableau`) | paid |
| Miniconda | Homebrew cask (`miniconda`) | conda environments |

### Video editing

*Resolve, Final Cut, Premiere, Edits*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| HandBrake | Homebrew cask (`handbrake-app`) |  |
| IINA | Homebrew cask (`iina`) |  |
| ffmpeg | Homebrew (`ffmpeg`) |  |

**Which editors do you use?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| DaVinci Resolve | Guided download ([page](https://www.blackmagicdesign.com/products/davinciresolve)) | free; Blackmagic asks you to register |
| Final Cut Pro | App Store (id `424389933`) | paid; from the App Store |
| Premiere Pro | Homebrew cask (`adobe-creative-cloud`) | through Adobe Creative Cloud; checklist: Sign in to Creative Cloud and install Premiere Pro |
| Edits by Instagram | Guided download ([page](https://edits.instagram.com/)) | free; Apple Silicon |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| VLC | Homebrew cask (`vlc`) |  |
| yt-dlp | Homebrew (`yt-dlp`) | download video for editing |

### Content & streaming

*OBS, Descript, CapCut, Canva*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| OBS | Homebrew cask (`obs`) |  |
| Descript | Homebrew cask (`descript`) | checklist: Sign in to Descript |
| CapCut | Homebrew cask (`capcut`) |  |
| Canva | Homebrew cask (`canva`) | checklist: Sign in to Canva |
| Shottr | Homebrew cask (`shottr`) | screenshots |
| Kap | Homebrew cask (`kap`) | screen recordings and GIFs |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Edits by Instagram ★ | Guided download ([page](https://edits.instagram.com/)) | free video editor |
| Premiere Pro | Homebrew cask (`adobe-creative-cloud`) | through Adobe Creative Cloud; checklist: Sign in to Creative Cloud and install Premiere Pro |
| Stream Deck | Homebrew cask (`elgato-stream-deck`) |  |
| Elgato Camera Hub | Homebrew cask (`elgato-camera-hub`) |  |
| Elgato Wave Link | Homebrew cask (`elgato-wave-link`) |  |
| Loopback | Homebrew cask (`loopback`) | route audio between apps (paid) |
| Audio Hijack | Homebrew cask (`audio-hijack`) | record any app's audio (paid) |
| Audacity | Homebrew cask (`audacity`) |  |
| Loom | Homebrew cask (`loom`) |  |

### Design

*Figma, Affinity, Pixelmator Pro*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Figma | Homebrew cask (`figma`) | checklist: Sign in to Figma |
| Affinity | Homebrew cask (`affinity`) | free |
| ImageOptim | Homebrew cask (`imageoptim`) |  |
| FontBase | Homebrew cask (`fontbase`) |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Framer | Homebrew cask (`framer`) | design to live sites |
| Spline | Homebrew cask (`spline`) | 3D design |
| Adobe Creative Cloud | Homebrew cask (`adobe-creative-cloud`) | checklist: Sign in to Creative Cloud |
| Pixelmator Pro | App Store (id `1289583905`) | paid; from the App Store |

### Team collaboration

*Slack, Zoom, Notion*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Slack | Homebrew cask (`slack`) | checklist: Sign in to Slack |
| Zoom | Homebrew cask (`zoom`) |  |
| Notion | Homebrew cask (`notion`) |  |
| Notion Calendar | Homebrew cask (`notion-calendar`) |  |
| Obsidian | Homebrew cask (`obsidian`) |  |

**Anything else?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Discord | Homebrew cask (`discord`) |  |

## Extras

The "A few extras people love" screen. Each is optional.

### Meeting notes

*Granola, or open-source Meetily*

**Which meeting note-taker?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Granola ★ | Homebrew cask (`granola`) | *Paid, polished*; AI notes; no bot joins your call |
| Krisp | Homebrew cask (`krisp`) | *Paid, polished*; noise cancelling and notes |
| Meetily | Homebrew cask (`meetily`) | *Free and private*; open source; transcribes on your Mac |
| Anarlog | Homebrew cask (`anarlog`) | *Free and private*; open source; on-device transcription |

### Voice dictation

*Wispr Flow, or open-source VoiceInk*

**Which dictation app?** (choose any)

| Item | Installed with | Notes |
| --- | --- | --- |
| Wispr Flow ★ | Homebrew cask (`wispr-flow`) | *Paid, polished*; edits as you speak; checklist: Sign in to Wispr Flow |
| Superwhisper | Homebrew cask (`superwhisper`) | *Paid, polished*; choose models and modes |
| Aqua Voice | Homebrew cask (`aqua-voice`) | *Paid, polished*; fast dictation |
| MacWhisper | Homebrew cask (`macwhisper`) | *Paid, polished*; transcribe files and meetings |
| VoiceInk | Homebrew cask (`voiceink`) | *Free and private*; open source; runs on your Mac |
| Handy | Homebrew cask (`handy`) | *Free and private*; open source; works offline |
| OpenWhispr | Homebrew cask (`openwhispr`) | *Free and private*; open source |
| Buzz | Homebrew cask (`buzz`) | *Free and private*; open source; transcribe audio files |

### Local AI models

*Ollama, LM Studio*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Ollama | Homebrew cask (`ollama-app`) |  |
| LM Studio | Homebrew cask (`lm-studio`) |  |

### Raycast

*a faster Spotlight with window snapping*

**Always installed:**

| Item | Installed with | Notes |
| --- | --- | --- |
| Raycast | Homebrew cask (`raycast`) | checklist: Open Raycast and choose a hotkey |
