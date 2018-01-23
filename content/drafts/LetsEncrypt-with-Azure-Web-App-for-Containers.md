---
title: LetsEncrypt with Azure Web App for Containers
tags:
---

# Set up your container w/ SSH

# Install Certbot locally

I'm using Ubuntu 16.04 via WSL

* https://certbot.eff.org/#ubuntuxenial-nginx

```shell
# See what options to run
certbot --help

# Manually get a cert for my domains w/o installing it
# Note: you must agree to IP logging
sudo certbot certonly -d noelbundick.com,www.noelbundick.com --manual
```

You'll get something like the following

```
Create a file containing just this data:

g7LuPeG2AbMvvlgVff5joOWLoSs3yqXT3jDRNgA66m8.9N_wE9GPLJRtS2AEPWVicsdQf-9D_xYYAD7X1FG-Bd4

And make it available on your web server at this URL:

http://www.noelbundick.com/.well-known/acme-challenge/g7LuPeG2AbMvvlgVff5joOWLoSs3yqXT3jDRNgA66m8
```

# SSH to your web app container

Run this in the SSH session inside your web app container

```shell
# Create the target directory
mkdir -p .well-known/acme-challenge

echo BNZxMPAKv84VqcwRcI4LXH5gWoUkFdw1uhzQodMvzMQ.9N_wE9GPLJRtS2AEPWVicsdQf-9D_xYYAD7X1FG-Bd4 > BNZxMPAKv84VqcwRcI4LXH5gWoUkFdw1uhzQodMvzMQ
echo g7LuPeG2AbMvvlgVff5joOWLoSs3yqXT3jDRNgA66m8.9N_wE9GPLJRtS2AEPWVicsdQf-9D_xYYAD7X1FG-Bd4 > g7LuPeG2AbMvvlgVff5joOWLoSs3yqXT3jDRNgA66m8
```

# Make sure your web app is listening on your custom domain name

# Back to certbot

Hit enter and you'll get output like the following:

```
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/noelbundick.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/noelbundick.com/privkey.pem
   Your cert will expire on 2018-01-16. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

# Preparing the cert for Azure

Per the docs, Azure wants the cert in PFX format
* https://docs.microsoft.com/en-us/azure/app-service-web/app-service-web-tutorial-custom-ssl#enforce-https-for-web-apps-on-linux

```shell
# Convert PEM to PFX. Don't forget the password!
sudo openssl pkcs12 -export -out noelbundick.pfx -inkey /etc/letsencrypt/live/noelbundick.com/privkey.pem -in /etc/letsencrypt/live/noelbundick.com/fullchain.pem

# Upload the cert & get the thumbprint
thumbprint=$(az webapp config ssl upload \
  --name noelbundick \
  --resource-group website-linux \
  --certificate-file noelbundick.pfx \
  --certificate-password <PFX_password> \
  --query thumbprint \
  --output tsv)

# Bind the cert to the web app
az webapp config ssl bind \
  --name noelbundick \
  --resource-group website-linux \
  --certificate-thumbprint $thumbprint \
  --ssl-type SNI
```

# Configure the stuff

* https://www.lastcoolnameleft.com/2017/08/letsencrypt-on-azure-app-service-for-linux/
* https://letsencrypt.org/getting-started/