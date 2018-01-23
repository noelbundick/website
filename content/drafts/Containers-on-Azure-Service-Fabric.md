---
title: Containers on Azure Service Fabric
tags:
  - azure
  - service fabric
---

* Include OMS / App Insights

In the post {% post_link Service-Fabric-Cluster-Quickstart "Service Fabric Cluster Quickstart" %}, I played around a bit with Service Fabric and got a secure cluster running relatively painlessly. I thought it would be fun to experiment with the new ability to run containers for both Windows Server 2016 and Linux. My plan is to create a couple of simple cross-platform apps that talk to each other, and then deploy them on a Windows cluster, then a Linux cluster & see what happens.

# Windows Containers

```powershell
New-AzureRmResourceGroup -Name noelsf -Location westus2
$password = ConvertTo-SecureString "Password!1234" -AsPlainText -Force
New-AzureRmServiceFabricCluster -ResourceGroupName noelsf -CertificateOutputFolder C:\temp\noelsf -CertificatePassword $password -OS WindowsServer2016DatacenterwithContainers -VmPassword $password -Location westus2
Import-PfxCertificate -FilePath C:\temp\noelsf\noelsf20170519111723.pfx -Password $password -CertStor
eLocation Cert:\CurrentUser\My -Exportable
```

## Output
```
VmUserName   : adminuser
Certificates : Primary key vault and certificate detail:
                KeyVaultId : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourceGroups/noelsf/providers/Microsoft.KeyVault/vaults/noelsf
                KeyVaultName : noelsf
                KeyVaultCertificateId : https://noelsf.vault.azure.net:443/certificates/noelsf20170519111723/7ab58176a0b24ba1b946c1ed2b1ce988
                SecretIdentifier : https://noelsf.vault.azure.net:443/secrets/noelsf20170519111723/7ab58176a0b24ba1b946c1ed2b1ce988
                Certificate: :
                    SubjectName : CN=noelsf.westus2.cloudapp.azure.com
                    IssuerName : CN=noelsf.westus2.cloudapp.azure.com
                    NotBefore : 5/19/2017 11:07:39 AM
                    NotAfter : 5/19/2018 11:17:39 AM
                CertificateThumbprint : 90B5BF8DBF7C3998274FF26F8694228BE0E9787B
                CertificateSavedLocalPath : C:\temp\noelsf\noelsf20170519111723.pfx

Deployment   : Name : AzurePSDeployment-0519111806
               Id : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourceGroups/noelsf/providers/Microsoft.Resources/deployments/AzurePSDeployment-0
               519111806
               CorrelationId : 63cd51d4-1857-4ed7-9dd1-bbb48750d868
               Mode : Incremental
               ProvisioningState : Succeeded
               Timestamp : 5/19/2017 6:25:27 PM

Cluster      : AvailableClusterVersions :
                   CodeVersion : 5.5.216.0
                   SupportExpiryUtc : 07/10/2017 00:00:00
                   Environment : Windows
                   CodeVersion : 5.5.219.0
                   SupportExpiryUtc : 07/10/2017 00:00:00
                   Environment : Windows
                   CodeVersion : 5.5.232.0
                   SupportExpiryUtc : 07/10/2017 00:00:00
                   Environment : Windows
                   CodeVersion : 5.6.205.9494
                   SupportExpiryUtc : 12/31/9999 23:59:59
                   Environment : Windows
               ClusterId : a2f37d6b-3989-4a3a-b728-14ee8ae8bcd3
               ClusterState : Deploying
               ClusterEndpoint : https://westus2.servicefabric.azure.com/runtime/clusters/a2f37d6b-3989-4a3a-b728-14ee8ae8bcd3
               ClusterCodeVersion : 5.5.216.0
                   Thumbprint : 90B5BF8DBF7C3998274FF26F8694228BE0E9787B
                   ThumbprintSecondary :
                   X509StoreName : My
               ReliabilityLevel : Silver
               UpgradeMode : Automatic
               ClientCertificateThumbprints :
               ClientCertificateCommonNames :
               FabricSettings :
                   Name : Security
                   Parameters :
                       Name : ClusterProtectionLevel
                       Value : EncryptAndSign
               ReverseProxyCertificate :
               ManagementEndpoint : https://noelsf.westus2.cloudapp.azure.com:19080
               NodeTypes :
                   Name : nt1vm
                   PlacementProperties :
                   Capacities :
                   ClientConnectionEndpointPort : 19000
                   HttpGatewayEndpointPort : 19080
                   DurabilityLevel : Bronze
                   ApplicationPorts : Microsoft.Azure.Management.ServiceFabric.Models.EndpointRangeDescription
                   EphemeralPorts : Microsoft.Azure.Management.ServiceFabric.Models.EndpointRangeDescription
                   IsPrimary : True
                   VmInstanceCount : 5
                   ReverseProxyEndpointPort :
               AzureActiveDirectory :
               ProvisioningState : Succeeded
               VmImage : Windows
                   StorageAccountName : ggfpuuhqvikpw2
                   ProtectedAccountKeyName : StorageAccountKey1
                   BlobEndpoint : https://ggfpuuhqvikpw2.blob.core.windows.net/
                   QueueEndpoint : https://ggfpuuhqvikpw2.queue.core.windows.net/
                   TableEndpoint : https://ggfpuuhqvikpw2.table.core.windows.net/
                   OverrideUserUpgradePolicy : False
                   ForceRestart : False
                   UpgradeReplicaSetCheckTimeout : 10675199.02:48:05.4775807
                   HealthCheckWaitDuration : 00:05:00
                   HealthCheckStableDuration : 00:05:00
                   HealthCheckRetryTimeout : 00:45:00
                   UpgradeTimeout : 12:00:00
                   UpgradeDomainTimeout : 02:00:00
                   HealthPolicy : Microsoft.Azure.Management.ServiceFabric.Models.ClusterHealthPolicy
                   DeltaHealthPolicy : Microsoft.Azure.Management.ServiceFabric.Models.ClusterUpgradeDeltaHealthPolicy
               Id : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourcegroups/noelsf/providers/Microsoft.ServiceFabric/clusters/noelsf
               Name : noelsf
               Type : Microsoft.ServiceFabric/clusters
               Location : westus2
               Tags :
                   resourceType : Service Fabric
                   clusterName : noelsf
```

