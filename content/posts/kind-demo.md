---
title: Presenting to the San Francisco Kubernetes Meetup about kind!"
date: 2019-04-10T15:28:10-07:00
draft: false
toc: true
asciinema: false
images:
  - https://mauilion.github.io/kind-demo/static/logo.png
tags: 
  - talks
  - kind
---

On 4/7/2019 I had the opportunity to talk to folks that attended the SF Kubernetes meetup [Anaplan](https://www.meetup.com/San-Francisco-Kubernetes-Meetup/events/259713345/) about kind!

It's a great project and I end up using kind everyday to validate or develop designs for Kubernetes clusters.

The slides that I presented are here: [mauilion.github.io/kind-demo](https://mauilion.github.com/kind-demo) and a link to the repository with the deck and the content used to bring up the demo cluster is here: [github.com/mauilion/kind-demo](https://github.com/mauilion/kind-demo)

[![](/kind-slide.png)](https://mauilion.github.io/kind-demo)

In the talk I dug in a bit about what kind and kubeadm are and what problems they solve.

I also demonstrated creating a 7 node cluster on my laptop live!

Finally, we spent a little time talking about the way that Docker in Docker is being used here.

My laptop is a recent Lenovo x1 carbon running Ubuntu and i3.

When I bring up a kind cluster I can see the docker containers that I start with a simple `docker ps`
``` bash
$ docker ps --no-trunc 
CONTAINER ID                                                       IMAGE                  COMMAND                                  CREATED             STATUS              PORTS                                  NAMES
b8f8ef6d2d97836dc66e09fe5e1a4c7e1b7a880c95372b8d4881288238985f22   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes       36533/tcp, 127.0.0.1:36533->6443/tcp   kind-external-load-balancer
69daaf381d8a4dbafb1197502446858e9b6e9e950c0b8db1eb1759dc2883f3ec   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes       34675/tcp, 127.0.0.1:34675->6443/tcp   kind-control-plane3
9f577280b62052d5caeecd7483e3283f01d3a3c784c4620efca15338cd0cad23   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes       38847/tcp, 127.0.0.1:38847->6443/tcp   kind-control-plane
dfcab2e279ffbb2710dbdaa3386814887d081ddd378641777116b3fed131a3b0   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes                                              kind-worker
e486393a724079b77b4aaec5de18fd0aea70f9ce0b46bb6d45edb3382bf3cb32   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes       35759/tcp, 127.0.0.1:35759->6443/tcp   kind-control-plane2
be76f1f1ba3c365a5058c2f46b555174c1c6b28418844621e31a2e2c548c5e5f   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes                                              kind-worker2
5a845004c40b035a198333a7f8c17eec8c3a024db15f484af4b5d7974e4c27db   kindest/node:v1.13.4   "/usr/local/bin/entrypoint /sbin/init"   12 minutes ago      Up 12 minutes                                              kind-worker3
```

And if I exec into one of the control plane "nodes" and run docker ps:
``` bash
root@kind-control-plane:/# docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
0904a715c607        18ee25ef69a8           "kube-controller-man…"   11 minutes ago      Up 11 minutes                           k8s_kube-controller-manager_kube-controller-manager-kind-control-plane_kube-system_0139f650b0ebdfe8039809598eafaed5_1
cce01b13d1be        fd722e321590           "kube-scheduler --ad…"   11 minutes ago      Up 11 minutes                           k8s_kube-scheduler_kube-scheduler-kind-control-plane_kube-system_4b52d75cab61380f07c0c5a69fb371d4_1
adb83f623945        calico/node            "start_runit"            11 minutes ago      Up 11 minutes                           k8s_calico-node_calico-node-bkbjv_kube-system_f3ffe8bb-5be3-11e9-a476-024240bbde2e_0
036e0f373c0b        7fe6f0b71640           "/usr/local/bin/kube…"   12 minutes ago      Up 12 minutes                           k8s_kube-proxy_kube-proxy-vnmbc_kube-system_f4010699-5be3-11e9-a476-024240bbde2e_0
57b9c22fa25a        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_calico-node-bkbjv_kube-system_f3ffe8bb-5be3-11e9-a476-024240bbde2e_0
f8ccefbb6faf        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_kube-proxy-vnmbc_kube-system_f4010699-5be3-11e9-a476-024240bbde2e_0
3b722fb72dd3        4eb4a1578884           "kube-apiserver --au…"   12 minutes ago      Up 12 minutes                           k8s_kube-apiserver_kube-apiserver-kind-control-plane_kube-system_36fd00068b02bdfc674c44e345a08553_0
37ce90751bb7        3cab8e1b9802           "etcd --advertise-cl…"   12 minutes ago      Up 12 minutes                           k8s_etcd_etcd-kind-control-plane_kube-system_a17306e4c3c6a492df6a1ccea459c458_0
b2dab14dc554        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_kube-scheduler-kind-control-plane_kube-system_4b52d75cab61380f07c0c5a69fb371d4_0
aa56021201fb        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_kube-controller-manager-kind-control-plane_kube-system_0139f650b0ebdfe8039809598eafaed5_0
71d3e0cb6fe2        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_kube-apiserver-kind-control-plane_kube-system_36fd00068b02bdfc674c44e345a08553_0
8a2e80860798        k8s.gcr.io/pause:3.1   "/pause"                 12 minutes ago      Up 12 minutes                           k8s_POD_etcd-kind-control-plane_kube-system_a17306e4c3c6a492df6a1ccea459c458_0
```

and from the underlying node we can the processes that are related to the containers.

``` bash
 2572 ?        Ssl    1:44 /usr/bin/dockerd --live-restore -H fd://
 2655 ?        Ssl    1:40  \_ docker-containerd --config /var/run/docker/containerd/containerd.toml
10669 ?        Sl     0:00  |   \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/9f577280b62052d5caeecd7483e3283f01d3a
10801 ?        Ss     0:00  |   |   \_ /sbin/init
14598 ?        S<s    0:00  |   |       \_ /lib/systemd/systemd-journald
14736 ?        Ssl    2:18  |   |       \_ /usr/bin/dockerd -H fd://
14958 ?        Ssl    0:33  |   |       |   \_ docker-containerd --config /var/run/docker/containerd/containerd.toml
22752 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/8a2e8086079885ea914c5
22816 ?        Ss     0:00  |   |       |       |   \_ /pause
22762 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/71d3e0cb6fe2f988842bb
22852 ?        Ss     0:00  |   |       |       |   \_ /pause
22777 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/aa56021201fb02aa8d855
22846 ?        Ss     0:00  |   |       |       |   \_ /pause
22795 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/b2dab14dc554cdcf40e13
22881 ?        Ss     0:00  |   |       |       |   \_ /pause
23015 ?        Sl     0:03  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/37ce90751bb7b196243f1
23061 ?        Ssl    4:41  |   |       |       |   \_ etcd --advertise-client-urls=https://172.17.0.6:2379 --cert-file=/etc/kubernetes/pki/etcd/server.crt --client-cert-auth=true --data-dir
23066 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/3b722fb72dd30e8b3e07f
23126 ?        Ssl    5:30  |   |       |       |   \_ kube-apiserver --authorization-mode=Node,RBAC --advertise-address=172.17.0.6 --allow-privileged=true --client-ca-file=/etc/kubernetes/p
24764 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/f8ccefbb6faf067876cf4
24830 ?        Ss     0:00  |   |       |       |   \_ /pause
24779 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/57b9c22fa25a83e4c69ca
24819 ?        Ss     0:00  |   |       |       |   \_ /pause
24895 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/036e0f373c0bcac56484c
24921 ?        Ssl    0:18  |   |       |       |   \_ /usr/local/bin/kube-proxy --config=/var/lib/kube-proxy/config.conf --hostname-override=kind-control-plane
26721 ?        Sl     0:04  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/adb83f623945215c3597a
26746 ?        Ss     0:00  |   |       |       |   \_ /sbin/runsvdir -P /etc/service/enabled
28040 ?        Ss     0:00  |   |       |       |       \_ runsv bird6
28242 ?        S      0:00  |   |       |       |       |   \_ bird6 -R -s /var/run/calico/bird6.ctl -d -c /etc/calico/confd/config/bird6.cfg
28041 ?        Ss     0:00  |   |       |       |       \_ runsv confd
28047 ?        Sl     0:28  |   |       |       |       |   \_ calico-node -confd
28042 ?        Ss     0:00  |   |       |       |       \_ runsv felix
28044 ?        Sl     2:03  |   |       |       |       |   \_ calico-node -felix
28043 ?        Ss     0:00  |   |       |       |       \_ runsv bird
28245 ?        S      0:01  |   |       |       |           \_ bird -R -s /var/run/calico/bird.ctl -d -c /etc/calico/confd/config/bird.cfg
27663 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/cce01b13d1be8c0e434cb
27701 ?        Ssl    1:19  |   |       |       |   \_ kube-scheduler --address=127.0.0.1 --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true
27704 ?        Sl     0:00  |   |       |       \_ docker-containerd-shim -namespace moby -workdir /var/lib/docker/containerd/daemon/io.containerd.runtime.v1.linux/moby/0904a715c607d662900b1
27744 ?        Ssl    0:04  |   |       |           \_ kube-controller-manager --enable-hostpath-provisioner=true --address=127.0.0.1 --allocate-node-cidrs=true --authentication-kubeconfig=/
```

This is because at each of the layers of abstraction, we are again still sharing the same linux kernel. So when I create containers leveraging something like docker in docker I am still making use of the same resources I would even if I were to run the docker command from the underlying node. 

Put another way the docker daemon and all it's dependencies is running as an application inside the docker container I started. It's not mounting in the docker socket or any of that just making use of docker and the linux namespaces available to it.

Thanks!
