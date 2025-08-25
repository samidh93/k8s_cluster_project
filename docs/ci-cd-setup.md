# CI/CD Pipeline Setup Guide

## 🚀 Overview

This document explains how to set up and configure the CI/CD pipeline for the Todo application.

## 📋 Pipeline Stages

The CI/CD pipeline consists of 6 main jobs:

1. **Test & Quality Check** - Runs tests and code quality checks
2. **Build Applications** - Builds Java backend and React frontend
3. **Docker Image Building** - Creates and pushes Docker images
4. **Security Scanning** - Runs vulnerability scans
5. **Deploy to Development** - Deploys to dev environment
6. **Deploy to Production** - Deploys to production environment

## 🔐 Required GitHub Secrets

To use the Docker image building functionality, you need to configure these secrets in your GitHub repository:

### **Docker Hub Credentials**
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub access token (not password)

### **How to Set Up Secrets**

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact names above

### **Getting Docker Hub Access Token**

1. Log in to [Docker Hub](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Give it a name (e.g., "GitHub Actions")
5. Copy the token and use it as `DOCKER_PASSWORD`

## 🏗️ Pipeline Triggers

- **Push to `main`** → Triggers full pipeline including production deployment
- **Push to `develop`** → Triggers pipeline up to development deployment
- **Pull Request** → Triggers testing and quality checks only

## 🔍 Code Quality Tools

### **Backend (Java)**
- **Checkstyle** - Code style and formatting
- **SpotBugs** - Bug detection and code analysis
- **Maven** - Build and dependency management

### **Frontend (React/TypeScript)**
- **ESLint** - Code linting and style enforcement
- **TypeScript** - Type checking
- **Jest** - Unit testing

## 🐳 Docker Images

The pipeline builds and pushes these images:
- `backend` - Spring Boot application
- `frontend` - React application
- `nginx` - Reverse proxy and static file server

## 📊 Security Scanning

- **Trivy** - Vulnerability scanner for containers and dependencies
- Results are uploaded to GitHub Security tab
- Scans run on every build

## 🚀 Deployment

### **Development Environment**
- Triggered on push to `develop` branch
- Requires successful test, build, and security checks

### **Production Environment**
- Triggered on push to `main` branch
- Requires successful development deployment
- Additional approval may be required

## 🔧 Customization

### **Modifying Pipeline**
- Edit `.github/workflows/ci-cd.yml`
- Add new jobs or modify existing ones
- Update environment configurations

### **Adding New Quality Checks**
- Backend: Add Maven plugins to `pom.xml`
- Frontend: Add npm scripts to `package.json`
- Update pipeline workflow accordingly

## 🐛 Troubleshooting

### **Common Issues**

1. **Maven Build Fails**
   - Check Java version compatibility
   - Verify dependencies in `pom.xml`

2. **Frontend Build Fails**
   - Check Node.js version compatibility
   - Verify dependencies in `package.json`

3. **Docker Build Fails**
   - Verify Docker Hub credentials
   - Check Dockerfile syntax

4. **Quality Checks Fail**
   - Review Checkstyle/ESLint output
   - Fix code style issues
   - Address security vulnerabilities

### **Getting Help**

- Check GitHub Actions logs for detailed error messages
- Review the specific job that failed
- Verify all required secrets are configured

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Maven Checkstyle Plugin](https://maven.apache.org/plugins/maven-checkstyle-plugin/)
- [SpotBugs Maven Plugin](https://spotbugs.readthedocs.io/en/latest/maven.html)
- [ESLint Configuration](https://eslint.org/docs/user-guide/configuring)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)
