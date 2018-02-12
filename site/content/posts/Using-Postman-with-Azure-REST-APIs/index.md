---
title: Using Postman with Azure REST APIs
tags: 
  - azure
date: 2017-05-23 10:09:44
aliases:
  - /2017/05/23/Using-Postman-with-Azure-REST-APIs/
  - /2017/05/24/Using-Postman-with-Azure-REST-APIs/
---

Azure has [a plethora of APIs](https://docs.microsoft.com/en-us/rest/api/) to interact with, and a lot of them have friendly wrappers via the Azure Portal, CLI or PowerShell cmdlets. But sometimes, I want to interact with services on a more detailed level, or try out newer API versions than the current tooling allows for. 

[Postman](https://www.getpostman.com) is an awesome tool for interacting directly with APIs. Unfortunately, dealing with authorization isn't always straightforward. I've compiled some of my recent hacking around with the hope that it will save you some pain and help you get you started. 

Note: Most Azure REST APIs use OAuth2, which is what I'll focus on here. For other APIs (specifically Azure Storage), check the links at the end of of the post. 

# Prerequisites

I use Bash (on Windows) for everything these days. To follow along, you'll want the following:

* Bash on Windows
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli#windows)
* [jq](https://stedolan.github.io/jq/) - This is a super handy command-line JSON processor ( `sudo apt-get install jq` )

# Configure Azure Active Directory

First, we'll need to set up an application and grant some permissions in AAD. I've created a script to help you out, because the configuration wasn't immediately obvious (hence this post).

## Create Service Principal via script

```bash
# Download script & mark as executable
curl -O https://gist.githubusercontent.com/noelbundick/1e1854b14c0a134de778345a6884a168/raw/c143e08128857632a9d566eadf2430adc04ff38c/createServicePrincipal.sh
chmod +x createServicePrincipal.sh
 
# Usage
./createServicePrincipal.sh NAME
```

<script src="https://gist.github.com/noelbundick/1e1854b14c0a134de778345a6884a168.js"></script>

## Add Required Permissions in the Portal

The app (Postman) needs some permissions to be able to access Azure on your behalf. I'm not sure how to update the application manifest automatically just yet, so I'm going to point you to the Portal. If you know how to do this in a script, please leave me a comment or ping me on [Twitter](https://twitter.com/acanthamoeba). To save on navigation, the script will output the specific URL you need. Follow these steps:

1\. Go to Required Permissions 

{{% img "aad-application.png" "Go to Required Permissions" %}}

2\. Add a Required Permission

{{% img "aad-required-permissions.png" "Click the Add button" %}}

3\. Select 'Windows Azure Service Management API'

{{% img "aad-api-azure-service-management.png" "Select Windows Azure Service Management API" %}}

4\. Select 'Access Azure Service Management as organization users (preview)'

{{% img "aad-delegated-permissions.png" "Enable delegated permissions" %}}

5\. Done!

# Configuring Postman

We'll be using Postman's native OAuth2 functionality here to get an OAuth token & attach it to our requests. The output from the previous script has all the info you need to configure Postman.

1\. Visit the Authorization tab and select `OAuth 2.0`

{{% img "postman-authorization.png" "Postman Authorization tab" %}}

2\. Hit `Get New Access Token`

{{% img "postman-get-access-token.png" "Select OAuth2" %}}

3\. Enter the values from the script output and make sure you're using the `Authorization Code` grant type

{{% img "postman-oauth2-config.png" "Use the output values from the script" %}}

4\. `Request Token`! You'll be prompted to login with your credentials. On your first time, you'll also need to authorize your app

{{% img "postman-initial-grant.png" "You'll see something like this when you get your first token" %}}

5\. You'll see a new token in your list of Existing Tokens. Select it & hit `Use Token`. This will set the Authorization header of your current request to use the Bearer token you just got from AAD

{{% img "postman-tokens.png" "Look at that shiny token!" %}}

6\. All done! You've got a proper Authorization header, and can now make requests against Azure Resource Manager. When your token expires, repeat steps 4 and 5 to get a new token.

{{% img "postman-bearer-token.png" "A fully armed and operational Authorization token" %}}

# Next steps

You should be able to modify this flow to work for lots of other services that use Azure AD. If you do, make sure you pay attention to a few things in particular:

* The Required Permissions for the application
  * Ex - If you're hitting Power BI, you'll want to add it to the app in AAD
* The Auth URL and Access Token URLs
  * Pay special attention to the `resource` parameter in the query string and make sure it lines up with your target service

# References
There are a ton of cool things you can do with Postman - this only scratches the surface. These links were helpful for me, and are a great place to learn more. Thanks for reading!

* [How to Use Azure Active Directory (AAD) Access Tokens in Postman](http://blog.jongallant.com/2017/03/azure-active-directory-access-tokens-postman/) - Use Postman environment variables with AAD tokens
* [Using Postman Invoking Azure Resource Management APIs](http://blog.tyang.org/2017/04/26/using-postman-invoking-azure-resource-management-apis/) - A PowerShell-centric approach
* [Generate Azure Storage SAS Tokens via Postman](http://blog.jongallant.com/2017/03/azure-storage-sas-tokens-postman/) - Use the Pre-request Script sandbox to easily use the Azure Storage REST API