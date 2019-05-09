---
title: "Using Kind to test a pr for Kubernetes."
date: 2019-05-08T09:37:30-07:00
toc: true
asciinema: true
images:
  - https://avatars1.githubusercontent.com/u/36015203
tags:
  - local
  - kubernetes
  - testing
  - kind
---
## Setup

I am looking to validate a set of changes produced by this PR.

https://github.com/kubernetes/kubernetes/pull/77523

In this post I want to show a few things.

1. setup a go environment.
1. build kind
1. checkout the k8s.io/kubernetes source
1. bring up a cluster to repoduce the issue.
1. build an image based on Andrews changes
1. bring up a cluster with that image
1. validate that the changes have the desired affect.

### Prerequisites

There is a pretty handy tool called `gimme` put out by the travis-ci folks.

This in my opinion is the "best" way to setup a go environment.

Read more about it [here](https://github.com/travis-ci/gimme)

For this setup I am going to leverage [direnv](https://direnv.net/) to configure go.

We need a system that has [gimme](https://github.com/travis-ci/gimme#installation--usage) and [direnv](https://direnv.net/) installed.

I will refer you to the instructions in the above links to get this stuff setup in your environment :)

### Let's get started with go!

For this next bit I have created a repo you can checkout and make use of.

{{< asciinema key="k8dev-go" >}}

In the cast you can see us checking out [mauilion/k8s-dev](https://github.com/mauilion/k8s-dev)
Then we move into the directory and use gimme to configure go via direnv.


We then edit the `.envrc` file.

I want to take a second to explain why.

```bash
unset GOOS;
unset GOARCH;
unset GOPATH;
export GOPATH=${PWD}
export GOROOT='/home/dcooley/.gimme/versions/go1.12.5.linux.amd64';
export PATH="${GOPATH}/bin:/home/dcooley/.gimme/versions/go1.12.5.linux.amd64/bin:${PATH}";
go version >&2;

export GIMME_ENV='/home/dcooley/.gimme/envs/go1.12.5.linux.amd64.env';

```
I added the `GOPATH` variable to ensure that when invoked go considers `/home/dcooley/k8s-dev` the path for go. This is how we can be sure that things like `go get -d k8s.io/kubernetes sigs.k8s.io/kind` will pull the src into that directory.
This is also important as when `kind` "discovers" the location of your checkout of `k8s.io/kubernetes` as part of the `kind build node-image` step it will follow the defined `GOPATH`.

I am also prepending `${GOPATH}/bin` to the `${PATH}` variable. So that when we build `kind`. The `kind` binary will be in our path. You can also just put `kind` i

### Let's build our kind node-images

Ok next up we need to build our images.

Since we checked out `k8s.io/kubernetes` into `${GOPATH}/src/k8s.io/kubernetes` we can just run `kind build node-image --image=mauilion/node:master`

This will create an image in my local docker image cache named `mauilion/node:master`

Once complete we also have to build the image based on the PR that Andrew provided.

In the ticket we can see src of Andrews PR. `andrewsykim:fix-xlb-from-local`

So we need to grab that branch and build another image.

The way I do this so as not to mess up the import paths and such is to move into `${GOPATH}/src/k8s.io/kubernetes` and run `git remote add andrewsykim git@github.com:andrewsykim\kubernetes`

Since Andrew is pushing his code to a branch `fix-xlb-from-local` of his fork `git@github.com:andrewsykim/kubernetes` of `k8s.io/kubernetes`

Once the remote is added I can do a `git fetch --all` and that will pull down all the known branches from all the remotes.

Then we can switch to Andrews branch and build a new `kind node-image`

{{< asciinema key="k8dev-build" >}}


Before we move on. Let's talk about what's happening when we run `kind build node-image --image=mauilion/node:77523`

`kind` is setup to build this image using a container build of kubernetes. This means that `kind` will "detect" where your local checkout of `k8s.io/kubernetes` is via your `${GOPATH}` then mount that into a container and build all the bits.

the node image will contain all binaries and images needed to run kubernetes as produced from your local checkout of the source.

This is a PRETTY DARN COOL thing!

This means that I can easily setup an environment that will allow me to dig into and validate particular behavior.

Also this is a way to iterate over changes to the codebase.

Alright let's move on.

### Let's bring up our clusters

In the repo I've the following directory structure:
```bash
kind/
├── 77523              # a repo with the bits for the 77523 clusters
│   ├── .envrc         # this .envrc will enable direnv to export our kubeconfig for this cluster when we move into this dir.
│   ├── config         # the kind config for this cluster. Basically 1 control plane node and 2 worker nodes
│   ├── km-config.yaml # the metallb configuration for vip addresses
│   └── test.yaml      # the test.yaml has our statically defined pods and service so that we can test.
└── master
    ├── .envrc
    ├── config
    ├── km-config.yaml
    └── test.yaml
```

In the cast below you can see that we are moving into the directory for each cluster. If you take a look at the .envrc in the directory you can see we are using direnv to export `KUBECONFIG` and configure `kubectl`. This is also where the resources for this cluster are defined.
We then run something like:
```
kind create cluster --config config --name=master --image=mauilion/node:master
```
This does a few things.
* It creates a cluster where the nodes will follow a naming convention we use in our statically defined test.yaml
* It will use the node-image that we created in the `build` step.
* It will use the config defined and create a cluster of 1 control plane node and 2 worker nodes.

{{< asciinema key="k8dev-cluster-up" >}}


### Now for the fun bit. Let's validate

This PR is setup to fix a behavior in the way that `externalTrafficPolicy: Local` works.

#### The problem:
If we bringup a pod on one of two workers and expose that pod with a service of type LoadBalancer.
And that service is configured with `externalTrafficPolicy: Local`.
A pod that is configured with `hostNetwork: True` on the node where the pod is not will fail to connect to the external lb ip. That traffic will be dropped.

#### The fix:
To fix this behavior Andrew has implemented a another iptables rule.
```
-A KUBE-XLB-ECF5TUORC5E2ZCRD -s 10.8.0.0/14 -m comment --comment "Redirect pods trying to reach external loadbalancer VIP to clusterIP" -j KUBE-SVC-ECF5TUORC5E2ZCRD
```
This change enables traffic for a svc from a pod or from the host to be redirected to the service defined by kube-proxy.

#### Our testing setup:
We have brought up 2 clusters:
* master
* 77523

Into each of them we have deployed our test.yaml and metallb and a config for metallb.

The test.yaml is a set of pods that are statically defined.
By that I mean that each pod is scheduled to a specific node. We do this by configuring `nodeName` in the pod spec.

There are 5 pods that we are deploying.
`echo-77523-worker2`
`netshoot-77523-worker`
`netshoot-77523-worker2`
`overlay-77523-worker`
`overlay-77523-worker2`

The echo pod is using [inanimate/echo-server](https://github.com/InAnimaTe/echo-server) and from the name you can see that this will be deployed on worker2.

The netshoot pods are set with `hostNetwork: True` This means that if you exec into the pod you can see the ip stack of the underlying node.

The overlay pods are the same except they are deployed as part of the overlay network and will be given a `pod ip`

The netshoot and overlay pods are both using [nicolaka/netshoot](https://github.com/nicolaka/netshoot)

We also define a svc of type LoadBalancer in each of our clusters.

for our `master` cluster we use `172.17.255.1:8080` and on the `77523` cluster it's `172.17.254.1:8080`

I am using metallb for this you can read more about metallb [here](https://metallb.universe.tf/). More about how I use it with kind [here](https://mauilion.dev/posts/kind-metallb/)

#### Let's test it!

From our understanding of the problem I expect that if exec into the `netshoot-master-worker` pod I will not be able to `curl 172.17.255.1:8080`
{{< asciinema key="k8dev-master" >}}



if we try from the `77523` cluster we can see that it does work!
{{< asciinema key="k8dev-77523" >}}

Why does it work now tho?

{{< asciinema key="k8dev-why" >}}

In the master cluster we can chase down the XLB entry and it looks like this:
```
:KUBE-XLB-U52O5CQH2XXNVZ54 - [0:0]
-A KUBE-FW-U52O5CQH2XXNVZ54 -m comment --comment "default/echo: loadbalancer IP" -j KUBE-XLB-U52O5CQH2XXNVZ54
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/echo:" -m tcp --dport 30012 -j KUBE-XLB-U52O5CQH2XXNVZ54
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "default/echo: has no local endpoints" -j KUBE-MARK-DROP

```

in the 77523 cluster:
```
:KUBE-XLB-U52O5CQH2XXNVZ54 - [0:0]
-A KUBE-FW-U52O5CQH2XXNVZ54 -m comment --comment "default/echo: loadbalancer IP" -j KUBE-XLB-U52O5CQH2XXNVZ54
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/echo:" -m tcp --dport 31972 -j KUBE-XLB-U52O5CQH2XXNVZ54
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "masquerade LOCAL traffic for default/echo: LB IP" -m addrtype --src-type LOCAL -j KUBE-MARK-MASQ
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "route LOCAL traffic for default/echo: LB IP to service chain" -m addrtype --src-type LOCAL -j KUBE-SVC-U52O5CQH2XXNVZ54
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "default/echo: has no local endpoints" -j KUBE-MARK-DROP
```

The rules that Andrew's patch adds are:

```
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "masquerade LOCAL traffic for default/echo: LB IP" -m addrtype --src-type LOCAL -j KUBE-MARK-MASQ
-A KUBE-XLB-U52O5CQH2XXNVZ54 -m comment --comment "route LOCAL traffic for default/echo: LB IP to service chain" -m addrtype --src-type LOCAL -j KUBE-SVC-U52O5CQH2XXNVZ54
```
And the comments make it pretty clear what's happening!

### Wrap up!

Let's make sure you wipe out those clusters.

```
kind delete cluster --name=master
kind delete cluster --name=77523
```

Also consider running `docker system prune --all` and `docker volume prune` every so often to keep your dockers cache tidy :)



shout-out to [@a_sykim](https://twitter.com/a_sykim) you should follow him on twitter he's great!

Thanks!
