# Local CI/CD Pipeline: Minikube + Nexus + Private Docker Registry + Jenkins

This repository contains the frontend application and the complete CI/CD configuration to deploy locally to a Minikube Kubernetes cluster using Jenkins on the host, Sonatype Nexus OSS (NPM Proxy), and a private Docker Registry.

---

## Architecture Overview

```
[ Host Machine ]
  ├── Jenkins (http://localhost:8080)
  │     ├── 1. Checkout Branch (GitHub / Workspace)
  │     ├── 2. Generate Tag (${commitId}_${datetimeIST})
  │     ├── 3. Podman Build & Push
  │     │      ├── NPM packages fetched from Nexus NPM Proxy
  │     │      └── Image pushed to local private Docker Registry
  │     ├── 4. Deploy to Kubernetes (kubectl set image)
  │     ├── 5. Rollout Status verification
  │     └── 6. Cleanup local images
  │
  └── Minikube Cluster (192.168.58.2)
        ├── Devops Namespace:
        │     ├── Nexus OSS (NodePort: 30081) -> npmjs-proxy
        │     └── Docker Registry v2 (ClusterIP: 10.96.0.50:5000 / NodePort: 30500)
        └── Application Namespace (ngrp):
              └── frontend-app (NodePort: 30080)
```

---

## Services & Ports Summary

| Component | Location | Internal / Cluster Port | Exposed NodePort / Host Port | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Jenkins** | Host Machine | 8080 | `http://localhost:8080` | CI/CD Pipeline Server |
| **Nexus OSS** | Minikube (`devops` ns) | 8081 | `http://192.168.58.2:30081` | NPM Proxy Repository (`/repository/npmjs-proxy/`) |
| **Docker Registry** | Minikube (`devops` ns) | 5000 | `http://192.168.58.2:30500` | Private Docker/OCI Registry |
| **Frontend App** | Minikube (`ngrp` ns) | 80 | `http://192.168.58.2:30080` | Angular Frontend live application |

---

## Pipeline Flow

1. **Checkout Source Branch**: Pulls the specified branch from Git or syncs local code.
2. **Generate Tag**: Generates a unique image tag using `<git_short_commit>_<DDMMYYYY_HHMM>` (IST).
3. **Podman Build & Push**:
   - Multi-stage build (`node:22-alpine` -> `nginx:alpine`).
   - Fetches all NPM packages via `--build-arg NPM_REGISTRY=http://192.168.58.2:30081/repository/npmjs-proxy/`.
   - Pushes built image to `192.168.58.2:30500/frontend-app:<tag>`.
4. **Deploy to Kubernetes**:
   - Updates the container image in Minikube deployment (`kubectl set image deployment/frontend-app frontend=... -n ngrp`).
5. **Rollout Status**:
   - Waits for the new pods to become Ready within 300s (`kubectl rollout status`).
6. **Post Actions**:
   - Cleans up locally cached images and reports status.

---

## Repository Structure

```
.
├── Dockerfile              # Multi-stage Dockerfile with NPM_REGISTRY build arg
├── Jenkinsfile             # Declarative Jenkins CI/CD pipeline
├── nginx.conf              # Nginx web server configuration
├── package.json            # Angular frontend dependencies
├── k8s/
│   ├── devops-stack.yaml   # Nexus OSS & Docker Registry K8s manifests
│   ├── deployment.yaml     # Frontend Deployment manifest in ngrp namespace
│   └── service.yaml        # Frontend NodePort Service manifest
└── src/                    # Angular source code
```
