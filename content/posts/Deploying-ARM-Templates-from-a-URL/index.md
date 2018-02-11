---
title: Quick tip - Deploying ARM Templates from a URL
tags:
  - azure
  - azure-resource-manager
date: 2017-08-07 07:30:04
aliases:
  - /2017/08/07/Deploying-ARM-Templates-from-a-URL/
---


# tl;dr version

Use something like following to create a new deployment from an ARM template URL

```html
<!-- Make sure to URI encode the template file location! -->
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnoelbundick%2Farm-samples%2Fmaster%2F1-storageaccount%2Ftemplate.json">Deploy to Azure</a>
```

OR

```javascript
let armTemplateUri = 'https://raw.githubusercontent.com/noelbundick/arm-samples/master/1-storageaccount/template.json';
let deployLink = `https://portal.azure.com/#create/Microsoft.Template/uri/${encodeURIComponent(armTemplateUri)}`;
window.location = deployLink;
```

# Explanation

Often enough, I find myself with an ARM template that I want to share with a teammate or customer so they can test it out or deploy into their own subscription. It's really not too painful when everyone's comfortable with deployments, but if not, the issues are always the same. Transferring a file via email, Slack, pastebin or whatever. Making sure they have a correctly configured deployment tool - Azure CLI, PowerShell, etc. There are also times I just want to provide a "Click here and you can deploy/run this" button attached to a demo, blog post or a GitHub repo.

The [Deploy to Azure Button](https://deploy.azure.com) solves exactly this problem, but it's specificially intended for GitHub/BitBucket repositories. I wanted something more flexible that didn't impose defaults or conventions on me.

I didn't find any obvious tips on this. I eventually found a reference on [deploying Function Apps](https://docs.microsoft.com/en-us/azure/azure-functions/functions-infrastructure-as-code), then finally found a more authoritative example buried in the [Azure/portaldocs](https://github.com/Azure/portaldocs/blob/master/portal-sdk/generated/portalfx-create-deploytoazure.md) repo. It reads:

To deep-link to the template deployment blade, URL-encode your hosted template URL and append it to the end of this URL:

```
https://portal.azure.com/#create/microsoft.template/uri/**<url-encoded-template-path>**
```

Verdict: it works great! You can change parameters, specify the target resource group, and dig into the template to see details before hitting deploy.

{{% img "custom_deployment.png" "Fill in some parameters, and voila!" %}}

Test it yourself with a storage account below

[![Deploy to Azure](https://azuredeploy.net/deploybutton.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnoelbundick%2Farm-samples%2Fmaster%2F1-storageaccount%2Ftemplate.json)