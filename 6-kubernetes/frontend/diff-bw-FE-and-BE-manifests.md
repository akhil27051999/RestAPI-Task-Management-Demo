
## ✅ Why do we have fewer manifest files for the frontend?
**You typically only see:**
- deployment.yaml
- service.yaml
- ingress.yaml

**Because that's often all that’s needed for frontend apps like React/Vue/Angular, which are static web apps. These don’t need as much infrastructure as a backend service.**
## 🔍 Now, compare it to the backend + database setup:

| File                             | Backend Use                                                   | Frontend Use                                                                              |
| -------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `configmap.yaml`                 | Used to pass environment configs (DB URL, log level, etc.)    | Rarely needed; frontend config is usually bundled at build time or served via static JSON |
| `hpa.yaml`                       | Backend needs autoscaling due to load                         | Frontend is static and served through NGINX or similar — not CPU-intensive                |
| `ingress.yaml`                   | Needed to expose backend endpoints via HTTP(S)                | Also needed to expose the frontend (React app)                                            |
| `mysql-deployment.yaml`          | Deploys MySQL DB                                              | ❌ Not applicable to frontend                                                             |
| `mysql-service.yaml`             | Internal service for backend to reach MySQL                   | ❌ Not needed for frontend                                                                |
| `namespace.yaml`                 | Logical grouping of backend components                        | Could be reused, but often frontend is in same namespace                                  |
| `pdb.yaml` (PodDisruptionBudget) | Helps ensure backend API remains available during disruptions | ❌ Not critical for frontend                                                              |
| `secret.yaml`                    | Needed for DB credentials, API keys                           | Usually not needed for frontend, or values are injected at build                          |
| `task-api-deployment.yaml`       | Runs the backend Node.js service                              | Frontend has its own deployment, often using NGINX                                        |
| `task-api-service.yaml`          | Exposes backend to other services                             | Frontend also has a service for Ingress to route traffic to it                            |
