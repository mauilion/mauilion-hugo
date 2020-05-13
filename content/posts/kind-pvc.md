---
title: "Kind Persistent Volumes"
date: 2020-05-10T14:50:57-07:00
draft: false
toc: true
asciinema: true
images:
- https://images.unsplash.com/photo-1547815749-838c83787de2
tags: 
  - kind
  - storage
  - pvc
  - kubernetes
---

Hey Frens! This week we are exploring portable persistent volumes in kind!
This is a pretty neat and funky trick!
<!--more-->

## Introduction

This article is going to explore three different ways to expose [persistent
volumes](docs.k8s.io/concepts/storage/persistent-volumes) with
[kind](sigs.k8s.io/kind)

### Use Cases

Assuming we are using a local kind cluster.

  1. default storage class:
       I want there to be a built in storage class so that I can deploy
     applications that request persistent volume claims.

  1. pod restart:
       If my pod restarts I want that pod to be scheduled such that the persistent
     volume claim is available to my pod. This ensures that if I have to restart
     and my pod will always come back with access to the same data.

  1. volume mobility: 
       I want to be able to schedule my pod to multiple nodes and have it access
     the same persistent volume claim. This requires that the peristent volume
     be made available to all nodes.

  1. local data:
       I have a bunch of data locally that I want to expose to pods running in a
     kind cluster.

  1. restore volumes:
       I want to be able to bring up a kind cluster and regain access to a
     previously provisioned persistent volume claim.


### The built in storage provider

