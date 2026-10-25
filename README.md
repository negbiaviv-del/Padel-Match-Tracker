# Padel Match Tracker

A cloud-native DevOps project for recording and viewing padel match results.

## Project Goal

Build, deploy, monitor, and automate a multi-tier application on AWS while demonstrating modern DevOps practices.

## Application

The application allows users to record padel matches and view match history.

- Frontend: simple web interface served by Nginx
- Backend: Python API built with FastAPI
- Database: PostgreSQL
- Metrics: Prometheus metrics exposed by the backend

## Target Delivery Flow

Developer push → Jenkins CI → Amazon ECR → GitOps update → Argo CD → Amazon EKS

## Repository Map

- `backend/` — Python API source code and automated tests
- `frontend/` — web interface and Nginx configuration
- `terraform/` — AWS infrastructure as code
- `kubernetes/` — Helm chart, Argo CD, and cluster add-ons
- `observability/` — Prometheus alerts and Grafana dashboards
- `scripts/` — repeatable helper scripts
- `docs/` — architecture, deployment, and learning documentation

## Project Principles

- Understand every component before automating it
- Keep secrets out of Git
- Use least-privilege access
- Prefer cost-efficient AWS resources
- Document design decisions and trade-offs

## Current Status

- [x] Git repository initialized
- [x] Initial project structure created
- [x] Git ignore rules configured
- [ ] Application contract defined
- [ ] Backend implemented
- [ ] Local database integration
- [ ] Containers and Kubernetes deployment
- [ ] AWS infrastructure and CI/CD
