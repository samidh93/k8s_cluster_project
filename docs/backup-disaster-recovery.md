# Backup & Disaster Recovery Guide

## 🚨 Overview

This document describes the comprehensive backup and disaster recovery system implemented for the Todo application. The system provides automated backups of both database and application state, with disaster recovery procedures to restore the application in case of failures.

## 🏗️ Architecture

### Backup Components

1. **VolumeSnapshotClass** - Defines snapshot policies for PVC backups
2. **Backup Storage PVC** - Persistent storage for backup files
3. **Backup Service Account** - Kubernetes identity for backup operations
4. **Backup RBAC** - Role-based access control for backup permissions
5. **Database Backup CronJob** - Automated PostgreSQL backups
6. **Application State Backup** - Kubernetes resource backups
7. **Disaster Recovery Scripts** - Automated recovery procedures

### Backup Schedule

| Component | Development | Staging | Production |
|-----------|-------------|---------|------------|
| Database | Daily at 2 AM | Daily at 2 AM | Every 6 hours |
| Application State | Daily at 3 AM | Daily at 3 AM | Daily at 3 AM |
| Retention | 7 days | 14 days | 14 days |
| Storage | 10Gi | 25Gi | 50Gi |

## 🔧 Implementation

### 1. Volume Snapshots

Volume snapshots provide point-in-time copies of persistent volumes:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: todo-backup-snapshot-class
spec:
  driver: standard.csi.k8s.io
  deletionPolicy: Delete  # Development: Delete, Production: Retain
```

### 2. Database Backups

PostgreSQL database backups using `pg_dump`:

```bash
# Backup command
pg_dump -h todo-postgres -U postgres -d tododb > backup.sql

# Restore command
psql -h todo-postgres -U postgres -d tododb < backup.sql
```

**Backup Features:**
- Compressed backups (gzip)
- Timestamped filenames
- Integrity verification
- Automated cleanup

### 3. Application State Backups

Kubernetes resource backups:

```bash
# Backup all resources
kubectl get all -n todo-app -o yaml > all-resources.yaml

# Backup specific resource types
kubectl get configmaps,secrets,pvc,networkpolicies,roles,rolebindings,serviceaccounts,ingress -n todo-app -o yaml > k8s-resources.yaml
```

**Backup Contents:**
- ConfigMaps and Secrets metadata
- Deployments and Services
- PVCs and Network Policies
- RBAC configuration
- Ingress rules

### 4. Backup Storage

Dedicated PVC for backup storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: todo-backup-pvc
  annotations:
    backup.kubernetes.io/retention: "30d"
    backup.kubernetes.io/compression: "gzip"
spec:
  resources:
    requests:
      storage: 10Gi  # Development: 10Gi, Production: 50Gi
```

## 🚀 Usage

### Manual Backup

#### Database Backup

```bash
# Create manual database backup
kubectl create job --from=cronjob/todo-database-backup todo-manual-db-backup-$(date +%Y%m%d-%H%M%S) -n todo-app

# Monitor backup progress
kubectl get jobs -n todo-app -l purpose=backup

# View backup logs
kubectl logs job/todo-manual-db-backup-$(date +%Y%m%d-%H%M%S) -n todo-app
```

#### Application State Backup

```bash
# Create manual application backup
kubectl create job --from=cronjob/todo-application-backup-scheduled todo-manual-app-backup-$(date +%Y%m%d-%H%M%S) -n todo-app

# Monitor backup progress
kubectl get jobs -n todo-app -l purpose=backup

# View backup logs
kubectl logs job/todo-manual-app-backup-$(date +%Y%m%d-%H%M%S) -n todo-app
```

### Disaster Recovery

#### Using the Recovery Script

```bash
# Check prerequisites
./scripts/disaster-recovery.sh check

# List available backups
./scripts/disaster-recovery.sh list-backups

# Restore database from specific backup
./scripts/disaster-recovery.sh restore-db <backup-job-name>

# Restore application state from specific backup
./scripts/disaster-recovery.sh restore-app <backup-job-name>

# Perform full disaster recovery
./scripts/disaster-recovery.sh full-recovery

# Check recovery status
./scripts/disaster-recovery.sh status
```

#### Manual Recovery

```bash
# Restore database
kubectl create job --from=cronjob/todo-database-backup todo-db-restore-$(date +%Y%m%d-%H%M%S) -n todo-app

# Restore application state
kubectl create job --from=cronjob/todo-application-backup-scheduled todo-app-restore-$(date +%Y%m%d-%H%M%S) -n todo-app
```

## 📊 Monitoring

### Backup Status

```bash
# Check backup jobs
kubectl get cronjobs -n todo-app -l purpose=backup

# Check backup job history
kubectl get jobs -n todo-app -l purpose=backup --sort-by=.metadata.creationTimestamp

# View backup logs
kubectl logs -n todo-app -l purpose=backup --tail=50
```

### Backup Storage

```bash
# Check backup storage status
kubectl get pvc -n todo-app -l purpose=backup

# Check backup storage usage
kubectl exec -n todo-app deployment/todo-backend -- df -h /backup-storage
```

