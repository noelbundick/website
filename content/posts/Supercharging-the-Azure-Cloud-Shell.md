---
title: Supercharging the Azure Cloud Shell
tags: 
  - azure
  - bash
date: 2017-05-13 14:36:02
aliases:
  - /2017/05/13/Supercharging-the-Azure-Cloud-Shell/
---


[Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), recently announced at Build, is an awesome new way to manage your Azure resources. In a nutshell, it's a hosted terminal session you can access from anywhere using your browser. And it's already got most of the basic tools you'll typically need for interacting with your Azure websites, VMs, Kubernetes clusters, and so on.

As I've been using it more often, I've found myself wanting a few files I already had locally - ssh keys, helper scripts, and the like. Cloud Shell uses a normal storage account to keep track of your $HOME directory, and there's already some [good docs](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage) on how to transfer files to & from a mapped `clouddrive` share via the Azure Portal. 

But all that clicking gets kind of tedious. I want to treat my `clouddrive` as if it were a normal folder in Windows, and I want to be able to copy files to & from it using Bash on Windows. Let's see what we can piece together!

# Mapping the Share to Windows

You'll need a few bits of info on the storage account associated with your Cloud Shell:
* Storage account name ([where to find](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage))
* Storage account key ([where to find](https://docs.microsoft.com/en-us/azure/storage/storage-create-storage-account#manage-your-storage-access-keys))
* File share name ([where to find](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage))
* Target folder - I chose `C:\users\Noel\clouddrive` to use the same folder name

Fire up a command prompt, replace the tokens with your values, and execute the following:
```powershell
# Save your connection information so you don't have to enter every time
cmdkey /add:<storage-account-name>.file.core.windows.net /user:AZURE\<storage-account-name> /pass:<storage-account-key>
 
# Connect to the file share
net use \\<storage-account-name>.file.core.windows.net\<share-name>
 
# Map the file share on Azure to a local folder
mklink /d <target-folder> \\<storage-account-name>.file.core.windows.net\<share-name>
 
# Open up the folder, take a look around!
explorer <target-folder>
cd <target-folder>
dir
```

Cool! It's just a normal file share. I can drag & drop, and use any of my normal commands to drop files to & from the share, which I can then access from Cloud Shell.

# Mapping the share to Bash on Windows

So that's great and all - but I  use Bash on Windows far more often than PowerShell or the Ye Olde Command Prompte. Surely I can just access my files, since they're available in a Windows folder now, right?

```bash
cd /mnt/c/Users/Noel
ls -al
```

{% asset_img bash-noclouddrive.png "Where is clouddrive?" %}

Failsauce! Where's my `clouddrive` folder? Turns out the version of WSL in Creators Update [doesn't yet have](https://github.com/Microsoft/BashOnWindows/issues/1975) the latest file system improvements. I'll need at least [Build 16176](https://msdn.microsoft.com/en-us/commandline/wsl/release_notes) to try this out. 

## Warning!

If you're following along with me - this is where things might break. I want the latest bits, so I'm going to opt in to Fast Ring of the [Windows Insider](https://insider.windows.com/) program. Make sure you make an informed decision before deciding to do this. If you're not comfortable with possible carnage on your box, you might want to wait a while after this post and let these WSL updates land in the stable update cycle.

## (Update) No, really!

Shortly after publishing this post, I continued about my business, then noticed vim had stopped working. The **good** news is the WSL team [already has a fix](https://github.com/Microsoft/BashOnWindows/issues/2092) for it. The **bad** news is that WSL ships as a part of Windows 10, and there's no way to get an exact timeline on when the fix will land.

Like I said before - don't just opt in to Fast Ring to get shiny new bits without understanding the risks.

## Mounting the share

Okay! Some update magic & a couple of reboots later, I'm on Windows 10 Enterprise Preview Build 16193. Let's give it another try

```bash
cd /mnt/c/Users/Noel
ls -al
```

{% asset_img bash-seeclouddrive.png "Well, hello cloudshell!" %}

Nice! Looks like Fast Ring is already an improvement. And when I go to look at my files in `clouddrive`

```bash
cd clouddrive
```

{% asset_img bash-inputoutputerror.png "Nothing's ever that easy" %}

Well, that didn't quite work out. Not sure what's going on here. I'll send some feedback to the WSL team on this. I'm in uncharted territory. But maybe I can get it working anyway. In the [blog post](https://blogs.msdn.microsoft.com/wsl/2017/04/18/file-system-improvements-to-the-windows-subsystem-for-linux/) announcing the latest filesystem improvements, it looks like I can mount a network location directly via the `mount` command.

```bash
cd ~
mkdir clouddrive
sudo mount -t drvfs '\\<storage-account-name>.file.core.windows.net\<share-name>' clouddrive
```

Sweet! No errors. Let's poke around and make sure this thing actually works!

```bash
cd clouddrive
ls -al
echo "I wonder if this works..." > test.txt
```

{% asset_img bash-test.png "So far, so good" %}

And now the real moment of truth - none of this time spent was worth anything if I can't read it from my Cloud Shell! Let's check it out in the Azure Portal:

{% asset_img cloudshell-success.png "Houston, we have liftoff!" %}

Awesome! Well if that works, then I should also be able to access via my Windows tools too, right?

{% asset_img explorer-success.png "Woohoo!" %}

&nbsp;

{% asset_img windows-success.png "This works too!" %}

Looking great! I wonder if...

{% asset_img mobile-success.png "So far, so good" %}

It sure does! Cloud Shell on the Azure mobile app works too. You probably saw this in the Build day 1 keynote, but it hasn't made its way out to everyone just quite yet. I'm on the beta iOS Azure app, so I would expect for this to roll out quite soon.

# Summary

Not bad for a morning of goofing around. Because Azure Cloud Shell is built on top of other reusable components, nameably Azure Files, I can now quickly & easily move files between my local box, whether that's PowerShell, Bash on Windows, or the Command Prompt. I'm sure others will do great things with this - hopefully this will get you up and started

## Resources

* [Azure Cloud Shell Quickstart](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart)
* [Persisting Files in Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/persisting-shell-storage)
* [Get Started with Azure File storage on Windows](https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-how-to-use-files#mount-the-file-share)