KinD makes use of Ranchers [local path persistent storage solution](https://github.com/rancher/local-path-provisioner).

With this provider we can solve for the first two use cases: default storage class and pod restart.

This solution is registered as the default storageclass on your kind cluster.
You can see this by looking at: 
``` bash
kubectl get storageclass
```

This solution relies on a deployment of some resources in the
`local-path-storage` namespace.


Now the way this storage solution works. When a pvc is created the persistent
volume will be dynamically created on the node that the pod is scheduled to. As part of the provisioning the persistent volume has the following appended to it. 
``` go
Spec: v1.PersistentVolumeSpec{
	PersistentVolumeReclaimPolicy: *opts.StorageClass.ReclaimPolicy,
	AccessModes:                   pvc.Spec.AccessModes,
	VolumeMode:                    &fs,
	Capacity: v1.ResourceList{
		v1.ResourceName(v1.ResourceStorage): pvc.Spec.Resources.Requests[v1.ResourceName(v1.ResourceStorage)],
	},
	PersistentVolumeSource: v1.PersistentVolumeSource{
		HostPath: &v1.HostPathVolumeSource{
			Path: path,
			Type: &hostPathType,
		},
	},
	NodeAffinity: &v1.VolumeNodeAffinity{
		Required: &v1.NodeSelector{
			NodeSelectorTerms: []v1.NodeSelectorTerm{
				{
					MatchExpressions: []v1.NodeSelectorRequirement{
						{
							Key:      KeyNode,
							Operator: v1.NodeSelectorOpIn,
							Values: []string{
								node.Name,
							},
						},
					},
				},
			},
		},
	},
},
```
[source](https://github.com/rancher/local-path-provisioner/blob/master/provisioner.go#L205-L238)

This means that in the case of pod failure or restart the pod will only be
scheduled to the node where the persistent volume was allocated. If that node is
not available then the pod will not schedule. 

For most use cases in Kind this solution will work great!

Let's take a look at how this works in practice. 

In this demonstration we will:
* create a multi node kind cluster
* schedule a pod with a pvc
* evict the pod from the node it was scheduled to
* see if the pod is rescheduled.
* allow the pod to be scheduled on the original node.

{{< asciinema key="kind-pvc-default" rows="35" preload="1" >}}

#### What about "restore volumes" use case?

To support restoring volumes from previous kind cluster we need to do a couple
of things. We need to mount the directory that the storage provider will use to
create persistent volumes so that we have the data to restore. We also need to
backup the persistent volume resources so that we can reuse them on restart! 

The local-path-provisioner is configured via a `configmap` in the local-path-storage namespace. It looks looks like this!

``` yaml
$ kubectl describe configmaps -n local-path-storage local-path-config 

Name:         local-path-config
Namespace:    local-path-storage
Labels:       <none>
Annotations:  
Data
====
config.json:
----
{
        "nodePathMap":[
        {
                "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                "paths":["/var/local-path-provisioner"]
        }
        ]
}
Events:  <none>

```
This configuration means that on each node in the cluster the provisioner will
use the /var/local-path-provisioner directory to provision new persistent
volumes!

Let's check that out.

In this demonstration we will:
* bring up a multi node kind cluster with /var/local-path-provisioner mounted from the host
* apply our sample pvc-test.yaml and create a deployment and pvc.
* show that the persistent volume is in our shared directory
* backup the persistent volume configuration
* modify the persistent volume configuration
* delete and recreate the kind cluster
* restore the persistent volume configuration
* redeploy the app and the pvc and show that the data has been restored.

{{< asciinema key="kind-pvc-default-persist" rows="35" preload="1" >}}

The important bit there is that we needed to modify the old persistent volume
manifest to change the retention policy to Retain or when we apply it. It will
be immediately deleted. 

We also kept the claim and node affinity information in the manifest. 

One of the things we have not addressed is making sure the workload detaches
from the storage before deleting the cluster! in some cases your data might be
corrupted if you didn't safely shut the app down before deleting the cluster! 

### Use Case "Volume Mobility"
For this we are going to use a different storage provider! Our intent is to
still provide dynamic creation of pvcs but not to configure the pvcs with node
affinity. 

Fortunately there is an example implementation in the sigs.k8s.io repo!
You can check it out
[here](https://github.com/kubernetes-sigs/sig-storage-lib-external-provisioner)

For us to use this we need to build it and host it somewhere our kind cluster
can access it. We also need a manifest that will deploy and configure it.

I've already built and pushed the container to
[mauilion/hostpath-provisioner:dev](https://hub.docker.com/layers/mauilion/hostpath-provisioner/dev/images/sha256-cdab86923c5a3d5e389818d7c192ed4488f3d7a272c892432378d53b900c8dee)

The manifest I built for this example is below

{{ gist mauilion 1b5727f42d181f36bb934656fa50459a "hostpath.yaml" }}

Now to use this we are going to modify our kind cluster to override the shared
mount and the "default storageClass" implementation that kind deploys. 

Here is a look at our new kind config

{{ gist mauilion 1b5727f42d181f36bb934656fa50459a "kind-hostpath-dynamic.yaml"
}}

Note that the mount path has changed and we are overriding the
"/kind/manifests/default-storage.yaml" file on the first control-plane node. We
are doing that because by default kind will apply that manifest to configure
storage for the cluster. 

Let's see if it works!

We will:
* fetch our kind-pvc-hostpath.yaml
* bring up a multi node cluster with shared storage
* deploy our example deployment and pvc with git.io/pvc-test.yaml
* populate some data in the pvc.
* Then we will drain the node and see the pod created on a different node.
* show the pod rescheduled and that the data is still accessible
* backup and modify the persistent volume
* recreate the kind cluster
* show that we can restore the persistent volume

{{< asciinema key="kind-pvc-hostpath" rows="35" preload="1" >}}

### Resources
I am using kind version v0.8.1
```
$ kind version
kind v0.8.1 go1.14.2 linux/amd64
```

I've made a simple deployment and pvc to play with. It's available at
git.io/pvc-test.yaml.

{{< gist mauilion 1b5727f42d181f36bb934656fa50459a "pvc-test.yaml" >}}

All of the other resources including the kind configurations can be found
[here](https://gist.github.com/mauilion/1b5727f42d181f36bb934656fa50459a)

A quick way to set things up is to use git to check them all out! 

``` bash
git clone https://gist.github.com/mauilion/1b5727f42d181f36bb934656fa50459a  pvc
```


