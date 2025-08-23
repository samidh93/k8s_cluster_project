# Todo App Architecture

## 🏗️ Project Overview

This is a full-stack Todo application built with modern technologies and deployed on Kubernetes.

## 🛠️ Technology Stack

### Frontend
- **Framework**: React 18
- **Build Tool**: Create React App
- **HTTP Client**: Axios
- **Routing**: React Router DOM
- **Container**: Nginx (production)

### Backend
- **Framework**: Spring Boot 3.2.0
- **Language**: Java 17
- **Build Tool**: Maven
- **Database**: PostgreSQL
- **Cache**: Redis
- **Container**: OpenJDK 17 JRE

### Infrastructure
- **Container Orchestration**: Kubernetes
- **Monitoring**: Prometheus + Grafana
- **API Gateway**: Nginx
- **Database**: PostgreSQL
- **Cache**: Redis

## 📁 Project Structure

```
kubernetes/
├── 📁 src/                           # Source code
│   ├── frontend/                     # React application
│   │   ├── src/
│   │   │   ├── components/           # Reusable components
│   │   │   ├── pages/                # Page components
│   │   │   └── services/             # API services
│   │   ├── public/                   # Static assets
│   │   └── package.json              # Dependencies
│   ├── backend/                      # Java Spring Boot
│   │   ├── src/main/java/
│   │   │   └── com/todoapp/         # Java packages
│   │   ├── src/main/resources/      # Configuration files
│   │   └── pom.xml                  # Maven dependencies
│   └── database/                     # Database scripts
│       ├── migrations/               # Schema changes
│       └── seeds/                    # Initial data
├── 📁 docker/                        # Docker configurations
│   ├── frontend.Dockerfile          # React container
│   ├── backend.Dockerfile           # Java container
│   └── nginx.conf                   # Nginx configuration
├── 📁 k8s/                          # Kubernetes manifests
│   ├── base/                        # Base configurations
│   ├── overlays/                    # Environment-specific configs
│   └── namespaces/                  # Namespace definitions
└── 📁 scripts/                      # Build and deployment scripts
```

## 🚀 Development Workflow

### 1. Local Development
```bash
# Start backend (Java)
cd src/backend
mvn spring-boot:run

# Start frontend (React)
cd src/frontend
npm start
```

### 2. Building
```bash
# Build everything
make build-all

# Build specific components
make build-frontend
make build-backend
```

### 3. Deployment
```bash
# Deploy to development
make deploy-dev

# Deploy to staging
make deploy-staging

# Deploy to production
make deploy-prod
```

## 🔧 Key Features

### Frontend Features
- ✅ Add new todos
- 🔴 Mark todos as complete
- 🗑️ Delete todos
- 📝 Edit todo descriptions
- 📅 Due dates (planned)
- 🏷️ Categories (planned)
- 👤 User authentication (planned)

### Backend Features
- RESTful API endpoints
- JPA/Hibernate for data persistence
- Redis caching for performance
- Health checks and monitoring
- Input validation
- Error handling

### Infrastructure Features
- Multi-environment deployment
- Auto-scaling capabilities
- Health monitoring
- Load balancing
- Security headers
- Rate limiting

## 🌐 API Endpoints

### Todo Management
- `GET /api/todos` - List all todos
- `POST /api/todos` - Create new todo
- `GET /api/todos/{id}` - Get specific todo
- `PUT /api/todos/{id}` - Update todo
- `DELETE /api/todos/{id}` - Delete todo

### Health & Monitoring
- `GET /health` - Frontend health check
- `GET /actuator/health` - Backend health check
- `GET /metrics` - Prometheus metrics

## 🔒 Security Features

- Input validation and sanitization
- Rate limiting (API: 10 req/s, General: 100 req/s)
- Security headers (XSS protection, frame options)
- Non-root container execution
- Health checks for all services

## 📊 Monitoring & Observability

### Metrics Collected
- HTTP request counts and rates
- Response times
- Error rates
- Database connection status
- Cache hit/miss ratios

### Dashboards
- Nginx performance metrics
- Application business metrics
- Infrastructure health
- Custom Todo app metrics

## 🚀 Next Steps

### Phase 2: Backend Implementation
- [ ] Create Todo entity and repository
- [ ] Implement REST controllers
- [ ] Add database configuration
- [ ] Set up Redis caching

### Phase 3: Frontend Implementation
- [ ] Create React components
- [ ] Implement API integration
- [ ] Add state management
- [ ] Create responsive UI

### Phase 4: Integration & Testing
- [ ] Connect frontend to backend
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Security testing

## 🐛 Troubleshooting

### Common Issues
1. **Port conflicts**: Ensure ports 3000, 8080, 9090 are available
2. **Database connection**: Check PostgreSQL is running and accessible
3. **Build failures**: Verify Java 17 and Node.js 18 are installed
4. **Kubernetes issues**: Check cluster status and resource availability

### Useful Commands
```bash
# Check application status
make status

# View logs
make logs

# Validate Kubernetes manifests
make validate

# Clean up resources
make clean
```

## 📚 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [React Documentation](https://reactjs.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
