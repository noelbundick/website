---
title: Fun with Azure Container Instances
tags:
  - azure
  - containers
  - minecraft
  - aci
date: 2017-08-03 17:32:39
aliases:
  - /2017/08/03/Fun-with-Azure-Container-Instances/
  - /2017/08/04/Fun-with-Azure-Container-Instances/
---


# Fun with Azure Container Instances

Azure Container Instances were [recently announced](https://azure.microsoft.com/en-us/blog/announcing-azure-container-instances/), making it easy for developers to spin up a container on-demand without having to provision and maintain a VM or a cluster.  It's been well received by the community, and there are already a [ton](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-quickstart) [of](https://channel9.msdn.com/Shows/Tuesdays-With-Corey/Tuesdays-with-Corey-Azure-Container-Instances) [great](https://channel9.msdn.com/Shows/Azure-Friday/Using-Kubernetes-with-Azure-Container-Instances) [resources](https://channel9.msdn.com/Shows/Azure-Friday/Azure-Container-Instances) to help you get started.

## But that's not what this post is about!

Truthfully, I can only sit through so many canned `docker run nginx` demos. I want learning to be fun! I wondered, "Can I run a Minecraft server on this thing?!"

{{< youtube "4PLvdmifDSk?start=62" >}}

This is where I completely ignore Dr. Malcolm's excellent advice. I'm going to stand on the shoulders of geniuses to accomplish something as fast as I can. The plan is to explore what I *could* do with Azure, and I have no intent to stop and think about whether or not I *should*.

## Step 1 - Make it work

Minecraft in a container? Easy enough! I'll run the following commands in the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) to create a resource group and a container. I'm going to use 2 CPU's and 2GB RAM just to make sure there are plenty of resources. Since billing is per-second and I'm tearing everything down after I write this post, I'm not worried about cost.

<script src="https://gist.github.com/noelbundick/9fa6e53a300e98e3af36d2a6ceea7f62.js?file=aci-minecraft.sh"></script>

### Sample output

{{% img "create-container.png" "Example output from 'az container create'" %}}

Cool, that gives me the IP address of the created container and shows the port mapping. Let's give it a try...

{{% img "minecraft-connect.png" "Connecting to an Azure Container Instance Minecraft server" %}}

And then for the big test - does it actually work?

{{% img "minecraft-world1.png" "Happy little blocks" %}}

Great success! I even got lucky & got a cool world seed... except for that giant hole just a few steps away

{{% img "minecraft-world1-nope.png" "Hellevator" %}}

Bunch of NOPE there! Moving on!

> Fun fact: If you mangle the names & use 1 CPU, you can spin this up in the space of a [tweet](https://twitter.com/acanthamoeba/status/890253868835102720)!

## Step 2 - Persisting data

Going back to the output of the `az container create` command, I noticed some interesting bits - particularly the `volumeMounts` field. I want to mount a volume so I can spin down my container, but still keep my world when I bring up a new one to play later.

How am I supposed to do that? Docs to the rescue! There's [already an article](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-mounting-azure-files-volume) on volume mounts. Hacking around with this a bit, I've come up with 2 artifacts.

### ARM Template

Volumes aren't supported in the CLI yet, so I need to specify them in an ARM template.

<script src="https://gist.github.com/noelbundick/9fa6e53a300e98e3af36d2a6ceea7f62.js?file=template.json"></script>

> If this is your first template and it looks like a big mess to you, then you're just like me! My [Intro to Azure Resource Manager Templates]({{< relref "Learning-Azure-Resource-Manager-Introduction" >}}) post might be a useful place to start learning

### Setup script

Cool, so we've got a declarative way to create our container and point it at a Storage Account. I know what you're thinking - "Noel, you forgot to create the storage account. Add it to the template!"

So here's the deal. I tried that and it doesn't work the way I hoped. The storage account gets created just fine, and the storageAccountKey gets properly set. Everything is wonderful... until you realize that the file share still needs to be created.

Well that's considered a data-plane operation, not a management-plane operation. So you don't get to do that with ARM. So you need a script

> If you want to vote to change that - [click here to go to the issue on the feedback site](https://feedback.azure.com/forums/281804-azure-resource-manager/suggestions/9306108-let-me-define-preconfigured-blob-containers-table)

<script src="https://gist.github.com/noelbundick/9fa6e53a300e98e3af36d2a6ceea7f62.js?file=aci-minecraft-volume.sh"></script>

Walking through the script gives me the following

{{% img "create-container-2.png" "Many Bothan spies died to bring you this screenshot of my console window" %}}

This time, I'm going to connect to my world & build something cool - that way, when I reconnect, I'll know that I'm in the same world

{{% img "minecraft-world2.png" "The mighty dirt obelisk" %}}

`¯\_(ツ)_/¯` Look, I'm a programmer, not an artist. Deal with it 

## Step 3 - Making sure volumes work

The big test! I'm going to delete my container and then fire it back up and we'll see if the obelisk stands, or if Azure is a big fat liar. I'll spare you the console screenshots this time

```bash
# Delete the container
az container delete -n minecraft-server --resource-group minecraft-rg -y
```

{{% img "connection-lost.png" "rm -rf minecraft" %}}

Awesome, I broke it. Running another ARM template deployment should give me a new container, with a new IP address, connected to the same world data.

```bash
# Deploy the template again to get a new container
az group deployment create -g minecraft-rg --template-uri https://aka.ms/aci-mcserver-template
```

{{% img "minecraft-world3.png" "Pretty sunset. Much wow." %}}

Yaaasssssss! I've got a persistent world and I'm able to spin up & down a containerized server on demand. I even got a nice virtual sunset out of the deal. Fun achieved!

## Summary

You're probably not running Minecraft - you'll have your own apps. Or not - steal my code and have fun!  In any case, I hope this gives you some ideas on how to run applications that interact with external state on Azure Container Instances. It's still very new, and the tooling is very much a work-in-progress. But it definitely works and I think it's worth checking out!

### Links
* [Code for this post](https://gist.github.com/noelbundick/9fa6e53a300e98e3af36d2a6ceea7f62)
* [Azure Container Instances Quickstart](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-quickstart)