---
title: Getting Started - Bash on Windows
tags: 
  - bash
date: 2017-05-08 18:00:00
aliases:
  - /2017/05/08/Getting-Started-Bash-on-Windows/
---


New job, new blog, new dev box, new... shell? Why not!

I'm spending more and more time with Bash on Windows / Windows Subsystem for Linux lately, and I'm loving it! My background to date has been mostly app development & Windows sysadmin, so Bash is new to me. Turns out, it runs great on Windows 10 Creators Update - quirks and all. Having recently set up a new box, I thought I'd share some tips and tasks that I would have appreciated when I got started. Hope you find them useful as well!

# Installation

* [Install Guide](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide)

# Colors

The Windows Console host has made some great improvements, but as of Creators Update, the colors you're going to get out of the box are still pretty rough. 

{{% img "colors-blackandblue.png" "Dark blue text on a black console background" %}}

Dark blue on black, ouch. 

We'll need to touch settings in both Windows and Linux to remedy this (remember what I said about quirks?) Let's start with Windows & start hacking away at the Registry to fix the console host colors. GitHub to the rescue - [neilpa/cmd-colors-solarized](https://github.com/neilpa/cmd-colors-solarized) is exactly what we need.

Specifically, I like Solarized Dark, so I'm going to start with [solarized-dark.reg](https://github.com/neilpa/cmd-colors-solarized/blob/master/solarized-dark.reg). I found applying this to the root **Console** key, gave me some craziness in PowerShell. To make this apply only to **bash.exe** and the **Bash on Ubuntu on Windows** shortcut, we'll change the name of the key, and repeat the section for the targets we want modified. 

```diff
-[HKEY_CURRENT_USER\Console]
+[HKEY_CURRENT_USER\Console\%SystemRoot%_System32_bash.exe]
"ColorTable00"=dword:00362b00
"ColorTable01"=dword:00969483
...
 
+[HKEY_CURRENT_USER\Console\Bash on Ubuntu on Windows]
+"ColorTable00"=dword:00362b00
+"ColorTable01"=dword:00969483
...
```

Note that if your shortcut is named **Bash**, your key would be named **[HKEY_CURRENT_USER\Console\Bash]**

{{% img "colors-solarizeddark.png" "Almost, but not quite there" %}}

Much better! We could stop there if we wanted to. But there are still a few places, like that **.azure** directory, where I still want more readable text. Here's where I tip my toes into the Linux world. Thankfully, GitHub saves me again - [seebi/dircolors-solarized](https://github.com/seebi/dircolors-solarized)

After looking over the **dircolors.ansi-dark** file, it looks safe, so let's pull it down and save it as our **.dircolors** file and see what happens

```bash
curl -o ~/.dircolors https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark
```

And after closing & restarting the Bash shell...

{{% img "colors-solarizeddark-withdircolors.png" "Console colors are fixed!" %}}

There we go! Room for improvement & customization? Sure, but this is a great improvement over the old & busted blue on black defaults. And it's a great first step towards bigger & better things.