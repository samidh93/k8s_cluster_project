# Database Setup for Todo Application

This directory contains all the database-related files for the Todo application, including PostgreSQL setup, Redis configuration, and database management scripts.

## 🗄️ **Database Architecture**

### **PostgreSQL (Primary Database)**
- **Purpose**: Store todo data, user information, and application state
- **Version**: PostgreSQL 15
- **Features**: ACID compliance, advanced indexing, full-text search, triggers, views

### **Redis (Caching Layer)**
- **Purpose**: Session storage, caching, rate limiting
- **Version**: Redis 7
- **Features**: In-memory storage, persistence, pub/sub, clustering support

## 📁 **File Structure**

```
src/database/
├── init.sql              # Database initialization script
├── test-connection.sql   # Connection and schema test script
├── backup-restore.sh     # Database backup/restore script
└── README.md            # This file
```

## 🚀 **Quick Start**

### **Option 1: Using Docker Compose (Recommended)**

1. **Start the entire stack:**
   ```bash
   docker-compose up -d
   ```

2. **Check database status:**
   ```bash
   docker-compose ps
   ```

3. **View database logs:**
   ```bash
   docker-compose logs postgres
   ```

### **Option 2: Manual PostgreSQL Setup**

1. **Install PostgreSQL:**
   ```bash
   # macOS
   brew install postgresql
   
   # Ubuntu/Debian
   sudo apt-get install postgresql postgresql-contrib
   
   # CentOS/RHEL
   sudo yum install postgresql postgresql-server
   ```

2. **Start PostgreSQL service:**
   ```bash
   # macOS
   brew services start postgresql
   
   # Linux
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. **Create database and user:**
   ```bash
   # Connect as postgres user
   sudo -u postgres psql
   
   # Create database
   CREATE DATABASE tododb;
   
   # Create user
   CREATE USER todoapp WITH PASSWORD 'todoapp_password';
   
   # Grant privileges
   GRANT ALL PRIVILEGES ON DATABASE tododb TO todoapp;
   
   # Exit
   \q
   ```

4. **Initialize schema:**
   ```bash
   psql -h localhost -U postgres -d tododb -f src/database/init.sql
   ```

## 🗂️ **Database Schema**

### **Tables**

#### **`todos` Table**
| Column      | Type        | Constraints           | Description                    |
|-------------|-------------|----------------------|--------------------------------|
| `id`        | BIGSERIAL   | PRIMARY KEY          | Unique identifier              |
| `title`     | VARCHAR(255)| NOT NULL             | Todo title                     |
| `description`| TEXT       |                      | Optional description           |
| `completed` | BOOLEAN     | NOT NULL, DEFAULT FALSE | Completion status             |
| `priority`  | VARCHAR(20) | NOT NULL, DEFAULT 'MEDIUM' | Priority level               |
| `due_date`  | TIMESTAMP   |                      | Optional due date             |
| `created_at`| TIMESTAMP   | NOT NULL, DEFAULT NOW | Creation timestamp            |
| `updated_at`| TIMESTAMP   | NOT NULL, DEFAULT NOW | Last update timestamp         |

#### **Priority Levels**
- `LOW` - No rush, can be done later
- `MEDIUM` - Normal priority
- `HIGH` - Important, needs attention
- `URGENT` - Critical, must be done ASAP

### **Views**

#### **`overdue_todos`**
Shows all incomplete todos with due dates in the past.

#### **`todos_due_today`**
Shows all incomplete todos due today.

#### **`high_priority_todos`**
Shows all incomplete todos with HIGH or URGENT priority.

### **Functions**

#### **`get_todo_statistics()`**
Returns comprehensive statistics including:
- Total todos count
- Completed/incomplete counts
- Overdue todos count
- High priority todos count
- Completion rate percentage

#### **`search_todos(search_term)`**
Full-text search across title and description fields with ranking.

### **Triggers**

#### **`update_todos_updated_at`**
Automatically updates the `updated_at` timestamp whenever a todo is modified.

### **Indexes**

- **Performance indexes** on frequently queried columns
- **Full-text search indexes** for title and description
- **Composite indexes** for common query patterns

## 🔧 **Configuration**

### **Environment Variables**

| Variable        | Default Value    | Description                    |
|-----------------|------------------|--------------------------------|
| `DB_HOST`       | `localhost`      | Database host                  |
| `DB_PORT`       | `5432`           | Database port                  |
| `DB_NAME`       | `tododb`         | Database name                  |
| `DB_USERNAME`   | `todoapp`        | Database username              |
| `DB_PASSWORD`   | `todoapp_password` | Database password           |
| `REDIS_HOST`    | `localhost`      | Redis host                     |
| `REDIS_PORT`    | `6379`           | Redis port                     |
| `REDIS_PASSWORD`| (empty)          | Redis password                 |

### **Connection Pool Settings**

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20        # Production
      minimum-idle: 10             # Production
      connection-timeout: 30000    # 30 seconds
      idle-timeout: 600000         # 10 minutes
      max-lifetime: 1800000        # 30 minutes
```

