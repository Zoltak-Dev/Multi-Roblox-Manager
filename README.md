# Multi-Roblox Manager

<p align="center">
  <img src="https://github.com/user-attachments/assets/56e3f5dc-c5f2-472d-97ad-d97da99f023d" alt="Multi-Roblox Manager preview" width="900">
</p>

Multi-Roblox Manager is currently in development.

This GitHub page was created early, before the first public release. If you want
to follow announcements, previews, feature ideas and release news, everything
will be shared on the Discord server.

While the complete manager is being prepared, this repository provides a small
standalone `multi_instance.py` utility. It only enables Roblox multi-instance
support; it is not the full account/session manager shown in the preview.

The project is made entirely in Python and has already been worked on for
several months. It already contains more than 25,000 lines of code, with a
lot of focus on details, stability, usability, request optimization and a clean
modern interface.

I have been automating things for many years, especially through requests, and I
never found a public Roblox manager that was truly good enough. So I decided to
build it myself.

The goal is simple: make literally the best Roblox account/session manager
available, completely for free, with public source code for everyone to inspect.
If something is even 0.1% worse than it should be, whether it is in the UI or in
the request optimization, I want to patch it. That is just how I work.

## Current Lightweight Utility

The temporary public utility has one purpose: it creates and holds Roblox's
Windows singleton mutex so that multiple Roblox clients can be launched.

It is designed for Windows 10/11 and the Roblox desktop client. It has no
external Python dependency, needs no administrator permission and does not
modify Roblox files.

### How To Use It

1. Fully close Roblox.
2. Open `Start Multi-Instance.bat`.
3. Keep the console window open.
4. Launch your Roblox clients.
5. Press Enter in the console when finished to release the mutex.

### Automatic Installation

1. Download only [`install.bat`](https://raw.githubusercontent.com/Zoltak-Dev/Multi-Roblox-Manager/main/install.bat).
2. Run it and follow the on-screen prompts.
3. Open `Start Multi-Instance.bat` from the installed folder.

The installer:

- Detects Python 3.8+ and Git, including common installations missing from PATH.
- Offers to install anything missing through Windows Package Manager (`winget`).
- Uses the real Windows Desktop location, including a redirected OneDrive Desktop.
- Downloads and validates the latest `main` branch before changing anything.
- Installs the requirements and opens the finished folder.
- Asks before replacing an existing installation and preserves it as a
  timestamped backup.

If installation fails, the existing version remains untouched. The batch file
is plain text and can be inspected before it is run.

### Manual Installation

Install [Python](https://www.python.org/downloads/) and
[Git](https://git-scm.com/download/win). Then open **Windows PowerShell** or
**Windows Terminal with a PowerShell tab** (not Command Prompt), paste the
following commands and press Enter:

```powershell
$desktop = [Environment]::GetFolderPath("Desktop")
Set-Location $desktop
git clone https://github.com/Zoltak-Dev/Multi-Roblox-Manager.git
Set-Location Multi-Roblox-Manager
py -3 -m pip install -r requirements.txt
py -3 multi_instance.py
```

If Roblox or another program already owns the singleton mutex, the utility
explains the conflict and lets you retry after closing it or leave safely. The
mutex is also released automatically if the console is closed.

## Support The Project

I am building this project out of passion.

If you would like to support its development directly, you can donate through
my [Ko-fi page](https://ko-fi.com/zoltrak/). Donations are completely optional
but always appreciated.

If you are interested in the project, please consider starring this repository
and joining the Discord server. Even a simple star and joining the server can
make a huge difference, because it helps me know in advance if people are truly
interested in my work.

Any help is also welcome: logo, graphic design, ideas, advice, feedback, posts,
sharing the project or anything that can help give it more visibility.

[Join the Discord](https://discord.gg/3VnrmEgKVQ) ·
[Support on Ko-fi](https://ko-fi.com/zoltrak/)

## Status

- In development
- Not released yet
- Lightweight multi-instance utility available
- More previews and announcements coming soon
