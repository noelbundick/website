---
title: Bash on Windows + Azure Cloud Shell Quickstart
tags:
  - azure
  - bash
date: 2017-05-14 14:49:56
---


In a {% post_link Supercharging-the-Azure-Cloud-Shell "previous post" %}, I shared some info on how to connect to your Azure Cloud Shell shared drive, with a particular focus on Bash on Windows. I thought to myself, "How can I make this even easier?" 

Here's how to get started in just two commands!

# TL;DR version - run this

```bash
# Run the setup script
curl https://gist.githubusercontent.com/noelbundick/f03200a4387b4bf4d3eed2d97169fc89/raw/738c3417a2513847dc71dabb844c395616831de9/setupclouddrive.sh | bash
 
# Run the created mount script
~/.mountclouddrive.sh
```

# Long Explanation

Make sure that you've already gone through the Cloud Shell setup for your selected subscription. That will get you set up with the storage account we'll connect to here. You'll also need to get logged into the Azure CLI on Bash on Windows.

## 1. Setup

All the cool kids these days seem to be piping curl to Bash, so I'm going to have you do the same here. 

### Security warning

Seriously, don't just pipe commands to your shell blindly! Take 10 seconds and [go look](https://gist.githubusercontent.com/noelbundick/f03200a4387b4bf4d3eed2d97169fc89/raw/738c3417a2513847dc71dabb844c395616831de9/setupclouddrive.sh) at what I'm telling you to do here before copy/pasting this. 

```bash
curl https://gist.githubusercontent.com/noelbundick/f03200a4387b4bf4d3eed2d97169fc89/raw/738c3417a2513847dc71dabb844c395616831de9/setupclouddrive.sh | bash
```

This script will connect to Azure to get some info about your Cloud Shell storage account. It then uses [Windows Interopability](https://msdn.microsoft.com/en-us/commandline/wsl/interop#invoking-windows-binaries-from-wsl) to invoke Windows binaries from Bash, securely storing your secrets & keeping them out of your scripts (this might actually be the coolest thing about this whole process). And it drops a mount script in your home folder for everyday use.

## 2. Everyday usage

Because only root can use the `--types` option on `mount`, the `mountclouddrive.sh` script needs sudo access. You should look at the script to make you understand what it's doing - never take my word for it. Check it out with

```bash
cat ~/.mountclouddrive.sh
```

{% asset_img bash-examplemountscript.png "This has been long deleted/recreated, so don't bother hacking me" %}

Looks legit to me! And to connect during your normal dev/admin activities, use

```bash
~/.mountclouddrive.sh
```

Putting that all together, you'll get something like the following

{% asset_img bash-success.png "Specific url is different than example command due to Gist revisions" %}

Easy! 2 commands and you're up and running!

# Notes on the Code

Wow, you're still reading! I wanted to explain some of the code so it wasn't magic voodoo - I want you to learn this stuff and go build bigger & better things. There are a few interesting things going on here I'll point out.

## Azure CLI

I'm using built-in [JMESPath](http://jmespath.org) query support to filter storage accounts to only get the ones in the `cloud-shell-storage` resource groups, which is the convention used per the Cloud Shell docs. Should there be multiple of those, I'm also getting just the first one. This is a super handy way for extracting simple JSON properties from complex objects & arrays without needing to use a separate tool.

Specifying TSV output gives clean strings that make it easy to use with other commands.

## [Windows Interop](https://msdn.microsoft.com/en-us/commandline/wsl/interop#invoking-windows-binaries-from-wsl)

So cool. This lets me invoke `cmdkey.exe` from inside Linux to save secrets in Windows, and I don't have to worry about secrets in files.


<script src="https://gist.github.com/noelbundick/f03200a4387b4bf4d3eed2d97169fc89.js"></script>
