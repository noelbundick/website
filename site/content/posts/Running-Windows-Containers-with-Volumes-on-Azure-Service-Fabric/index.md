---
title: Running Windows Containers with Volumes on Azure Service Fabric
tags:
  - azure
  - service fabric
date: 2018-02-10 15:56:10
aliases:
  - /2018/02/10/Running-Windows-Containers-with-Volumes-on-Azure-Service-Fabric/
  - /2018/02/11/Running-Windows-Containers-with-Volumes-on-Azure-Service-Fabric/
---


Containers are rapidly becoming the de-facto choice for application packaging, distribution, and execution in the cloud. This newfound flexibility brings new challenges, particularly with stateful workloads like databases. With the advent of container orchestrators, it's no longer a safe assumption that the underlying data for your server is already directly connected to your host. Nodes fail and are dynamically scaled, but your app still needs its data.

[Azure Service Fabric](https://docs.microsoft.com/en-us/azure/service-fabric/) is a distributed systems platform that [added support](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-containers-overview) for containers a while back. Windows Server 1709 has [greatly improved](https://blogs.msdn.microsoft.com/clustering/2017/08/10/container-storage-support-with-cluster-shared-volumes-csv-storage-spaces-direct-s2d-smb-global-mapping/) container storage support options by adding SMB Global Mapping. I've combined the two with great success and want to share, so that you can understand & replicate the concepts in your own environment.

> This post has a sibling repo on GitHub where you can steal code & follow along: [https://github.com/noelbundick/service-fabric-1709-demo](https://github.com/noelbundick/service-fabric-1709-demo)

## Minecraft, I choose you!

{{% img "pokeball.jpg" "Minecraft + Pokémon = awesome!" %}}

First off - I need an app that reads & writes local state. Databases and legacy apps are the common pick, but I'll take any excuse I can to play video games at work, so I'm choosing the [Minecraft Windows Container image](https://hub.docker.com/r/acanthamoeba/minecraft-server/) that I created (as an excuse to play games while learning Windows Containers...)

If you feel like something a bit more enterprisey or "real world", the [SQL Server Developer Edition for Windows Containers](https://hub.docker.com/r/microsoft/mssql-server-windows-developer/) is eerily similar - it also uses a specialized protocol on a specific port, writes data to local storage, you have to accept the EULA, etc. If you want to give it a try, use `C:\temp` instead of `C:\data`, and use port `1433` instead of `25565`

## Setting up a cluster

I have a few options here. First, the [Azure Portal](https://portal.azure.com) now supports Service Fabric clusters with Server 1709. To kick the tires & get started, it works great. I know I'm also interested in trying Hyper-V containers, so I need a VM size that supports [nested virtualization](https://azure.microsoft.com/en-us/blog/nested-virtualization-in-azure/) - the `Dv3` or `Ev3` series are what I need. I also want to expose port 25565 instead of port 80.

Okay, that's getting to be a lot of stuff to remember, so I'm going to use an ARM template and check it into source control. That way, I can recreate this environment again after I tear down this cluster. The template I'm using is available [on GitHub](https://github.com/noelbundick/service-fabric-1709-demo/blob/master/sf-1709/template.json). 

I'm running the following commands in a PowerShell session:

```powershell
# Create a cluster
az sf cluster create `
  -g sf-1709 `
  -l eastus `
  --template-file sf-1709/template.json `
  --parameter-file sf-1709/parameters.json `
  --vault-name sf-1709 `
  --certificate-subject-name sf-1709 `
  --certificate-password 'Password#1234' `
  --certificate-output-folder .

# Import cert
Import-PfxCertificate -FilePath '.\sf-1709201802051346.pfx' -CertStoreLocation 'Cert:\CurrentUser\My\'
```

Cool, now I've got a cluster up and running! Based on the params I gave it, I can visit it in Service Fabric Explorer at `https://sf-1709.eastus.cloudapp.azure.com:19080`

> For more cluster creation tips, check out James Sturtevant's post: [Creating a secure Service Fabric cluster in two commands](http://www.jamessturtevant.com/posts/Creating-a-secure-Service-Fabric-Cluster-in-two-commands/)

## Service Fabric Application Overview

First, it's important to understand the big picture of how Service Fabric handles applications, because it's easy to get lost without that initial context. You don't just run a block of code on Service Fabric - you first register it as a type of application. This application type is versioned, and describes what services (containers), parameters, configuration, etc. that are needed to run your app. Then, you create an instance of your app. 

For my Minecraft example, my `ApplicationType`, version 1.0.0 describes the following:

* My app, by default, has a single instance of a Minecraft `Service`
  * That service runs the `acanthamoeba/minecraft-server:nanoserver-1709` container, with various environment variables configured
  * The service should expose 2 endpoints (TCP ports) - one for the game, and one for administration
  * I also need a startup script that runs as Administrator to configure my host before running the container
* I want to parameterize my app so I can run lots of Minecraft servers on my cluster - each one will have different ports, data folders, etc.
* Finally, I want to limit how much CPU/memory I allocate to each Minecraft server

{{% img "sfoverview.png" "Service Fabric application types and instances" %}}

The above diagram shows an example representation of how this all works. Minecraft first gets set up as an ApplicationType, and when I create instances, that's when Service Fabric will launch containers & map ports. Think of the ApplicationType like a rubber stamp, and the Instance is the impression I get when I use it on a piece of paper. Those instances can differ (color of ink, type of paper, etc) but each impression came from the same stamp.

## How Does the Container Storage Work?

Let's do a deep dive into how I set up container storage.  Normally with VM Scale Sets, you do something like attach a 100GB data disk to every instance. A naive approach to container volumes might look something like the following:

{{% img "datadisk.png" "Data disks attached to VMSS" %}}

> If you're still learning containers, a quick note on container storage: it's important to understand that the data inside a container goes away when the container is destroyed. So first step is always to map a path from inside the container to a path outside the container. Ex: `C:\data` inside the container pointing to `D:\some_folder` on the host.

### The problem

Okay, looks great! My container can die and I still have my data stored on a disk, backed by Azure Storage - which replicates it multiple times inside my datacenter. Done! Right?

Wait, hold on - remember how I said container orchestrators introduce new challenges? Let's see what this looks like when a node fails, or needs to be taken offline for security updates:

{{% img "datadisk-failure.png" "Data disks attached to VMSS - failure" %}}

Not looking so great anymore. My data is indeed safe, but it's logically bound to a specific VM (Node 0). When Service Fabric reschedules my service, it's going to launch on a new node, see no data, and start from scratch. That's bad! Really bad! I'm going to get a different set of data every time my service moves across nodes. I'm actually in worse shape than if I were to just host my app on a VM at this point - I'm tied to a specific node, but I'm pretending that I'm not.

### A solution

This is where SMB Global Mapping can really help me out. It's like `net use` on steroids - it can map an SMB share for all users at the OS level. And lucky for me, Azure Files provides a hosted SMB service that persists data independently of any given VM node (or even cluster!). Here's what my storage looks like when I've configured everything:

{{% img "smbglobalmapping.png" "SMB Global Mapping" %}}

Cool, so I've offloaded my data onto Azure Files. Let's run through the same thought experiment - what happens when my container dies in this scenario?

{{% img "smbglobalmapping-failure.png" "SMB Global Mapping - failure" %}}

Awesome! I've got the mapping set up on the new node, pointing to the same Azure File share. My container reads the existing data, and can continue on. I've lost no data, and to the players on my Minecraft server - they've experienced a disconnect, but didn't completely lose everything in their world.

## Deep dive

This section explains what I'm doing in the GitHub repo and why.

### 1. Node configuration

First up, I need to create the SMB Global Mapping on the host. I could do this on all nodes manually, or with a CustomScript VM extension, but that's really tedious & not very dynamic. What if I want to have multiple Minecraft servers, with each on a different storage account or file share? Or what if I have a business requirement that says each customer's database must be segregated? The smart thing to do is to have Service Fabric configure my node on-demand whenever I want to run a container on it.

Thankfully, running containers on Service Fabric takes advantage of the same application lifecycle as Guest Executables and Reliable Services. That means I can create a `SetupEntryPoint`, and run it as `Administrator` to set up my SMB Global Mapping on-demand.

#### Defining the SetupEntryPoint

In `ServiceManifest.xml`, I'm launching a .bat file prior to running my container, which then launches a PowerShell script. Would love to make this simpler, but this is what I have working as of today. Below are the important snippets - **please** check out the GitHub repo - it has annotations, tips & tricks, and the full source:

```xml
<CodePackage Name="Code" Version="1.0.0">
  <SetupEntryPoint>
    <ExeHost>
      <Program>setup.bat</Program>
      <WorkingFolder>CodePackage</WorkingFolder>
      </ExeHost>
  </SetupEntryPoint>
  <EntryPoint>
    <ContainerHost>
      <ImageName>acanthamoeba/minecraft-server:nanoserver-1709</ImageName>
    </ContainerHost>
  </EntryPoint>
</CodePackage>
```

#### The .bat file

I didn't see a quick & easy way to run a PowerShell script, so the batch file just invokes PowerShell:

```bash
powershell.exe -ExecutionPolicy Bypass -Command ".\AddSMBGlobalMapping.ps1"
```

#### The .ps1 script

The PowerShell script does all the real work:

```powershell
# Create the SMB Global Mapping
$password = ConvertTo-SecureString $account_key -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\$account_name", $password
New-SmbGlobalMapping -RemotePath $mapping_remote_target -Credential $cred

# Symlink the SMB Global Mapping to a folder on the node (this lets me avoid tracking drive letters!)
pushd D:\smbglobalmappings
New-Item -ItemType SymbolicLink -Name minecraft -Target $mapping_remote_target -Force
```

#### Running SetupEntryPoint as Administrator

Finally, I need to run this all as Administrator, so I've got the following in `ApplicationManifest.xml` to tell Service Fabric to run `SetupEntryPoint` with elevated permissions:

```xml
<Policies>
  <RunAsPolicy CodePackageRef="Code" UserRef="SetupAdminUser" EntryPointType="Setup" />
</Policies>
<Principals>
  <Users>
    <User Name="SetupAdminUser">
      <MemberOf>
        <SystemGroup Name="Administrators"/>
      </MemberOf>
    </User>
  </Users>
</Principals>
```

### 2. Mapping the Container Volume

Finally, I need to map that symlink'd SMB Global Mapping to the data folder inside my container. That takes place in `ApplicationManifest.xml`:

```xml
<Policies>
  <ContainerHostPolicies CodePackageRef="Code">
    <Volume Source="D:\smbglobalmappings\minecraft" Destination="C:\data" IsReadOnly="false" />
  </ContainerHostPolicies>
</Policies>
```

## Results

{{% img "success.gif" "Nailed it!" %}}

It works great! I'm able to deploy one or more instances of Minecraft as a Windows Container to a Service Fabric cluster, with each pointing to its own data. I can take down a node and let Service Fabric take care of putting everything on a new node, and then have it reconnect to storage with minimal downtime - I'm talking seconds, not minutes or hours.

### What Went Well

* Stateful Windows Containers on Service Fabric are a viable & real scenario! If that's what you need, give it a try!
* Not much additional setup on top of having a basic container running.
* With some minor tweaks, you can actually deploy all of this from Azure Cloud Shell, Bash on Windows, Ubuntu, etc. :) I'm comfortable with a code-centric workflow, and Service Fabric development works well in that setting.

### What Was Difficult

* There are inherently a lot of moving parts - VMs, a Service Fabric cluster, node setup, and container volume mappings. It can be overwhelming if you're not deliberate about what you're doing.
* There wasn't an easy way to get all of this running with a [Docker Compose deployment (preview)](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-docker-compose), so you'll need to roll up your sleeves & dive into the XML.
* Azure Files is not currently (Feb 2018) designed for high-throughput scenarios. Target throughput is `60 MiB/sec` per the [Azure Files scalability and performance targets](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-scale-targets). Things are always changing, so be sure to check the official docs to see if there are any changes in the future.
* Java (specifically OpenJDK 8) and Windows Containers were a real pain. I experienced application timeouts & strange problems. Putting everything in a Hyper-V container made these go away at the expense of up-front resource allocation. See *Make JVM respect CPU and RAM limits* on the [OpenJDK image](https://hub.docker.com/_/openjdk/) on Docker Hub for more details. I would pick a Hyper-V container over process affinity every day, but it's interesting reading. I can't redistribute the Oracle JRE, so I'm not sure if it behaves differently.

### Next Steps

For higher throughput using Premium Managed Disks - I see no reason why I shouldn't be able to configure [Storage Spaces Direct (S2D)](https://blogs.msdn.microsoft.com/clustering/2017/08/10/container-storage-support-with-cluster-shared-volumes-csv-storage-spaces-direct-s2d-smb-global-mapping/) on a VM Scale Set + Service Fabric cluster. This moves the storage back to the cluster itself and gives me up to `250 MB/sec` throughput per disk, while keeping the benefits of not being tied to a specific node. I haven't tested this yet, but it sounds fun!

It's also now possible to [attach a disk to a specific instance](https://github.com/Azure/vm-scale-sets/tree/master/preview/disk#attach-detach-rest-api-description) of a VM Scale Set. In theory, that should let me change my SetupEntryPoint to mount a disk directly to a node.

Finally, the Service Fabric team is always working to improve the product, and they're [working on a volume driver](https://github.com/Azure/service-fabric-issues/issues/452) for an upcoming release. Don't be surprised if this entire post is superseded in the near future!

### Links!

* Go to the GitHub repo! [noelbundick/service-fabric-1709-demo](https://github.com/noelbundick/service-fabric-1709-demo)
* The Dockerfile for Minecraft on Windows Containers is quite interesting too! [noelbundick/minecraft-server](https://github.com/noelbundick/minecraft-server)
* For Linux SF clusters, check out [Haishi's Blog](https://haishibai.blogspot.com/2017/03/setting-up-highly-available-minecraft.html)
