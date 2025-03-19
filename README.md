# do-frappe
1-Click Frappe Framework deployment on DigitalOcean App Platform

[Detailed blog post](https://dev.to/aldo/1-click-frappe-framework-deployment-on-digitalocean-app-platform-2lbb)

# Prerequisites

- DigitalOcean Account
- DigitalOcean Access Token

# Deploy

- Fork and use as template [do-frappe](https://github.com/aldo-o/do-frappe)
- Update `repo` value on `.do/app.yaml` to be your Github username
- Link your Github Account with App Platform. (IMPORTANT)
- Generate a DigitalOcean token with scopes `update`, `read`, `create` under `app` (or give full permissions)
- Add this token as a secret in your forked repo named `DIGITALOCEAN_ACCESS_TOKEN`
- Trigger the CI/CD pipeline
- Wait for the deployment to complete