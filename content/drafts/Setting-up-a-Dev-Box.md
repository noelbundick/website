---
title: Setting up a Dev Box
tags:
---

Bash on Windows
7zip
Sysinternals - add to PATH
VS Code Insiders
VS 2017 Enterprise Preview
Service Fabric SDK (2017 version!)
Chrome
Docker for Windows - edge
- Windows Containers feature
Git Extensions
- Git
- Kdiff3
- PuTTY
- Git Credential Manager
Postman (Windows x64, not chrome app)
Fiddler
Azure Storage Explorer
Node.js
Yarn
Snip

--------
Surface Book
- Remap keys (https://github.com/randyrants/sharpkeys)
  - Interferes with Chrome/VS debugging shortcut keys :(

--------
Ideas
- Universal launcher (like Alfred)
- wsltty
  - Solarized colors (https://github.com/karlin/mintty-colors-solarized/blob/master/.minttyrc--solarized-dark)
  - Consolas, 12pt
  - Right mouse = paste
  - see .minttyrc

--------
PC
- BitLocker - auto unlock drive
- Setup OneDrive for Business
- Dark theme for Windows 10
- Autohotkey - for surface pen fun
- Rust lang (and VS2015 C++ build tools)
  - cargo install racer
  - cargo install rustsym
  - cargo install rustfmt
- SQL management studio 2017
- Defender exclusions
  - C:\code
  - C:\Users\nobun\AppData\Local\Yarn
  - C:\Users\nobun\AppData\Local\lxss
- PuTTY

--------
Keyboard shortcuts
- Win+Shift+Left/Right = Move current window to another monitor
- Ctrl+Win+Left/Right = Switch desktops


--------
Cloud console mapping
https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-how-to-use-files#mount-the-file-share
https://superuser.com/questions/244562/how-do-i-mount-a-network-drive-to-a-folder
- cmdkey /add:<storage-account-name>.file.core.windows.net /user:AZURE\<storage-account-name> /pass:<storage-account-key>
- net use \\<storage-account-name>.file.core.windows.net\<share-name>
- mklink /d C:\users\nobun\cloudconsole \\nobunconsole.file.core.windows.net\console

Bash on Windows
REQUIRES build 16176! Fast ring as of 5/13/17
- https://github.com/Microsoft/BashOnWindows/issues/1975
- https://msdn.microsoft.com/en-us/commandline/wsl/release_notes
- https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/
- sudo mount -t drvfs '\\server\share' /mnt/share

--------
Explorer
- Show file extensions
- Pin code, temp folders. Remove others

--------
Docker
- Ubuntu (https://store.docker.com/editions/community/docker-ce-server-ubuntu?tab=description)
- Windows (https://store.docker.com/editions/community/docker-ce-desktop-windows?tab=description)
  - Needs Hyper-V

--------
Keyboard shortcuts
-Win+1 - bash
-Fn + del/backspace for brightness

--------
Chrome
-chrome://flags - smooth scrolling

--------
Folders
-code
-temp
-tools

--------
VS Enterprise 2017 Preview
- .NET core
- web
- Python
- Data science
- Node.js
- Linux

--------
VS Code
- extensions
  - Azure Resource Manager Tools
  - C#
  - Docker
  - EditorConfig for VS Code
  - Go
  - Kubernetes Support
  - PowerShell
  - Python
- other preferences
  - "terminal.integrated.shell.windows": "C:\\WINDOWS\\Sysnative\\bash.exe",
  - "editor.tabSize": 2,
  - "git.confirmSync": false

--------
Cmd
//https://github.com/neilpa/cmd-colors-solarized
- create a '.cmdrc' for cmd and/or PowerShell
- HKCU\Software\Microsoft\Command Processor\Autorun="C:\users\nobun\.cmdrc.cmd"
  - doskey aliases
- HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\code.exe
  - default value: "C:\Program Files (x86)\Microsoft VS Code Insiders\Code - Insiders.exe"
- colors
- share .ssh between bash/windows?
- Azure CLI
  - python (python36 or anaconda)
  - Add /AppData/Roaming/Python/Python36/Scripts to PATH
  - updates: "az component update"
- see solarized-dark.reg
- 16pt consolas
- install kubectl (--install-location="C:\tools\kubectl.exe")


```
@echo off
doskey code=code-insiders $*
doskey ls=dir $*
doskey cp=copy $*
doskey mv=move $*
doskey rm=del $*
doskey vim=bash -c "vim $*"
doskey cat=type $*
```

--------
PowerShell
- Install-Module AzureRM

--------
Bash
// https://gist.github.com/MadLittleMods/0e38f03774fb16e8d698175e505f1f3e
// https://github.com/iamthad/base16-windows-command-prompt
// https://medium.com/@Andreas_cmj/how-to-setup-a-nice-looking-terminal-with-wsl-in-windows-10-creators-update-2b468ed7c326
// https://communary.net/2017/04/13/getting-started-with-windows-subsystem-for-linux/
// https://www.hanselman.com/blog/SettingUpAShinyDevelopmentEnvironmentWithinLinuxOnWindows10.aspx
// https://gist.github.com/P4/4245793
// https://github.com/seebi/dircolors-solarized
- eliminate beep
  - Right click in taskbar, go to Volume Mixer
  - Mute Console Host
- terminal - sane colors
- set DOCKER_HOST
- dscorch
- update git
- Azure CLI (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#windows)
  - Stable : apt-get install azure-cli
  - Nightly: pip install --pre azure-cli --extra-index-url https://azureclinightly.blob.core.windows.net/packages
    - https://github.com/Azure/azure-cli#nightly-builds
  OLD:
  - az configure - set to jsonc
  - DOESN"T WORK
    - echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
    - sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
    - sudo apt-get install apt-transport-https
    - sudo apt-get update && sudo apt-get install azure-cli
    - to update: sudo apt-get update && sudo apt-get install azure-cli
  - WORKS
    - sudo ln -s /usr/bin/python3 /usr/bin/python
    - apt-get update && apt-get install -y libssl-dev libffi-dev python3-dev build-essential
    - curl -L https://aka.ms/InstallAzureCli | bash
    - will install in /home/noel/bin
    - say yes to PATH & autocomplete
    - run `exec -l $SHELL` to restart
- kubectl
- dotnet sdk (dotnet-dev-1.0.3)
- node
- imagemagick
- pngcrush
- sshfs
- mysql-client
- postgresql-client-9.4
  - echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
  - wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  - sudo apt-get update
  - sudo apt-get install postgresql-client-9.4
- yarn
  - sudo yarn global add hexo-cli
- docker
- docker-compose
- Service Fabric SDK
  - https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-get-started-linux
  - sudo yarn global add yo bower grunt
- jq
- rust (from site)
  - cargo install racer
  - cargo install rustsym
  - cargo install rustfmt
- # not needed: python3, python3-pip + ccat
- # not needed:  sudo ln -s /usr/bin/pip3 /usr/bin/pip
- # not needed: pip install pygments
- sudo apt install python-pygments
- setup Vim - pathogen, solarized
- ssh-agent
- symlinks for code, temp, c (for MobyLinuxVM)
  - ex: "ln -s /mnt/c/Users/nobun/Desktop desktop"
  - go -> /mnt/c/code/go
  - code -> /mnt/c/code
  - temp -> /mnt/c/temp
  - desktop -> /mnt/c/Users/nobun/Desktop
  - downloads -> /mnt/c/Users/nobun/Downloads
  - .ssh -> /mnt/c/users/nobun/.ssh ??
- change ll='ls -alF' to 'ls -alFh' for nicer MB/GB names
- curl -o .dircolors https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark
```
export TERM='xterm-256color'
source <(kubectl completion bash)
source ~/lib/azure-cli/az.completion

export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
export DOCKER_HOST=tcp://127.0.0.1:2375

alias rc="vim ~/.bashrc && source ~/.bashrc"
alias code="code-insiders"
alias ccat="pygmentize -O style=manni -f console256 -g"
cless() {
  pygmentize -O style=manni -f console256 -g "$1" | /usr/bin/less -R
}
alias dockviz="docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"
alias colors="pygmentize -O style=manni -f console256 -s"
alias clip="clip.exe"

dscorch() {
  read -p "Are you sure? " -n 1 -r
  echo # new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    docker rm --force $(docker ps -aq)
  fi
}

export PATH=/home/noel/bin:$PATH
```

--------
Go
- Install on Linux (GOPATH=/mnt/c/code/go)
- Install on Windows (GOPATH=C:\code\go)
- Install Glide (package manager)
  - sudo add-apt-repository ppa:masterminds/glide && sudo apt-get update
  - sudo apt-get install glide

--------
Tmux
- Create a ~/.tmux.conf
```
# Enable mouse control (clickable windows, panes, resizable panes)
set -g mouse on
set -g default-terminal "screen-256color" 
```

Launching
- tmux new -s "SessionName"
- tmux attach -t "#"

Shortcuts
Ctrl+B prefix
- % Split vertically
- " Split horizontal
- x Kill pane
- c Create window 
- & Kill window
- n Next window
- p Prev window
- 0-9 select a window
- Arrows move between panes
- Alt+1 Even horizontal
- Alt+2 Even vertical (stacked)
- Alt+3 Main horizontal
- Alt+4 Main vertical
- Alt+5 Tiled
- Ctrl+arrows resize
- Alt+arrows resize in bigger steps
- { Swap current pane with prev
- } Swap current pane with next
--------
Git
- Set up credential store / cache
  - `git config --global credential.helper store`
  - Files will be stored in plain text at `~/.git-credentials`
- Create & use a Personal Access Token on GitHub

--------
SSH-Agent
- Start a new agent
```
eval $(ssh-agent -s)
```
- Add keys
```
ssh-add ~/.ssh/id_rsa
```

--------
Vim
- Create a ~/.vimrc
  - copy /usr/share/vim/vim74/vimrc_example.vim
```
execute pathogen#infect()
syntax enable
set background=dark
colorscheme solarized

set tabstop=2       " The width of a TAB is set to 2
                    " Still it is a \t. It is just that
                    " Vim will interpret it to having
                    " a width of 2.
set shiftwidth=2    " Indents will have a width of 2
set softtabstop=2   " Sets the number of columns for a TAB.
set expandtab       " Expand TABs to spaces

set number
set mouse=a
if &term =~ '256color'
  " Disable Background Color Erase (BCE) so that color schemes
  " render properly when inside 256-color tmux and GNU screen.
  " see also http://snk.tuxfamily.org/log/vim-256color-bce.html
  set t_ut=
endif
```

Vim commands:
- ESC to command mode
- :q! - force quit, don't save
- :wq - save & quit
- i   - insert mode, add text
- dd  - delete the current line

-------------
neofetch

ZSH
- oh my zsh
- export PATH=$PATH:/usr/local/go/bin
  - goes in /etc/zsh/zshenv for machine-wide install for zsh users
  - goes in /etc/profile for bash users

-------------
Azure VM (see Google Drive linux folder)
- Enable host disk caching?
