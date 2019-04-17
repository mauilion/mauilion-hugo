---
title: "Using MetalLb with Kind"
date: 2019-04-17T10:44:33-07:00
draft: false
toc: true
asciinema: true
images:
  - https://github.com/danderson/metallb/blob/master/website/static/images/logo.png
tags:
  - metallb
  - kind
  - tutorial
---

### Preamble:

When using metallb with king we are going to deploy it in `l2-mode` This means that we need to be able to connect to the ip addresses of the node subnet.
If you are using kind on Mac or Windows this will require you to add a route to your laptop routing the subnet used by your kind cluster to the vm that is hosting it.
If you are using linux to host a kind cluster. You will not need to do this as the kind node ip addresses are directly attached.

### Problem Statement:

Kubernetes on bare metal doesn't come with an easy integration for things like services of type LoadBalancer.

This mechanism is used to expose services inside the cluster using an external Load Balancing mechansim that understands how to route traffic down to the pods defined by that service.

Most implementations of this are relatively naive. They place all of the available nodes behing the load balancer and use tcp port knocking to determine if the node is "healthy" enough to forward traffic to it.

With Metallb there are a different set of assumptions.

Metallb can operate in two distinct modes.

A Layer 2 mode that will use vrrp to arp out for the external ip or VIP on the lan.

A bgp mode that will announce the external ip or VIP from all of the nodes where at least one pod is running.

the bgp mode relies on ecmp to balance traffic back to the pods. ECMP is a great solution for this problem and I HIGHLY recommend you use this model if you can.

That said I haven't created a bgp router for my kind cluster so we wil use the l2-mode for this experiment.

First let's create a service of type loadbalancer and see what happens before we install metallb.

I am going to use the echo server for this. I prefer the one built by inanimate. Here is the [source](https://github.com/InAnimaTe/echo-server) and image: `inanimate/echo-server`

{{< asciinema key="km-echo1" rows="30" preload="1" >}}

We can see that the `EXTERNAL-IP` field is `pending`. This is because there is nothing available in the cluster to manage this type of service.

### Let's do this thing!

First let's bring up a 2 node kind cluster with the following config.

``` yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
```

{{< asciinema key="km-bringup" rows="30" preload="1" >}}

Then we need to see if we can ping the node ip of the nodes themselves.


{{< asciinema key="km-ping" rows="30" preload="1" >}}

At this point we need to determine the network that is being used for the node ip pool. Since kind nodes are associated with the docker network named "bridge" we can inspect that directly. 

I am using a pretty neat tool called [`jid`](https://github.com/simeji/jid) here that is a repl for json.

{{< asciinema key="km-inspect" rows="30" preload="1" >}}

So we can see that there is an allocated network of `172.17.0.0/16` in my case.

Let's swipe the last 10 ip addresses from that allocation and use them for the metallb configuration.

### Now on to the metallb part!

First read the docs https://metallb.universe.tf/installation/

Then we can get started on installing this to our cluster.

{{< asciinema key="km-metallb-install" rows="30" preload="1" >}}

We can see that metallb is now installed but we aren't done yet!

now we need to add a configuration that will use a few of the unused ip addresses from the node ip pool (`172.17.0.0/16`)

Now if we look at our existing service we can see that the `EXTERNAL-IP` is still `pending`

This is because we haven't yet applied the config for metallb.

Here is the config:

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.17.255.1-172.17.255.250
```
You can apply this to your cluster with `kubectl apply -f https://git.io/km-config.yaml`

Let's see what happens when we apply this.

{{< asciinema key="km-config" rows="28" preload="1" >}}

We can see the svc get's an ip address immediatly.

And we can curl it!

That's all for now hit me up on [twitter](https://twitter.com/mauilion) or [k8s slack](https://kubernetes.slack.com/team/U37TLLWAU) with questions!

Shout-out to Jan Guth for the idea on this post!

