---
title: "What is Docker in Docker"
date: 2019-07-01T13:42:45-07:00
draft: true
toc: false
asciinema: true
images:
  - images/michael-blum-whale-unsplash.jpg
tags:
  - docker
---

Just got back from vacation and I am excited to bring another blog post on something I don't think is terribly well explained. Docker in Docker (DinD) is an interesting way to make use of the docker and containerization in general.

The most interesting thing to me is that there are at least two technical definitions of what DinD is.

1. You have a node where docker is running and you expose the docker socket on that node to a container that has been started. This enables the new running container to assume that the mounted docker socket can be used to create other containers.
2. When you provide enough privilege to a container that the new container can make use of the same kernel primitives necessary to create a container. This does not require mounting in the docker socket but it does require more extensive privileges.


