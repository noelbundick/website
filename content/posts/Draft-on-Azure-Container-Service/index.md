---
title: Draft on Azure Container Service
tags:
  - azure
  - kubernetes
date: 2017-05-31 12:22:12
todo: Update with https://medium.com/@deeeet/draft-on-google-container-engine-f806aa42875c
aliases:
  - /2017/05/31/Draft-on-Azure-Container-Service/
---


[Draft](https://github.com/Azure/draft) is a tool designed to streamline development on Kubernetes, [announced today](https://azure.microsoft.com/en-us/blog/streamlining-kubernetes-development-with-draft/). Sounds pretty useful to me - it looks like it could make it easy for developers to take advantage of Kubernetes without having to dive in and learn all the internals up front. Or for those who are already familiar with k8s - it could save some keystrokes, which I'm all for. 

With that in mind, I thought it might be useful to try it out myself, and capture my step-by-step instructions as a guide for anyone else who wants to try it out.

# Tools

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - I'm using Bash on Windows

# Cluster Setup

I'm going to spin up a Kubernetes cluster in Azure using Azure Container Service. This makes setup super easy and then I can delete everything when I'm done playing around.

```bash
# Create a resource group
az group create -n trash1 -l southcentralus
 
# Create a private container registry to hold images
az acr create -n noelacr -g trash1 --admin-enabled --sku Basic
 
# Create a Kubernetes cluster via ACS
az acs create -n noelk8s -g trash1 -t kubernetes
 
# Get kubectl
az acs kubernetes install-cli
 
# Download Kubernetes cluster configuration
az acs kubernetes get-credentials -n noelk8s -g trash1
 
# Install Helm tools locally
curl -O https://storage.googleapis.com/kubernetes-helm/helm-v2.4.2-linux-amd64.tar.gz
tar -zxvf helm-v2.4.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
 
# Install Helm onto the cluster (this uses the config you downloaded to talk to the cluster)
helm init
```

Draft uses a wildcard domain and an ingress controller to make life easier, so I set that up as well

```bash
# Setup an Ingress Controller
helm install stable/nginx-ingress --namespace=kube-system --name=nginx-ingress
 
# Get the External IP for the ingress controller
kubectl get services --namespace kube-system -w nginx-ingress-nginx-ingress-controller
```

My DNS is hosted on Cloudflare - I added the following

{{% img "wildcard-dns.png" "Wildcard DNS for Draft apps" %}}

So that's Kubernetes, Azure Container Service, and Helm. Last step - Draft itself.

```bash
# Install Draft tools locally
curl -O https://azuredraft.blob.core.windows.net/draft/draft-canary-linux-amd64.tar.gz
tar -xzf draft-canary-linux-amd64.tar.gz
sudo mv linux-amd64/draft /usr/local/bin
 
# Get the registry credentials
az acr credential show -n noelacr
 
# Format & base64 encode the registry login
echo '{"username":"noelacr","password":"+X9/D+/+=CF/c/6/E/=+QS=e=d85=UPB","email":"noelbundick@gmail.com"}' | base64 -w 0
 
# Install Draft to your cluster
draft init --set registry.url=noelacr.azurecr.io,registry.org=draft,registry.authtoken=eyJ1c2VybmFtZSI6Im5vYnVuIiwicGFzc3dvcmQiOiIrWDkvRCsvKz1DRi9jLzYvRS89K1FTPWU9ZDg1PVVQQiIsImVtYWlsIjoibm9idW5AbWljcm9zb2Z0LmNvbSJ9Cg==,basedomain=draft.noelbundick.com
```

# Developer Workflow

The cluster is all set up. These steps are what a typical developer might experience after the Kubernetes guru configured the dev cluster. I followed along with the default [Python example](https://github.com/Azure/draft/tree/master/examples/python). Step-by-step below!

```bash
# Devs would install Draft tools locally as well
curl -O https://azuredraft.blob.core.windows.net/draft/draft-canary-linux-amd64.tar.gz
tar -xzf draft-canary-linux-amd64.tar.gz
sudo mv linux-amd64/draft /usr/local/bin
 
# Create a folder for my app
mkdir pythonapp && cd pythonapp
 
# Download python example files from GitHub
curl -O https://raw.githubusercontent.com/Azure/draft/master/examples/python/app.py
curl -O https://raw.githubusercontent.com/Azure/draft/master/examples/python/requirements.txt
 
# Use Draft to create a Kubernetes-ready app
draft create
```

Draft saw my files, knew I had a Python app, and generated an appropriate Dockerfile & Helm Chart for me. Smart!

```bash
# Use Draft to deploy my app
draft up
```

This will give you a crazy name, like http://washing-marmot.draft.noelbundick.com

```bash 
# Check it out - in a new console window/tab/etc
curl http://washing-marmot.draft.noelbundick.com
```

This is all pretty cool so far. I started out with the most barebones of Python apps, and I've got a load balanced set of containers running on a real cluster. After the initial setup, all I have to do is run `draft up`, and everything gets deployed without me having to worry about the details. 

The next part is even better!

## Live Updates

Open up **app.py** in an editor and save it. Draft watches your local file system, packages up your code in a new Docker container, and will make a live update on Kubernetes. 

> Note: Vim immediately registered a file change upon opening the file - Nano and VS Code gave me better results.

I don't even have a Docker daemon running locally, so these are being built on my cluster - pretty neat!

If you close your terminal and want to get back up and running, just run `draft up` in the folder again, and you're back into watch mode.

## Cleaning Up

I'm done playing with this cluster, and I don't want to keep paying for it

```bash
# Delete the resource group & clean up
az group delete -n trash1 -y --no-wait
```

# Closing Thoughts

Draft is still bleeding-edge. I'm looking forward to seeing it grow. Smarter tools like this are essential as technology grows in complexity - no one person can keep up with all the moving parts. I also think there's an opportunity for tools like Draft to lower the barrier to entry so that more people have an opportunity to jump in, try things out, and contribute.