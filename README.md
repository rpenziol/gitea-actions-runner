# Gitea Actions Runner

This is a project forked from [actions/actions-runner-controller](https://github.com/actions/actions-runner-controller) and incorporates code from [actions-runner-controller/releases](https://github.com/actions-runner-controller/releases)

## About

**gitea-actions-runner** defines a set of containers that act as Gitea Runners. There are 3 main variants of the container:

- [gitea-actions-runner](https://github.com/rpenziol/gitea-actions-runner/pkgs/container/gitea-actions-runner%2Fgitea-actions-runner): Base container with Gitea Actions Runner
- [gitea-actions-runner-dind](https://github.com/rpenziol/gitea-actions-runner/pkgs/container/gitea-actions-runner%2Fgitea-actions-runner-dind): Container with Gitea Actions Runner and Docker-in-Docker, for workflows with Docker steps
- [gitea-actions-runner-dind-rootless](https://github.com/rpenziol/gitea-actions-runner/pkgs/container/gitea-actions-runner%2Fgitea-actions-runner-dind-rootless) (coming soon): Container with Gitea Actions Runner and Docker-in-Docker, for workflows with Docker steps, running as non-root user

For now only amd64 images based on Ubuntu 22.04 have been published. This project will strive to support all images defined in **actions/actions-runner-controller**. This consists of the containers listed above, based on Ubuntu 20.04 and Ubuntu 22.04 for amd64 and arm64 platforms.

## Getting Started

Follow Gitea's initial getting started guide for Gitea Actions [https://blog.gitea.io/2023/03/hacking-on-gitea-actions/](https://blog.gitea.io/2023/03/hacking-on-gitea-actions/)

### Kuberentes

Tailor of the template below to meet your needs. As-is this will create a Gitea Runner pod in Kubernetes that will allow you to run Gitea Actions with Docker steps.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    io.kompose.service: gitea-runner
  name: gitea-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: gitea-runner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        io.kompose.service: gitea-runner
      annotations:
    spec:
      containers:
      - name: runner
        image: ghcr.io/rpenziol/gitea-actions-runner/gitea-actions-runner-dind:ubuntu-22.04
        volumeMounts:
        - mountPath: /.runner
          name: gitea-runner-configmap
          subPath: .runner
        securityContext:
          privileged: true
      hostNetwork: true
      volumes:
        - name: gitea-runner-configmap
          configMap:
            name: gitea-runner-configmap
status: {}

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitea-runner-configmap
data:
  .runner: |
    {
      "id": 6,
      "uuid": "b66cdb63-c4ee-48e1-9326-4bb01afaff73",
      "name": "gitea-runner-1",
      "token": "your-generated-gitea-token-here",
      "address": "https://gitea.yourdomain.com",
      "insecure": "true",
      "labels": [
        "ubuntu-latest:docker://node:16-bullseye",
        "ubuntu-22.04:docker://node:16-bullseye",
        "ubuntu-20.04:docker://node:16-bullseye",
        "ubuntu-18.04:docker://node:16-buster"
      ]
    }

```

## Contributing

We welcome contributions from the community. For more details on contributing to the project (including requirements), please refer to "[Getting Started with Contributing](https://github.com/actions/actions-runner-controller/blob/master/CONTRIBUTING.md)."

## Troubleshooting

We are very happy to help you with any issues you have. Please refer to the "[Troubleshooting](https://github.com/actions/actions-runner-controller/blob/master/TROUBLESHOOTING.md)" section for common issues.
