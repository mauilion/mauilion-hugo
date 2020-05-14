---
title: "Accessing Local Data from inside Kind!"
date: 2020-05-12T21:09:00-07:00
draft: false
toc: true
asciinema: true
images:
- https://images.unsplash.com/photo-1511285095685-c5c53c7e8c60
tags: 
  - kind
  - kubernetes
  - storage
  - datapool
  - PVc
---

Following on from the [recent kind PVc](../kind-PVc) post. In this post we
will explore how to bring up a kind cluster and use it to access data that you
have locally on your machine via Persistent Volume Claims.
<!--more-->
This gives us the ability to model pretty interesting deployments of
applications that require access to a data pool!

Let's get to it!

## Summary
For this article I am going to use a txt file of a book and we can do some
simple word counting. 

For our book we are going to use [The Project Gutenberg EBook of Pride and
Prejudice, by Jane Austen](https://www.gutenberg.org/files/1342/1342-0.txt)

We are going to create a multi node kind cluster and access that txt file from pods
running in our cluster!

Let's make a directory locally that we will use to store our data

``` bash
$ mkdir -p data/pride-and-prejudice
$ cd data/pride-and-prejudice/
$ curl -LO https://www.gutenberg.org/files/1342/1342-0.txt
$ wc -w 1342-0.txt
124707 data/pride-and-prejudice/1342-0.txt
```

Now for a kind config that mounts our data into our worker nodes!

`kind-data.yaml`
``` yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role:  worker
  extraMounts:
  - hostPath: ./data
    containerPath: /tmp/data
- role:  worker
  extraMounts:
  - hostPath: ./data
    containerPath: /tmp/data
```

Let's bring up the cluster!

{{< asciinema key="kind-pvc-localdata-up" rows="35" preload="1" >}}

### Access Models
There are a couple of different ways we can provide access to this data! In
Kubernetes we have the ability to configure the pod with access to `hostPath`
``` bash
$ kubectl explain pod.spec.volumes.hostpath
KIND:     Pod
VERSION:  v1

RESOURCE: hostPath <Object>

DESCRIPTION:
     HostPath represents a pre-existing file or directory on the host machine
     that is directly exposed to the container. This is generally used for
     system agents or other privileged things that are allowed to see the host
     machine. Most containers will NOT need this. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath

     Represents a host path mapped into a pod. Host path volumes do not support
     ownership management or SELinux relabeling.

FIELDS:
   path	<string> -required-
     Path of the directory on the host. If the path is a symlink, it will follow
     the link to the real path. More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath

   type	<string>
     Type for HostPath Volume Defaults to "" More info:
     https://kubernetes.io/docs/concepts/storage/volumes#hostpath
```

For LOTS of good reasons this pattern is not a good one. Allowing `hostPath` as
a volume for pods amounts to giving complete access to the underlying node. 

A malicious or curious user of the cluster could mount the /var/run/docker.sock
into their pod and have the ability to completely take over the underlying node.
Since most nodes host workloads from many different applications this can
compromise the security of your cluster pretty significantly!

All that said we will demonstrate how this works.

The other model is to provide access to the underlying `hostPath` as a defined
persistent volume. This is better move because the person defining the PV has to
have the ability to define the PV at the cluster level and requires elevated
permissions. 

Quick reminder here that persistent volumes are defined at cluster scope but
persistent volume claims are namespaced! 

If you are ever wondering what resources are namespaced and what aren't check
this out!

{{< asciinema key="kubectl-api-resources" rows="35" preload="1" >}}

So TL;DR do this with Persistent Volumes not with hostPath!

#### The Setup!
I assume that you have already setup [kind](https://kind.sigs.k8s.io) and all
that comes with that.

I've made all the resources used in the following demonstrations available
[here](https://gist.github.com/mauilion/c40b161822598e5b1720d3b34487fb82)

You can fetch them with
```bash 
git clone https://gist.github.com/mauilion/c40b161822598e5b1720d3b34487fb82
PVc-books
```
And follow along!

{{< asciinema key="kind-pvc-localdata-git" rows="35" preload="1" >}}

#### hostPath
In this demo we will:
* configure a deployment to use hostPath
* bring up a pod and play with the data!
* show why hostpath is crazy town!
* cleanup

{{< asciinema key="kind-pvc-localdata-hostpath" rows="35" preload="1" >}}

#### Persistent Volumes
In this demo we will: 
* define a Persistent Volume
* configure a deployment and a persistent volume claim
* bring up the deployment and play with the data!
* cleanup

{{< asciinema key="kind-pvc-localdata-PVc" rows="35" preload="1" >}}

#### Persistent Volume Tricks!
Ever wondered how to ensure that a specific Persistent Volume will connect to a
specific Persistent Volume Claim? 

One of the most foolproof ways is to populate the claimRef with information that
indicates where the PVC will be created. 

We do this in our example pv.yaml

{{< gist mauilion c40b161822598e5b1720d3b34487fb82 "pv.yaml" >}}

This way if you have multiple PVs you are "restoring" or "loading into a
cluster" you can have some control over which PVC will attach to which PV. 

Thanks!


### In Closing

Giving a consumer hostpath access via Persistent Volume is very much a more sane way to provide
that access! 
* They can't arbitrarily change the path to something else. 
* Only someone with cluster level permission can define a Persistent Volume

Thanks for checking this out! I hope that it was helpful. If you have questions
or ideas about something you'd like to see a post on hit me up on twitter!



