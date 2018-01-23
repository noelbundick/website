---
title: Learning Azure Resource Manager - Introduction
tags:
  - azure
  - azure-resource-manager
date: 2017-07-14 11:16:47
---


Check out the accompanying repo: [https://github.com/noelbundick/arm-samples](https://github.com/noelbundick/arm-samples)
***

# Introduction

When I joined my current team a few months back, one of the first pieces of advice I received was "Use the Azure Portal to look at things, but make all your changes with the CLI or an ARM template". That has turned out to be great advice, and I now give the same advice to everyone who's serious about becoming an Azure expert. 

The Azure CLI 2.0 has plenty of great docs on getting started and usage, but when I went to dive into Azure Resource Manager, it seemed as if all roads just pointed me to the [azure-quickstart-templates](https://github.com/Azure/azure-quickstart-templates) repo. Samples are no replacement for proper documentation! I had no context, and I was left staring at folders upon folders of cryptic JSON files. What I really wanted was a guide that told me what I was looking at, why it was important, and how it all worked in a step-by-step way.

> Note: The official Microsoft docs are quickly getting much better. Make sure to also visit [https://docs.microsoft.com/en-us/azure/azure-resource-manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager)

So here it is! I've distilled my hacking around & personal notes and have turned it into a guide that increases in complexity over time rather than throwing you in the deep end all at once.

# Why should you care?

Great question! I think it's easiest for me to share my own story, and then let you decide if you want to care or not :)

My background seems fairly common among devs - I started out configuring features using the GUI, moved on to editing config files, and then later got into hacking together my own deployment scripts. The common thread across all is that these were imperative processes - steps were typically performed or executed one at a time and often had to be done in a specific order. If something failed along the way (which it often did!), I was left troubleshooting for hours. Cleaning up or removing apps was similarly painful.

For me, using ARM templates makes me much more productive. Assembling a cluster of machines on the same virtual network used to take me days, if not weeks. Creating a bunch of databases and websites was easier, but was still hours worth of work. I do this kind of thing on a daily basis now, often several times a day. Gone are the days of "Wait, how did I do that again?". I can keep a set of known working templates and then parameterize & tweak as needed.

## Benefits to Noel

| | |
|---|---|
|Declarative|Define what you want to exist. Let Azure take care of handling errors, retries, etc.|
|Repeatable|Easily reproduce an application for dev/test/prod environments|
|Easy cleanup|Deploy a template to a resource group for dev/test, then delete the entire thing when you're done|
|Documentation|There's opportunity to retain & share knowledge rather than losing it to one-off operations|

* * *

Maybe some of those resonate with you, too. If so, keep reading!

# How to get started

Let's start with the basics - just the structure. ARM templates typically consist of a template file and a parameters file, both written in JSON. 

## Template

The template is where you'll define what resources (storage accounts, virtual machines, web sites, etc) you want to create in Azure. There are a ton of options for customization, but I'm going to keep it simple with an annotated blank template.

```javascript
{
  // Required. All templates currently use the following schema
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
 
  // Required. Set this to whatever you want. It's so you can keep track of your template's version
  "contentVersion": "1.0.0.0",
 
  // You can define parameters to pass into the template, which can be referenced later. Ex: the name of a storage acccount
  "parameters": {
  },
 
  // Create variables by composing functions, and then reuse them in your template
  // These variables can reference parameters or other variables
  "variables": {
  },
 
  // This is where you'll create VM's, databases, etc. Each resource type will use a different set of properties
  "resources": [
  ],
 
  // Optionally capture some data, like the name of a storage account or an SSH connection string
  "outputs": {
  }
}
```

> Note: JSON doesn't support comments, so the above example isn't actually valid. Everything in the [https://github.com/noelbundick/arm-samples](https://github.com/noelbundick/arm-samples) repo has been tested & runs - so hop over there to copy/paste code!

## Parameters

Parameters aren't required, but are encouraged! For example, a single parameter such as "name" can be used as a seed to generate names for all of your resources. You can pass parameters inline using the Azure CLI or PowerShell, but it's most common to put them in their own file.

```javascript
{
  // Required. All parameter files currently use the following schema
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
 
  // Required. Set this to whatever you want. It's so you can keep track of your parameter file version
  "contentVersion": "1.0.0.0",
 
  // Define your parameters here. These need to match up with what's been defined in the parameters
  // section of your template. Mistyped names or omission of a required parameter will result in an error!
  "parameters": {
  }
}
```

# Next steps

## [https://github.com/noelbundick/arm-samples](https://github.com/noelbundick/arm-samples)

I put my samples together and annotated them prior to starting this guide. The feedback I've received so far says the repo is a helpful resource for learning ARM templates. I hope you'll find it useful as well.

## [Create your first ARM template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-create-first-template)

The official docs site is improving every day, and this is a great example. Now that you know what the structure of a template looks like, you can follow along here and start creating your own resources.