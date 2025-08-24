#!/bin/bash

# Database Backup and Restore Script for Todo Application
# Usage: ./backup-restore.sh [backup|restore] [filename]

set -e

# Configuration
DB_NAME="tododb"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5433"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if PostgreSQL is running
check_postgres() {
    if ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER > /dev/null 2>&1; then
        print_error "PostgreSQL is not running or not accessible"
        print_error "Please ensure PostgreSQL is running and accessible at $DB_HOST:$DB_PORT"
        exit 1
    fi
}

# Function to create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_status "Created backup directory: $BACKUP_DIR"
    fi
}

# Function to backup database
backup_database() {
    local filename=$1
    
    if [ -z "$filename" ]; then
        filename="todo_backup_${TIMESTAMP}.sql"
    fi
    
    local backup_path="$BACKUP_DIR/$filename"
    
    print_status "Starting database backup..."
    print_status "Database: $DB_NAME"
    print_status "Backup file: $backup_path"
    
    # Create backup
    if pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
        --verbose --clean --create --if-exists \
        --no-owner --no-privileges \
        -f "$backup_path"; then
        print_status "Backup completed successfully!"
        print_status "Backup size: $(du -h "$backup_path" | cut -f1)"
        print_status "Backup location: $backup_path"
    else
        print_error "Backup failed!"
        exit 1
    fi
}

# Function to restore database
restore_database() {
    local filename=$1
    
    if [ -z "$filename" ]; then
        print_error "Please specify a backup file to restore from"
        print_error "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    local backup_path="$BACKUP_DIR/$filename"
    
    if [ ! -f "$backup_path" ]; then
        print_error "Backup file not found: $backup_path"
        exit 1
    fi
    
    print_warning "This will completely replace the current database!"
    print_warning "Database: $DB_NAME"
    print_warning "Backup file: $filename"
    
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    print_status "Starting database restore..."
    
    # Drop and recreate database
    print_status "Dropping existing database..."
    dropdb -h $DB_HOST -p $DB_PORT -U $DB_USER --if-exists "$DB_NAME"
    
    print_status "Creating new database..."
    createdb -h $DB_HOST -p $DB_PORT -U $DB_USER "$DB_NAME"
    
    # Restore from backup
    print_status "Restoring from backup..."
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$backup_path"; then
        print_status "Restore completed successfully!"
        print_status "Database: $DB_NAME has been restored from: $filename"
    else
        print_error "Restore failed!"
        exit 1
    fi
}

# Function to list available backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
        print_warning "No backups found in $BACKUP_DIR"
        return
    fi
    
    print_status "Available backups:"
    echo
    for backup in "$BACKUP_DIR"/*.sql; do
        if [ -f "$backup" ]; then
            local size=$(du -h "$backup" | cut -f1)
            local date=$(stat -c %y "$backup" | cut -d' ' -f1)
            local time=$(stat -c %y "$backup" | cut -d' ' -f2 | cut -d'.' -f1)
            echo "  $(basename "$backup") - ${size} - ${date} ${time}"
        fi
    done
    echo
}

# Function to show help
show_help() {
    echo "Database Backup and Restore Script for Todo Application"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  backup [filename]    Create a database backup"
    echo "  restore <filename>   Restore database from backup"
    echo "  list                 List available backups"
    echo "  help                 Show this help message"
    echo
    echo "Examples:"
    echo "  $0 backup                           # Create backup with timestamp"
    echo "  $0 backup my_backup.sql            # Create backup with custom name"
    echo "  $0 restore todo_backup_20231201_143022.sql"
    echo "  $0 list                            # List available backups"
    echo
    echo "Configuration:"
    echo "  Database: $DB_NAME"
    echo "  Host: $DB_HOST:$DB_PORT"
    echo "  User: $DB_USER"
    echo "  Backup directory: $BACKUP_DIR"
}

# Main script logic
main() {
    local command=$1
    local filename=$2
    
    case $command in
        "backup")
            check_postgres
            create_backup_dir
            backup_database "$filename"
            ;;
        "restore")
            check_postgres
            create_backup_dir
            restore_database "$filename"
            ;;
        "list")
            list_backups
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
