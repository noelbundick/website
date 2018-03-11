---
title: Cross-compiling Kubernetes on Windows Subsystem for Linux
tags:
  - kubernetes
  - wsl
date: 2018-03-10
---

Over the last year, I've gone from Linux n00b to a growing level of competence. In large part, this is thanks to Windows Subsystem for Linux, where I could learn and take advantage of command line tooling without being completely lost in an unfamiliar ecosystem. It also gave me an easy way to [exit vim](https://www.commitstrip.com/en/2017/05/29/trapped/)!

That said, I'm always interested to push the limits on things. After Brian Ketelsen's [recent post about WSL metadata](https://brianketelsen.com/going-overboard-with-wsl-metadata/), and some [good conversation on Twitter](https://twitter.com/bketelsen/status/972274864127168512), I was reminded that I had cross-compiled Kubernetes for Windows under WSL a while back, and had never shared how to repeat this feat of nerdery for others.

# Setting up WSL

First up, you'll need the [Go programming language](https://golang.org/doc/install). I've got mine installed in the default location at `/usr/local/go`. I'm also using a common path for both Linux and Windows, so I've got my `GOPATH` environment variable pointed to the C: drive

```bash
# Optional: use a common directory for Windows & Linux
export GOPATH=/mnt/c/code/go

curl -LO https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.9.3.linux-amd64.tar.gz
```

Note: Kubernetes supports specific versions of Go. If you've already upgraded to 1.10, downloading a supported version and making sure it's the active one in your `PATH` temporarily works great too!

> You can check your version with `go version` and which executable is active with `which go`

## Windows Defender

A quick note on Windows Defender before I continue - WSL is still working to catch up to native Linux installs on file I/O speed, but the built-in antivirus doesn't make matters any better. I've made the decision to accept the risk and exclude my WSL and code folders from scanning, which seems to help. YMMV

{{% img "windows-defender.png" "Excluding paths from Windows Defender" %}}

# Getting Kubernetes

Getting started with Kubernetes is easy! I followed the first part of the instructions on the [main Kubernetes repository](https://github.com/kubernetes/kubernetes/blob/master/README.md#to-start-developing-kubernetes) on GitHub.

```bash
go get -d k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
```

For me, that pulls everything down into `/mnt/c/code/go/src/k8s.io/kubernetes`, which is really mapped to `C:\code\go\k8s.io\kubernetes`. Neat!

{{% img "mapped-files.png" "Linux files mapped to an NTFS path" %}}

# Building Kubernetes

Even though I first did this back in November, I'm just getting started building & working with the Kubernetes codebase - especially on Windows. So don't look to the snippet below as authoritative or best instructions, but they work for me!

```bash
# Build for Linux first to generate some needed files
make WHAT=cmd/kubelet KUBE_BUILD_PLATFORMS=linux/amd64

# Build kubelet and kube-proxy!
make WHAT=cmd/kubelet KUBE_BUILD_PLATFORMS=windows/amd64
make WHAT=cmd/kube-proxy KUBE_BUILD_PLATFORMS=windows/amd64
```

The commands will drop a `kubelet.exe` and a `kube-proxy.exe` in `C:\code\go\src\k8s.io\kubernetes\_output\local\bin\windows\amd64`. I'm ready to take these files, and run them locally, or upload them to a VM to do some real-world testing.

# Summary

{{% img "rainbow-cat.jpg" "Rainbow cat!" %}}

Awesome! I've just used a Linux installation of Go, running under Windows Subsystem for Linux, to compile a big-time real-world app for another operating system. Sure, it might not be the Kubernetes community's first choice for toolchain, but it shows that WSL is a legit tool, and not just for toy apps or neat demos. WSL can and does support real engineering work, and things are only getting better and better. Keep an eye on the [WSL team blog](https://blogs.msdn.microsoft.com/wsl/) for more updates!