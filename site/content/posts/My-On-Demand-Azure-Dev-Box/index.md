---
title: My On-Demand Azure Dev Box
tags:
  - azure
date: 2017-11-13 19:25:38
aliases:
  - /2017/11/13/My-On-Demand-Azure-Dev-Box/
  - /2017/11/14/My-On-Demand-Azure-Dev-Box/
---


I'm always tinkering with things and trying to automate away common things that become annoying. I'm also on the lookout to be a good steward of my company's resources. And I certainly don't want to spend any of my own money! To those ends - I've assembled some useful hacks that let me quickly access my Azure VMs on demand. It started out as a fun experiment of what's possible and turned into something I use on a daily basis across all my computers.

# Part 1: Create a VM

I'm going to assume you already know how this works. If not, [read this first](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli) and come back. I use the [burstable B-series](https://azure.microsoft.com/en-us/blog/introducing-b-series-our-new-burstable-vm-size/) VMs for my dev boxes. They're super cheap and work well for my most common workload - a bunch of shell commands, some vim here & there, and then a less common compilation where I want things to run fast.

```bash
# Create a dev box resource group
az group create -n devbox -l westus2
 
# Create a VM that you'd like to use, but you don't want to pay to keep running 24/7
az group create -n devbox -g devbox --image UbuntuLTS --size Standard_B4MS
```

# Part 2: Saving $$$ with auto-shutdown

I don't use all of my VMs every day, and I'm not usually hacking on a remote VM late at night. Azure has a handy feature called `Auto-shutdown` that can turn off VMs on a schedule. That is - deallocate them and stop charging me money. Enable it on the VM resource in the Azure Portal.

{{% img "auto-shutdown.png" "No more charges for things I'm not using!" %}}

> This is also a handy reminder to ** stop working ** and spend some time with my family. That's a post for another day

# Part 3: But Noel, now my VM is off

I got this far and felt pretty good. But then I realized I had to login to the Azure portal or launch the Azure CLI to start my VM every time I wanted to use it, which was totally lame. And what if I didn't immediately remember the DNS name or the IP address of the VM I just turned on? More clicking.

{{% img "do-not-want.jpg" "First world problems for sure. It used to take months to get a new machine" %}}

I'm willing to wait for a VM to boot up, but I didn't like the extra steps. I wanted to just press a button, be prompted for my password, and then be dropped inside a VM of my choice.

# Part 4: Azure functions to the rescue

So that's what I built! 

[StartVirtualMachine](https://github.com/noelbundick/azure-utilities/blob/master/Functions/StartVirtualMachine.cs) is an Azure Function that
* accepts a VM name, and an optional username. 
* uses a Service Principal to find the VM by name & start it
* gives you everything you need to enter a password & login
  * Linux: redirects and/or links to `ssh://<username>@<fqdn>`
  * Windows: downloads an `.rdp` file to connect

# Part 5: Moving cheese is my favorite

So essentially all I've done is replace an Azure portal/CLI login with an Azure function token. Traded one password for another. At least now I've got a well-known key and an HTTP trigger.

Wait a minute, that's something useful. I can create a shortcut & add it to the Chrome bookmarks bar!

{{% img "bookmarks.png" "Noel does not like words on his bookmarks bar" %}}

My bookmark:
* Title: <blank>
* Url: `https://my-functions.azurewebsites.net/api/StartVirtualMachine?code=<i_was_not_born_last_night>&vm=devbox&username=noel`

# Part 6: Y u no ssh?

Opening up the RDP for Windows VMs works great. Remote Desktop Connection comes installed with Windows, and I've even tested it out with the [Microsoft Remote Desktop](https://play.google.com/store/apps/details?id=com.microsoft.rdc.android&hl=en) Android app on a Chromebook.

SSH is up next. Turns out that the [Secure Shell](https://chrome.google.com/webstore/detail/secure-shell/pnhechapfaindjhompbnflcldabbghjo?hl=en) Chrome App will interpret my `ssh://` links and do exactly what I want. 

I've already got my colors, fonts, and keys just the way I want them. So when I click on my bookmark, the function will start my VM and I'm presented with the following

{{% img "secure-shell.png" "Do not hack me plz" %}}

When I'm done with it, I can either run `az vm deallocate` or just wait for auto-shutdown to do its job

# Summary

Worth it? For me, I think so! I use this thing a lot.

Or maybe I'm this guy

{{% img "complicated.jpg" "If you're reading this, I have bad news. You're probably this guy or gal as well" %}}

What do you think? Is there anything you would add or remove to make this more useful to you?