### Recovery Status

```bash
# Check restore jobs
kubectl get jobs -n todo-app -l purpose=restore

# Check application health
kubectl get pods -n todo-app
kubectl get services -n todo-app
```

## 🧪 Testing

### Test Backup System

```bash
# Run comprehensive backup tests
./scripts/test-backup.sh

# Test specific components
./scripts/test-backup.sh test_backup_infrastructure
./scripts/test-backup.sh test_backup_jobs
./scripts/test_backup.sh test_backup_storage
```

### Test Disaster Recovery

```bash
# Test recovery script
./scripts/disaster-recovery.sh check
./scripts/disaster-recovery.sh help

# Test manual backup
kubectl create job --from=cronjob/todo-database-backup todo-test-backup -n todo-app
```

## 🔒 Security

### Backup Permissions

The backup service account has minimal required permissions:

```yaml
# Can read secrets for database credentials
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["todo-secrets"]
  verbs: ["get"]

# Can create volume snapshots
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots"]
  verbs: ["get", "list", "create", "delete"]
```

### Data Protection

- **Secrets**: Only metadata backed up (no sensitive data)
- **Encryption**: Production backups use encrypted storage
- **Access Control**: RBAC restricts backup operations
- **Audit Logging**: All backup operations are logged

## 🚨 Troubleshooting

### Common Issues

#### Backup Jobs Failing

```bash
# Check job status
kubectl get jobs -n todo-app -l purpose=backup

# Check job logs
kubectl logs job/<backup-job-name> -n todo-app

# Check events
kubectl describe job <backup-job-name> -n todo-app
```

#### Backup Storage Issues

```bash
# Check PVC status
kubectl get pvc todo-backup-pvc -n todo-app

# Check storage events
kubectl describe pvc todo-backup-pvc -n todo-app

# Check storage capacity
kubectl get pvc todo-backup-pvc -n todo-app -o jsonpath='{.spec.resources.requests.storage}'
```

#### Recovery Failures

```bash
# Check restore job status
kubectl get jobs -n todo-app -l purpose=restore

# Check restore logs
kubectl logs job/<restore-job-name> -n todo-app

# Verify backup files exist
kubectl exec -n todo-app deployment/todo-backend -- ls -la /backup-storage/
```

### Recovery Procedures

#### Database Recovery

1. **Stop application** (optional, for data consistency)
2. **Restore database** from backup
3. **Verify data integrity**
4. **Restart application**

#### Application Recovery

1. **Stop all deployments**
2. **Restore Kubernetes resources**
3. **Verify resource status**
4. **Restart deployments**

#### Full System Recovery

1. **Assess damage scope**
2. **Restore database first**
3. **Restore application state**
4. **Verify system health**
5. **Test critical functionality**

## 📈 Best Practices

### Backup Strategy

1. **Regular Backups**: Automated daily backups
2. **Multiple Copies**: Keep backups in different locations
3. **Test Restores**: Regularly test recovery procedures
4. **Monitor Health**: Track backup success rates
5. **Document Procedures**: Maintain recovery runbooks

### Recovery Strategy

1. **RTO (Recovery Time Objective)**: Target < 1 hour
2. **RPO (Recovery Point Objective)**: Target < 6 hours
3. **Automated Recovery**: Use scripts for consistency
4. **Validation**: Verify recovery success
5. **Communication**: Notify stakeholders of recovery status

### Security Considerations

1. **Least Privilege**: Minimal required permissions
2. **Encryption**: Encrypt sensitive backup data
3. **Access Control**: Restrict backup access
4. **Audit Logging**: Log all backup operations
5. **Regular Review**: Review backup permissions

## 🔮 Future Enhancements

### Planned Features

1. **Cross-Region Backups**: Geographic distribution
2. **Incremental Backups**: Reduce backup size and time
3. **Backup Encryption**: End-to-end encryption
4. **Backup Compression**: Advanced compression algorithms
5. **Backup Deduplication**: Eliminate duplicate data
6. **Backup Validation**: Automated backup integrity checks
7. **Backup Monitoring**: Prometheus metrics and alerts

### Integration Opportunities

1. **Monitoring Stack**: Integrate with Prometheus/Grafana
2. **Alerting**: Notify on backup failures
3. **Metrics**: Track backup performance and success rates
4. **Dashboard**: Visual backup status and history
5. **API**: Programmatic backup management

## 📚 References

- [Kubernetes CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
- [PostgreSQL Backup](https://www.postgresql.org/docs/current/app-pgdump.html)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Disaster Recovery Best Practices](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

## 🆘 Support

For backup and disaster recovery support:

1. **Check logs**: `kubectl logs -n todo-app -l purpose=backup`
2. **Run tests**: `./scripts/test-backup.sh`
3. **Review status**: `./scripts/disaster-recovery.sh status`
4. **Check documentation**: This guide and inline help
5. **Contact team**: DevOps/SRE team for complex issues

---

**Last Updated**: $(date)
**Version**: 1.0
**Maintainer**: DevOps Team
