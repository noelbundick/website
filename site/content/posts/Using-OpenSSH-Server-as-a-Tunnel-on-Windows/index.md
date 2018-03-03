---
title: Using OpenSSH Server as a Tunnel on Windows
tags: 
  - azure
  - ssh
date: 2018-03-02
---

Confession: Windows 10 is a great operating system, and it's my primary both at work and at home, but I don't always use Windows.  I've made a conscious decision to use Linux as a host OS on occasion so that I can learn its ins and outs, which helps me solve problems for customers, makes me more productive in the cloud, helps me troubleshoot fiddly devices at home, etc.

But sometimes, I have a problem - I need to be able to access computers on the corporate network, and the RDP Gateway server I've been using doesn't seem to be supported anymore. One of my laptops is an Active Directory domain member, so I'm covered there. And I can join my mobile devices using Intune to get access. But Intune doesn't support Ubuntu...

## But Why Tho

{{% img "y-tho.jpg" "But whyyyyyyyy" %}}

Is this really a problem? There are plenty of reasons why you might consider doing something similar, including:

* You're running Linux
* You can't install software directly on the box you're using
* Your personal PC belongs to you, and you don't want other people putting corporate policies on it just so you can use your snazzy 4k monitor
* Your tinfoil hat tells you that you need to somehow mask your source IP address. Or something. (Hint: this isn't the solution you're looking for)

## SSH -> RDP tunnel

To solve for this, I decided to build an SSH tunnel using a low-cost [B-series](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/b-series-burstable) Azure VM. The VM is Intune-managed, and the company is free to wipe all its data, lock me out, set arcane policies, and do whatever it wants. I forward local ports directly to my RDP destination, using the VM as the middle-man. It looks something like this:

{{% img "ssh-tunnel.png" "Abusing SSH tunnels for fun and profit" %}}

### Create an Azure VM

Use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and/or [Azure Cloud Shell](https://shell.azure.com) to create a Windows VM - Server 1709, Windows 10 Fall Creators Update, or newer. You'll also want to go ahead and open up port `22` in your Network Security Group. Use these commands to get started:

```bash
# Creating a VM
az vm create -h

# Opening port 22
az vm open-port -n my-jumpbox -g my-rg --port 22
```

### Enrolling in Intune

Every company is going to have something set up slightly differently, but the general idea is that on your VM, go to `Settings > Accounts > Access Work or School` and sign in

{{% img "join-intune.png" "Enrolling in Intune" %}}

Intune should automatically add & configure your VPN connection. Restart if it doesn't show up within a few minutes. If your company requires you to set up your VPN connection manually, do that now.

> Your company may need a third-party app, like [GlobalProtect](https://www.microsoft.com/en-us/store/p/globalprotect/9nblggh6bzl3). If you need that - install that now too

Next up - verify that you can make an RDP connection from your VM to the box on your corporate network. If that doesn't work, no amount of SSH tunneling tricks will help you.

> **Important:** It seems like some VPN configurations require an interactive logon to make the VPN connection. You'll need to RDP to your VM to initiate the connection, but you can immediately disconnect (but don't logoff) as soon as the VPN is connected in the task bar

### OpenSSH Server

Now to the interesting part - running sshd as a built-in Windows Feature. The best way to get started is to follow the [official blog](https://blogs.msdn.microsoft.com/powershell/2017/12/15/using-the-openssh-beta-in-windows-10-fall-creators-update-and-windows-server-1709/). Don't forget the extra PowerShell steps to set security on your SSH keys, or it'll all go south.

{{% img "openssh-server.png" "Installing OpenSSH Server on Windows" %}}

### OpenSSH Client

If you're on Linux or a Mac, you've got ssh, so you're good to go. On Windows, using the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) is the way to go.

Now to wire it all up. A single command does the following for you:

* Open port `20000` on your local machine
* Restrict access to `127.0.0.1` (localhost), so other computers can't use your tunnel
* Forward all traffic made to port `2000` to port `3389` on `my-computer.corp.example.com`
* Do the forwarding through `my-jumpbox.westus2.cloudapp.azure.com`, using the login name of `azureuser`
* Use compression on the data sent over ssh

```bash
ssh -fNTC -L 127.0.0.1:20000:my-computer.corp.example.com:3389 azureuser@my-jumpbox.westus2.cloudapp.azure.com
```

Tunnel opened! Now, you can open an RDP session to `localhost:20000`, and have it forwarded all the way to the box you actually care about.

## Final Thoughts

{{% img "why.gif" "Why did I do this?" %}}

This was a lot of work, why did I do this again?

RDP has been highly tuned and optimized for many years - nested sessions included. So far, it's actually been snappier to use RDP-inside-RDP than to use this SSH tunnel. But this was a quick & fun way to play with the new OpenSSH Server on Windows, so I might keep it around.

[OpenSSH Server on Windows](https://github.com/powershell/Win32-OpenSSH) is **super beta** - expect weird things to happen, but the PowerShell team would love your input - go visit them on GitHub

Oh - and don't violate your company's security policies - just because you **can** do this doesn't necessarily mean that it's a good idea.