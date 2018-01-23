---
title: Importing Certificates to Key Vault
tags:
  - azure
  - service fabric
date: 2017-06-13 16:19:09
---


I've found that creating a secure Service Fabric cluster can be a challenge - primarily because of the required interaction with Key Vault. In my {% post_link Service-Fabric-Cluster-Quickstart "Service Fabric Cluster Quickstart" %} post, I shared how the latest Azure PowerShell updates make it much easier to get up and running. That works great for dev clusters, but you'll really want to use an ARM template for any production environments so you can reap the benefits of repeatable declarative deployments.

This means that you've still got to figure out how to get your certificate into KeyVault and reference it properly. I've endured the pain on your behalf. This post will give you an easy to follow guide to get a certificate into Key Vault, then collect the parameters you'll need for ARM template deployment. I've compiled the steps for both Azure CLI and Azure PowerShell - choose the method that works best for you!

# Tools

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Azure PowerShell](https://www.powershellgallery.com/packages/AzureRM/4.1.0)

# Azure CLI

## Creating a Key Vault

I'm going to assume you're starting from scratch. To create a Key Vault

```bash
# Create a Resource Group to hold your Key Vault(s)
# Note this should be separate from your other resources so you can delete those other resource groups without impacting your registered certs
az group create -n keyvault -l southcentralus
 
# Create a Key Vault to hold your secrets
az keyvault create -n noel-temp -g keyvault --enabled-for-deployment --enabled-for-disk-encryption --enabled-for-template-deployment
```

> Note - your Key Vault should live in the same region as your compute resources. You can pass `--location <targetRegion>` to `az keyvault create` if you need to create the vault in a different region than the resource group

## Key Vault-generated Certificates

It's pretty simple to let Key Vault do all the work for you, then download the cert locally when you need it. If you use a supported CA, you can even configure Key Vault to enroll for certificates on your behalf - no leaking of keys! For simplicity, the policy in these examples will be set to generate self-signed certs from Key Vault.

```bash
# Tell Key Vault to create a certificate with the default policy
az keyvault certificate create --vault-name noel-temp -n cert1 -p "$(az keyvault certificate get-default-policy -o json)"
 
# Download the secret (private key information) associated with the cert
az keyvault secret download --vault-name noel-temp -n cert1 -e base64 -f cert1.pfx
 
# If you're on Linux, odds are you're not using .pfx format
# Convert from PFX to PEM format. Import password is blank
openssl pkcs12 -in cert1.pfx -out test.pem -outkey test.key -nodes
```

> Note - The PFX has no password by default, and I've specified `-nodes`, so the PEM has an unencrypted private key as well. For production deployments, use appropriate measures to secure your certs.

## Self-signed / Bring-your-own Certificates

You may want/need to sign your certs externally. Or perhaps your CA doesn't support integration with Key Vault. In these cases, you'll have an existing cert that you'll need to import into Key Vault. This is also pretty easy once you know the magic words.

```bash
# Create a new self-signed cert, with a custom FQDN
# Note: As of 5/7/17, KeyVault supports only 2048 bit RSA keys
openssl req -x509 -newkey rsa:2048 -subj "/CN=mycluster.southcentralus.cloudapp.azure.com" -days 365 -out cert2.crt -keyout cert2.pem -passout pass:Password!
 
# Convert PEM to PFX
openssl pkcs12 -export -in cert2.crt -inkey cert2.pem  -passin pass:Password! -out cert2.pfx -passout pass:Password!
 
# Upload to Key Vault
az keyvault certificate import --vault-name noel-temp -n cert2 -f cert2.pfx --password Password!
```

## Required Fields for ARM Deployment

Cool, you've got a cert in Key Vault. You'll need a few fields for your ARM template. Here's how to get them

```bash
# Source vault id
az keyvault show -n noel-temp --query id -o tsv
 
# Certificate thumbprint
az keyvault certificate show --vault-name noel-temp -n cert1 --query x509ThumbprintHex -o tsv
 
# Certificate url
az keyvault certificate show --vault-name noel-temp -n cert1 --query sid -o tsv
```

# Azure PowerShell

## Creating a Key Vault

I'm going to assume you're starting from scratch. Here's how to get started with a Key Vault

```powershell
# Create a Resource Group to hold your Key Vault(s)
# Note this should be separate from your other resources so you can delete those other resource groups without impacting your registered certs
New-AzureRmResourceGroup -Name keyvault -Location southcentralus
 
# Create a Key Vault to hold your secrets
New-AzureRmKeyVault -VaultName noel-temp -ResourceGroupName keyvault -Location southcentralus -EnabledForDeployment -EnabledForDiskEncryption -EnabledForTemplateDeployment
```

## Key Vault-generated Certificates

It's pretty simple to let Key Vault do all the work for you, then download the cert locally when you need it. If you use a supported CA, you can even configure Key Vault to enroll for certificates on your behalf. No leaking of keys! For simplicity, the policy in these examples will be set to generate self-signed certs from Key Vault.

```powershell
# Have Key Vault create the certificate with a simple policy
$policy = New-AzureKeyVaultCertificatePolicy -SubjectName "CN=mycluster.southcentralus.cloudapp.azure.com" -IssuerName Self -ValidityInMonths 12
Add-AzureKeyVaultCertificate -VaultName noel-temp -Name cert1 -CertificatePolicy $policy
 
# Download the secret (private key information) associated with the cert
$secret = Get-AzureKeyVaultSecret -VaultName noel-temp -Name cert1
$secretBytes = [System.Convert]::FromBase64String($secret.SecretValueText)
[System.IO.File]::WriteAllBytes("C:\temp\cert1.pfx", $secretBytes)
 
# Import the certificate to CurrentUser\My
Import-PfxCertificate -FilePath C:\temp\cert1.pfx -CertStoreLocation cert:\CurrentUser\My -Exportable
```

> Note - The PFX has no password by default. For production deployments, use appropriate measures to secure your certs.

## Self-signed / Bring-your-own Certificates

You may want/have to sign your certs locally. Or perhaps your CA doesn't support integration with Key Vault. In these cases, you'll have an existing cert that you'll need to import into Key Vault. This is also pretty easy once you know the magic words.

```powershell
# Create a new self-signed cert in CurrentUser\My
New-SelfSignedCertificate -Subject "CN=mycluster.southcentralus.cloudapp.azure.com" -CertStoreLocation cert:\CurrentUser\My
 
# Export the cert to a PFX with password
$password = ConvertTo-SecureString "Password!" -AsPlainText -Force
Export-PfxCertificate -Cert "cert:\CurrentUser\My\$($cert.Thumbprint)" -FilePath C:\temp\cert2.pfx -Password $password
 
# Upload to Key Vault
Import-AzureKeyVaultCertificate -VaultName noel-temp -Name cert2 -FilePath C:\temp\cert2.pfx -Password $password
```

## Required Fields for ARM Deployment

Cool, you've got a cert in Key Vault. You'll need a few fields for your ARM template. Here's how to get them

```powershell
# Source vault id
Get-AzureRmKeyVault -Name noel-temp | select ResourceId
 
# Certificate thumbprint
Get-AzureKeyVaultCertificate -VaultName noel-temp -Name cert1 | select Thumbprint
 
# Certificate Url
Get-AzureKeyVaultCertificate -VaultName noel-temp -Name cert1 | select SecretId
```

# Non-Recommended Methods

I've tried some other ways, with various levels of failure and frustration. I'm going to list my bad ideas to save you the trouble

## Azure CLI on PowerShell

This one is actually more or less supported, and it's super easy to stumble into this trap. Watch out - you'll spend far more time fighting the tooling (escaping quotes, etc) than actually getting work done. The resulting code is also awful to read. A working example that I was too stubborn to put down

```powershell
# Don't do this! Just use native PowerShell commands
$defaultPolicy = az keyvault certificate get-default-policy -o json
az keyvault certificate create --vault-name noel-temp -n cert3 -p $("""" + $defaultPolicy.Replace("""", """""") + """")
```

## Azure PowerShell on Linux

Basically there are **very** limited commands and modules available, and AzureRM isn't one of them.

## Azure CLI on Command Prompt

NOPE. Don't do it.

{% asset_img nope.gif "Just no" %}


# Links

* [Get Started with Azure Key Vault Certificates](https://blogs.technet.microsoft.com/kv/2016/09/26/get-started-with-azure-key-vault-certificates/)