## Warning on loopback networking
https://blog.sixeyed.com/published-ports-on-windows-containers-dont-do-loopback/

## Problem with Windows NAT DNS

Things I tried:

* Works with docker build!
* Doesn't work with docker compose (or docker run with intermediate image)
* Doesn't work with docker build anymore
* Intermediate image works with --dns=8.8.8.8
* Set daemon.json `{ dns: ["8.8.8.8", "8.8.4.4" ]}`

## Problems & Fix for Host Network Service (HNS)

Tried
```powershell
sc.exe config hns type=own
restart-service hns
```
Goofed around with `get-netnat | remove-netnat` and `get-netnatstaticmapping | remove-netnatstaticmapping`

But then I hit `hns failed with error: the object already exists`

Reset from Windows -> Linux containers & back again
Reset Docker

Tried adding `{ "bridge": "none" }` to daemon.json. Started containers, but they had no net access to run `npm install`

What finally got me back on track:

* Removed DNS & bridge updates to daemon.json
* Found [this GitHub issue](https://github.com/docker/for-win/issues/750)
* [This script](https://github.com/Microsoft/Virtualization-Documentation/tree/master/windows-server-container-tools/CleanupContainerHostNetworking) might also be useful

```powershell
stop-service HNS
del C:\ProgramData\Microsoft\Windows\HNS\HNS.data
start-service HNS
```

# Linux Containers
```powershell
New-AzureRmResourceGroup -Name noelsflinux -Location westus2
$password = ConvertTo-SecureString "Password!1234" -AsPlainText -Force
New-AzureRmServiceFabricCluster -ResourceGroupName noelsflinux -CertificateOutputFolder C:\temp\noelsflinux -CertificatePassword $password -OS UbuntuServer1604 -VmPassword $password -Location westus2
Import-PfxCertificate -FilePath C:\temp\noelsflinux\noelsflinux20170519111954.pfx -Password $password
 -CertStoreLocation Cert:\CurrentUser\My -Exportable
```

## Output
```
VmUserName   : adminuser
Certificates : Primary key vault and certificate detail:
                KeyVaultId : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourceGroups/noelsflinux/provider
               s/Microsoft.KeyVault/vaults/noelsflinux
                KeyVaultName : noelsflinux
                KeyVaultCertificateId : https://noelsflinux.vault.azure.net:443/certificates/noelsflinux201705191119
               54/d33c8ed03aef4effacfcd0094420873e
                SecretIdentifier : https://noelsflinux.vault.azure.net:443/secrets/noelsflinux20170519111954/d33c8ed
               03aef4effacfcd0094420873e
                Certificate: :
                    SubjectName : CN=noelsflinux.westus2.cloudapp.azure.com
                    IssuerName : CN=noelsflinux.westus2.cloudapp.azure.com
                    NotBefore : 5/19/2017 11:10:12 AM
                    NotAfter : 5/19/2018 11:20:12 AM
                CertificateThumbprint : 82B2799000C202E040BEEAC0C83EB89EF100411F
                CertificateSavedLocalPath : C:\temp\noelsflinux\noelsflinux20170519111954.pfx

Deployment   : Name : AzurePSDeployment-0519112037
               Id : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourceGroups/noelsflinux/providers/Microso
               ft.Resources/deployments/AzurePSDeployment-0519112037
               CorrelationId : 7ccd6233-2847-45f3-b6da-ec3b1623f779
               Mode : Incremental
               ProvisioningState : Succeeded
               Timestamp : 5/19/2017 6:24:12 PM

Cluster      : AvailableClusterVersions :
                   CodeVersion : 5.5.0.2
                   SupportExpiryUtc : 12/31/9999 23:59:59
                   Environment : Linux
               ClusterId : a7ed719b-c9ab-454c-a03e-525b71330c9c
               ClusterState : WaitingForNodes
               ClusterEndpoint :
               https://westus2.servicefabric.azure.com/runtime/clusters/a7ed719b-c9ab-454c-a03e-525b71330c9c
               ClusterCodeVersion : 5.5.0.2
                   Thumbprint : 82B2799000C202E040BEEAC0C83EB89EF100411F
                   ThumbprintSecondary :
                   X509StoreName : My
               ReliabilityLevel : Silver
               UpgradeMode : Automatic
               ClientCertificateThumbprints :
               ClientCertificateCommonNames :
               FabricSettings :
                   Name : Security
                   Parameters :
                       Name : ClusterProtectionLevel
                       Value : EncryptAndSign
               ReverseProxyCertificate :
               ManagementEndpoint : https://noelsflinux.westus2.cloudapp.azure.com:19080
               NodeTypes :
                   Name : nt1vm
                   PlacementProperties :
                   Capacities :
                   ClientConnectionEndpointPort : 19000
                   HttpGatewayEndpointPort : 19080
                   DurabilityLevel : Bronze
                   ApplicationPorts : Microsoft.Azure.Management.ServiceFabric.Models.EndpointRangeDescription
                   EphemeralPorts : Microsoft.Azure.Management.ServiceFabric.Models.EndpointRangeDescription
                   IsPrimary : True
                   VmInstanceCount : 5
                   ReverseProxyEndpointPort :
               AzureActiveDirectory :
               ProvisioningState : Succeeded
               VmImage : Linux
                   StorageAccountName : f53pvmir73g6o2
                   ProtectedAccountKeyName : StorageAccountKey1
                   BlobEndpoint : https://f53pvmir73g6o2.blob.core.windows.net/
                   QueueEndpoint : https://f53pvmir73g6o2.queue.core.windows.net/
                   TableEndpoint : https://f53pvmir73g6o2.table.core.windows.net/
                   OverrideUserUpgradePolicy : False
                   ForceRestart : False
                   UpgradeReplicaSetCheckTimeout : 10675199.02:48:05.4775807
                   HealthCheckWaitDuration : 00:05:00
                   HealthCheckStableDuration : 00:05:00
                   HealthCheckRetryTimeout : 00:45:00
                   UpgradeTimeout : 12:00:00
                   UpgradeDomainTimeout : 02:00:00
                   HealthPolicy : Microsoft.Azure.Management.ServiceFabric.Models.ClusterHealthPolicy
                   DeltaHealthPolicy :
               Microsoft.Azure.Management.ServiceFabric.Models.ClusterUpgradeDeltaHealthPolicy
               Id : /subscriptions/6c1f4f3b-f65f-4667-8f9e-b9c48e09cd6b/resourcegroups/noelsflinux/providers/Microso
               ft.ServiceFabric/clusters/noelsflinux
               Name : noelsflinux
               Type : Microsoft.ServiceFabric/clusters
               Location : westus2
               Tags :
                   resourceType : Service Fabric
                   clusterName : noelsflinux
```


# Resources

* [Service Fabric Containers Overview](https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-containers-overview)
* [Service Fabric .NET Containers (Windows)](https://github.com/Azure-Samples/service-fabric-dotnet-containers)