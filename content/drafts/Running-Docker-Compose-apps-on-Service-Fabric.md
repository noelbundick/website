---
title: Running Docker Compose apps on Service Fabric
tags:
  - azure
  - docker
  - service fabric
---

* Setting up a cluster with preview bits
* Preview tooling
* What's supported & what's not
* Quirks (volumes are case sensitive)
* Volume mounts to VMSS
  * Map to Azure File share mounted on host - allows node independence at the cost of latency
* Warnings
* Working example / try it now