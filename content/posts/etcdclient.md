---
title: "A manifest that can be used to interact with etcd on kubeadm clusters"
date: 2019-03-18T16:25:23-07:00
toc: false
tags:
  - etcd
asciinema: true
---

In this post I am going to discuss [git.io/etcdclient.yaml](https://git.io/etcdclient.yaml) and why it's neat!
<!--more-->

When putting together content for a series of blog posts that I am doing around etcd recovery and failure scenarios, I realized that I was configuring the etcdclient to interact with the etcd cluster that kubeadm stands up. 

[git.io/etcdclient.yaml](https://git.io/etcdclient.yaml) is an attempt to DRY (do not repeat yourself) work up.

It makes a set of assumptions.

1. That etcd has been created by kubeadm as a `local etcd`
1. That we have well defined locations for certs on the underlying file system layed down by kubeadm.
1. That etcd is listening on localhost and a node ip or for our purposes at the very least localhost.

The static pod looks like:

{{< gist mauilion 2bab4b00eb7a0ab4fca7023ae251e8ee >}}

The interesting bits are the env vars that configure etcdclient on your behalf.

With etcd and etcdclient the arguments that you can pass at the cli are also [exposed as environment variables](https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/configuration.md).

Now to see it in action!

{{< asciinema key="etcdclient" rows="30" preload="1" >}}


