---
title: Frankenetes! Serverless Kubernetes
tags:
  - azure
  - kubernetes
  - aci
date: 2018-02-24
---

In a [recent post]({{< relref "posts/Frankenetes-Running-the-Kubernetes-control-plane-on-Azure-Container-Instances" >}}), I showed how it was possible to run the Kubernetes control plane components on Azure Container Instances. The cloud moves fast, and there have been some [great improvements to ACI](https://azure.microsoft.com/en-us/updates/aci-feb/) in the last month. In keeping up with the times, I've upgraded Frankenetes from just a virtual control plane to a full-blown virtual cluster! Look out, hacks incoming!

> Check out the code on GitHub: [https://github.com/noelbundick/frankenetes](https://github.com/noelbundick/frankenetes)

## DNS

Previously, I was manually creating DNS records to glue my containers together. ACI now lets you specify a `--dns-name-label` parameter on creation, which is awesome! Here's a code snippet of the new option:

```bash
az container create -g frankenetes \
  --name etcd \
  --image quay.io/coreos/etcd:v3.2.8 \
  --ports 2379 2389 \
  --location eastus \
  --ip-address public \
  --dns-name-label frankenetes-etcd \
  --command-line "/usr/local/bin/etcd --name=aci --listen-client-urls=http://0.0.0.0:2379 --advertise-client-urls=http://frankenetes-etcd.eastus.azurecontainer.io:2379"
```

> Note the use of the fully qualified domain name in the startup command. The pattern for DNS names on Azure Container Instances is `{DNS name label}.{location}.azurecontainer.io`

Container groups get automatically assigned a new public IP, and then the DNS name points to it. Other applications (or container groups!) can use the DNS name to access the container. Here's a diagram of how this works in Frankenetes with multiple container groups in play:

{{% img "dns.png" "Frankenetes component communication" %}}

## Virtual-Kubelet

A cluster is no good if you have no nodes to run things on. And since this is a science experiment to see what's possible, I've added [virtual-kubelet](https://github.com/virtual-kubelet/virtual-kubelet), which will give me **even more** container groups!

Normally you run virtual-kubelet as a pod on your cluster... but I don't really have one of those yet, so I'm running it as yet another Azure Container Instance!

```bash
az container create -g $AZURE_RESOURCE_GROUP \
  --name virtual-kubelet \
  --image microsoft/virtual-kubelet \
  --azure-file-volume-account-name $AZURE_STORAGE_ACCOUNT \
  --azure-file-volume-account-key $AZURE_STORAGE_KEY \
  --azure-file-volume-share-name virtual-kubelet \
  --azure-file-volume-mount-path /etc/virtual-kubelet \
  -e AZURE_AUTH_LOCATION=/etc/virtual-kubelet/credentials.json ACI_RESOURCE_GROUP=frankenetes-pods ACI_REGION=$REGION \
  --command-line "/usr/bin/virtual-kubelet --provider azure --nodename virtual-kubelet --os Linux --kubeconfig /etc/virtual-kubelet/frankenetes.kubeconfig"
```

> I've told virtual-kubelet to run all pods for that "node" in the `frankenetes-pods` resource group, so I can apply different rules to application container groups than my control plane container groups.

From a Kubernetes perspective, virtual-kubelet is just a node. It talks to the apiserver and listens for the pods that it should be running. When it finds a new one assigned that's not already active, it spins up a new pod. 

I'm using the ACI provider to spin up more container groups, but virtual-kubelet is open source and there's also a provider for [hyper.sh](https://hyper.sh/). You could also write your own provider to run containers anywhere you want - another cloud, on bare-metal, to spin up a VM per container, etc. If you like interacting with your apps via the Kubernetes API, it might be a cool way to implement features you need without waiting for upstream support.

### Running pods

VK conveniently maps Kubernetes concepts to ACI concepts, so the following command:

```bash
kubectl run nginx --image=nginx --port 80
```

Results in the following flow to create a new container group with a public IP:

{{% img "virtual-kubelet.png" "How virtual-kubelet creates pods" %}}

## What's next?

I have absolutely zero legitimate use case for this mad scientist experiment - other than it's fun and I want to see what's possible. Here are some ideas I'm kicking around.

### Pausing/restarting

My etcd container is currently mapped to Azure Files, which lets me persist my cluster configuration. I should be able to delete all of my container groups, and spin them back up and let my virtual-kublet create new pods. This would give me an on-demand Kubernetes cluster that's billed by the second. Now that's pretty cool!

So far, I've had some problems with the etcd write ahead log when it's mapped to Azure Files. If I can resolve that issue, I think this is good to go!

### TLS

This is still **horribly insecure** - please don't run code from my repo and run anything real on it :)

### Open Service Broker for Azure

What's more serverless than an ACI-hosted Kubernetes cluster? Using hosted Azure services, of course! [Open Service Broker for Azure](https://github.com/Azure/open-service-broker-azure) lets you create databases, queues, and more - all from the Kubernetes API.