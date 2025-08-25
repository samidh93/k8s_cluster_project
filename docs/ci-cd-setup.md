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

**Good news! No secrets are required!** 🎉

The pipeline uses **GitHub Container Registry (ghcr.io)** which automatically authenticates using your repository's built-in `GITHUB_TOKEN`.

### **How It Works**

The pipeline automatically:
1. **Authenticates** to GitHub Container Registry using `GITHUB_TOKEN`
2. **Builds Docker images** from your source code
3. **Pushes images** to `ghcr.io/${{ github.repository }}/`
4. **Tags images** with commit SHA and `latest`

### **Image URLs**

Your images will be available at:
- `ghcr.io/YOUR_USERNAME/kubernetes/backend:latest`
- `ghcr.io/YOUR_USERNAME/kubernetes/frontend:latest`
- `ghcr.io/YOUR_USERNAME/kubernetes/nginx:latest`

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