## 📊 **Monitoring & Health Checks**

### **Health Check Endpoints**

- **Database**: `/actuator/health/db`
- **Redis**: `/actuator/health/redis`
- **Overall**: `/actuator/health`

### **Metrics**

- **Prometheus metrics** available at `/actuator/prometheus`
- **Database connection pool metrics**
- **Query performance metrics**
- **Cache hit/miss ratios**

## 🛠️ **Database Management**

### **Backup & Restore**

#### **Create Backup**
```bash
# Automatic timestamp
./src/database/backup-restore.sh backup

# Custom filename
./src/database/backup-restore.sh backup my_backup.sql
```

#### **Restore Database**
```bash
./src/database/backup-restore.sh restore my_backup.sql
```

#### **List Backups**
```bash
./src/database/backup-restore.sh list
```

### **Testing Database Connection**

```bash
# Test schema and functions
psql -h localhost -U postgres -d tododb -f src/database/test-connection.sql

# Quick connection test
psql -h localhost -U todoapp -d tododb -c "SELECT version();"
```

### **Database Maintenance**

#### **Vacuum and Analyze**
```sql
-- Regular maintenance
VACUUM ANALYZE todos;

-- Full vacuum (during maintenance window)
VACUUM FULL ANALYZE todos;
```

#### **Index Maintenance**
```sql
-- Rebuild indexes
REINDEX TABLE todos;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'todos';
```

## 🔒 **Security Considerations**

### **Production Security**

1. **Change default passwords** for both PostgreSQL and Redis
2. **Use SSL connections** for database communication
3. **Implement connection pooling** with proper limits
4. **Regular security updates** for database software
5. **Network isolation** - restrict database access to application servers only

### **User Permissions**

```sql
-- Minimal permissions for application user
GRANT CONNECT ON DATABASE tododb TO todoapp;
GRANT USAGE ON SCHEMA public TO todoapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON todos TO todoapp;
GRANT USAGE, SELECT ON SEQUENCE todos_id_seq TO todoapp;
```

## 📈 **Performance Optimization**

### **Query Optimization**

1. **Use appropriate indexes** for common query patterns
2. **Implement pagination** for large result sets
3. **Use database views** for complex queries
4. **Implement caching** for frequently accessed data

### **Connection Pooling**

- **HikariCP** for Java applications
- **Proper pool sizing** based on load testing
- **Connection leak detection** enabled

### **Caching Strategy**

- **Redis** for session data and frequently accessed objects
- **Application-level caching** for business logic results
- **Database query result caching** for expensive operations

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Connection Refused**
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check port availability
netstat -an | grep 5432
```

#### **Authentication Failed**
```bash
# Check pg_hba.conf configuration
sudo cat /etc/postgresql/*/main/pg_hba.conf

# Verify user exists
sudo -u postgres psql -c "\du"
```

#### **Permission Denied**
```bash
# Check user permissions
psql -h localhost -U postgres -d tododb -c "\du todoapp"

# Grant necessary permissions
GRANT ALL PRIVILEGES ON TABLE todos TO todoapp;
```

### **Log Analysis**

```bash
# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log

# Application logs
docker-compose logs backend
```

## 📚 **Additional Resources**

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Spring Data JPA Reference](https://docs.spring.io/spring-data/jpa/docs/current/reference/html/)
- [HikariCP Configuration](https://github.com/brettwooldridge/HikariCP)

## 🤝 **Support**

For database-related issues:

1. **Check the logs** for error messages
2. **Verify configuration** matches environment
3. **Test connectivity** using provided scripts
4. **Review this documentation** for common solutions

---

**Happy Database Management! 🗄️✨**
