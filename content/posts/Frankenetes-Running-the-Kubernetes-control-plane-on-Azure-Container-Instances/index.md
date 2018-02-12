---
title: Frankenetes! Running the Kubernetes control plane on Azure Container Instances
tags:
  - azure
  - kubernetes
  - aci
date: 2018-01-21 23:02:43
aliases:
  - /2018/01/21/Frankenetes-Running-the-Kubernetes-control-plane-on-Azure-Container-Instances/
---


I've been learning more about Kubernetes lately - both how to use it, and how it works. I recently took the time to run through Kelsey Hightower's [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way), specifically, the [Azure version](https://github.com/ivanfioravanti/kubernetes-the-hard-way-on-azure) by Ivan Fioravanti. In addition to learning a lot, it sparked some interesting ideas on my flight home...

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">Ignoring all the “this is dumb, whyyyy” reasons - in theory I should be able to spin up k8s master etcd/apiserver/controllermanager in Azure Container Instances w/ public IP’s no?</p>&mdash; Noel Bundick (@acanthamoeba) <a href="https://twitter.com/acanthamoeba/status/954435808332861440?ref_src=twsrc%5Etfw">January 19, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

My thought was that these are just apps, processes, binaries that run with flags - boring. Boring is good! They all have prebuilt images that let you run them as containers. And hey... [Azure Container Instances](https://docs.microsoft.com/en-us/azure/container-instances/) lets me run containers without VM's. All the hard work was done; I wanted to see if I could glue it together to create a "virtual Kubernetes cluster"...

But I also knew there were already plenty of [sane](https://github.com/Azure/acs-engine) [ways](https://docs.microsoft.com/en-us/azure/aks/) to run a Kubernetes cluster on Azure. And this felt like I was cobbling together parts from all over... and that if anyone did this in production, it could turn into a monster! So I decided to give my monstrous creation a name.

{{% img "frankenstein.jpg" "Boris Karloff as the Kubernetes, I mean Frankenstein monster" %}}

> Yes, I know that's actually Frankenstein's monster. Don't worry, your nits have been recorded.

Frankenetes! I'll walk you through what I did and some of the gotchas, so you can run your own virtual Kubernetes cluster on ACI

## Overview

The Kubernetes control plane consists of a few moving parts

* [etcd](https://coreos.com/etcd/): the distributed key/value store that holds cluster data
* apiserver: REST API that validates & controls all reads/writes to etcd
* controller manager: runs the core control loops of Kubernetes
* scheduler: updates pods in the apiserver & assigns them to nodes

I figured once those were in place, I should be able to connect nodes to my cluster and schedule workloads.

> This is a total hack, so I didn't secure **anything**. I don't see a reason why you wouldn't be able to secure all of this with TLS - it just wasn't the initial goal.

## Prerequisites: Azure

I set up a couple of things in Azure to get started. A resource group to hold everything, and a storage account for all of my persistent data. Right now, it's mainly etcd data, but in the future, I can also store certs, logs, and so on.

```bash
AZURE_RESOURCE_GROUP=frankenetes

# As of 2.0.25, you have to use 'export' for it to automagically set your storage acct
# https://github.com/Azure/azure-cli/issues/5358
export AZURE_STORAGE_ACCOUNT=frankenetes

az group create -n $AZURE_RESOURCE_GROUP -l eastus
az storage account create -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP

AZURE_STORAGE_KEY=$(az storage account keys list -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP --query '[0].value' -o tsv)
```

{{% img "young_frankenstein.jpg" "Maybe I should have named it Abby Normal" %}}

## etcd

As the backing data store, etcd needed to come up first. Kubernetes the Hard Way had most of the flags I needed, and the help for `az container create` gave me everything I needed to map my `data-dir` to an Azure File share.

### Write ahead log

Unfortunately, I ran into some unusual issues on startup. My limited understanding is that etcd takes a lock on the write ahead log directory, then renames a temp file to boot up. This works fine inside the container, but when mapped to Azure Files, it can't perform the rename (due to the lock), fails, and then the container gets stuck in a crash loop. Setting the `wal-dir` path to something inside the container resolves the issue, but since the log no longer outlives the container, the data store can suffer data loss.

> This could likely be solved if ACI supported additional volume types, etcd was patched to work around the locking issue, etc. Like I said, this is a hack...

### DNS

My next issue was the `advertise-client-urls`. ACI gave me a public IP from, but it was dynamically generated and I wasn't able to specify it or know it until **after** the container group had been created. I needed another level of abstraction - DNS to the rescue! I'm listening on all addresses inside the container, and then I configured DNS to let the apiserver resolve my etcd host from outside the container.

```bash
# Create an Azure File share to hold cluster data
az storage share create -n etcd

#WARNING! This isn't truly useful until I fix the write ahead log & secure the cluster
#TODO: figure out why I get "create wal error: rename /etcd/data/member/wal.tmp /etcd/data/member/wal: permission denied" when --wal-dir is not set
az container create -g $AZURE_RESOURCE_GROUP \
  --name etcd \
  --image quay.io/coreos/etcd:v3.2.8 \
  --azure-file-volume-account-name $AZURE_STORAGE_ACCOUNT \
  --azure-file-volume-account-key $AZURE_STORAGE_KEY \
  --azure-file-volume-share-name etcd \
  --azure-file-volume-mount-path /etcd \
  --ports 2379 2389 \
  --ip-address public \
  --command-line '/usr/local/bin/etcd --name=aci --data-dir=/etcd/data --wal-dir=/etcd-wal --listen-client-urls=http://0.0.0.0:2379 --advertise-client-urls=http://frankenetes-etcd.noelbundick.com:2379'

# Grab the ipAddress.ip property & update the A record for 'frankenetes-etcd.noelbundick.com'
```

And here's where I updated my DNS on CloudFlare

{{% img "frankenetes-etcd-dns.png" "Adding the etcd record in CloudFlare DNS" %}}

Finally, I verified everything by running a few etcdctl commands against the remote `frankenetes-etcd.noelbundick.com:2379` host

## apiserver

Next up - the apiserver. I used the latest stable [hyperkube](https://github.com/kubernetes/kubernetes/tree/master/cluster/images/hyperkube) image to run the API server, and connected to etcd using the DNS name.

```bash
# Create a share to hold logs/etc
az storage share create -n apiserver

az container create -g $AZURE_RESOURCE_GROUP \
  --name apiserver \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --azure-file-volume-account-name $AZURE_STORAGE_ACCOUNT \
  --azure-file-volume-account-key $AZURE_STORAGE_KEY \
  --azure-file-volume-share-name apiserver \
  --azure-file-volume-mount-path /apiserverdata \
  --ports 6445 \
  --ip-address public \
  --command-line '/apiserver  --advertise-address=0.0.0.0 --allow-privileged=true --apiserver-count=1 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/apiserverdata/log/audit.log --authorization-mode=Node,RBAC --bind-address=0.0.0.0 --etcd-servers=http://frankenetes-etcd.noelbundick.com:2379 --runtime-config=api/all --v=2 --runtime-config=admissionregistration.k8s.io/v1alpha1 --enable-swagger-ui=true --event-ttl=1h --service-node-port-range=30000-32767 --insecure-bind-address=0.0.0.0 --insecure-port 6445'


# Grab the ipAddress.ip property & update the A record for 'frankenetes-apiserver.noelbundick.com'
```
> Running on 6445 instead of 6443 was me "securing" my cluster by not using a default port. Security through obscurity is dumb. Don't do what I did for anything that matters

And one more DNS update for the apiserver

{{% img "frankenetes-apiserver-dns.png" "Adding the apiserver record in CloudFlare DNS" %}}

To verify, I hit the apiserver endpoint by running `curl http://frankenetes-apiserver.noelbundick.com:6445/version`

## Controller manager

Cool! The hard part was done. Smooth sailing from here on out. The controller manager was pretty straightforward - I just pointed it at the apiserver. No certs, no problems!

```bash
az container create -g $AZURE_RESOURCE_GROUP \
  --name controllermanager \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --command-line '/controller-manager --address=0.0.0.0 --cluster-cidr=10.200.0.0/16 --cluster-name=kubernetes --leader-elect=true --master=http://frankenetes-apiserver.noelbundick.com:6445 --service-cluster-ip-range=10.32.0.0/24 --v=2'
```

## Scheduler

Same story for the scheduler - it just needs to know where the apiserver is. Around this point, I really started to appreciate how modular the Kubernetes core components were.

```bash
az container create -g $AZURE_RESOURCE_GROUP \
  --name scheduler \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --command-line '/scheduler --leader-elect=true --master=http://frankenetes-apiserver.noelbundick.com:6445 --v=2'
```

## kubeconfig

I needed a way to connect to my cobbled together Kubernetes cluster (still with no nodes). I used the following to set up my kubeconfig and verify everything was working.

```bash
# Set up cluster/context info in a standalone file
kubectl config set-cluster frankenetes --server=http://frankenetes-apiserver.noelbundick.com:6445 --kubeconfig=frankenetes.kubeconfig
kubectl config set-context default --cluster=frankenetes --kubeconfig=frankenetes.kubeconfig
kubectl config use-context default --kubeconfig=frankenetes.kubeconfig

# Use the kubeconfig & cross your fingers!
export KUBECONFIG=frankenetes.kubeconfig
kubectl version
kubectl api-versions
```

{{% img "young_frankenstein_2.jpg" "Frankenetes is alive" %}}

## Nodes!

I ran through the manual steps in Kubernetes the Hard Way on Azure to create a single node, stripping out all the TLS bits along the way, and substituting 1.9.2 for 1.8.0.

Relevant sections:

* [Compute resources](https://github.com/ivanfioravanti/kubernetes-the-hard-way-on-azure/blob/master/docs/03-compute-resources.md) - Virtual Network, Firewall Rules, Kubernetes Workers
* [Bootstrapping the Kubernetes Worker Nodes](https://github.com/ivanfioravanti/kubernetes-the-hard-way-on-azure/blob/master/docs/09-bootstrapping-kubernetes-workers.md)

After all was said & done, I was able to run pods on my node, all being controlled by Frankenetes running in ACI!

{{% img "pods.jpg" "Lots of work to make it useful, but it does work!" %}}

## What's next?

Not sure! This was a learning project to understand more about how the Kubernetes control plane really worked. It doesn't seem mysterious anymore. I feel like I can make it do what I want now. Here are some of my ideas so far. If you've got more, please [hit me up on Twitter](https://twitter.com/acanthamoeba)!

### TLS

This is horribly insecure. Wide open. I should be able to use the DNS names to generate proper certs and secure everything. And then, of course, automate it all away.

### DNS

I want to automate all the DNS steps using [Azure Event Grid](https://docs.microsoft.com/en-us/azure/event-grid/). My plan is to create the container group with a tag containing my desired DNS name (needs a PR for azure-cli!) Then, I can subscribe to Azure Resource Manager events and fire off an Azure Function that will take care of updating my DNS records based on the tag and the IP address that was provisioned. Think of it as a kind of Frankenstein version of kube-dns!

### Virtual Kubelet

Why stop at a virtual master control plane when I could have virtual nodes! I want to wire up [virtual-kubelet](https://github.com/virtual-kubelet/virtual-kubelet). If that works, I could interact with my virtual cluster with my familiar Kubernetes toolkit (kubectl, kubectx, kubens, etc), but then **all** of my workloads would run on ACI. Not sure that's a useful concept, but hey - I'll give it a try and see if anyone likes it!

{{% img "young_frankenstein_3.gif" "Me, when I got everything up and running" %}}
