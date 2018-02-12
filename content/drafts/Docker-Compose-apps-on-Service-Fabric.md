---
title: Docker Compose apps on Service Fabric
draft: true
tags:
  - docker
  - azure
  - servicefabric
---

* Needs cluster to be created with preview SDK version
* Possible trouble with self-signed certs
* 

## Bash
```bash
# az sf cluster select
# az sf compose create 
```

## PowerShell

```powershell
Connect-ServiceFabricCluster -ConnectionEndpoint trash123.southcentralus.cloudapp.azure.com:19000 -KeepAliveIntervalInSec 10 -X509Credential -ServerCertThumbprint 931078574dfb67
d0d435f381c367d8462596f25f -FindType FindByThumbprint -FindValue 931078574dfb67d0d435f381c367d8462596f25f -StoreLocation CurrentUser -StoreName My

# New-ServiceFabricComposeApplication
```
