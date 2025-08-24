-- PostgreSQL Database Initialization Script for Todo Application
-- This script creates the database, user, and initial schema

-- Create database (run as postgres superuser)
-- CREATE DATABASE tododb;

-- Connect to the tododb database before running the rest
-- \c tododb;

-- Create application user (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'todoapp') THEN
        CREATE USER todoapp WITH PASSWORD 'todoapp_password';
    END IF;
END
$$;

-- Grant privileges to the application user
GRANT CONNECT ON DATABASE tododb TO todoapp;
GRANT USAGE ON SCHEMA public TO todoapp;
GRANT CREATE ON SCHEMA public TO todoapp;

-- Create todos table
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    due_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at);
CREATE INDEX IF NOT EXISTS idx_todos_title ON todos USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_todos_description ON todos USING gin(to_tsvector('english', description));

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_todos_updated_at 
    BEFORE UPDATE ON todos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions to the application user
GRANT ALL PRIVILEGES ON TABLE todos TO todoapp;
GRANT USAGE, SELECT ON SEQUENCE todos_id_seq TO todoapp;

-- Insert some sample data for testing
INSERT INTO todos (title, description, priority, due_date) VALUES
    ('Complete project documentation', 'Write comprehensive documentation for the Todo application project', 'HIGH', CURRENT_TIMESTAMP + INTERVAL '3 days'),
    ('Review code changes', 'Go through all recent code changes and provide feedback', 'MEDIUM', CURRENT_TIMESTAMP + INTERVAL '1 day'),
    ('Setup monitoring', 'Configure Prometheus and Grafana dashboards', 'URGENT', CURRENT_TIMESTAMP + INTERVAL '6 hours'),
    ('Write unit tests', 'Create comprehensive test coverage for backend services', 'HIGH', CURRENT_TIMESTAMP + INTERVAL '2 days'),
    ('Deploy to staging', 'Deploy the application to staging environment for testing', 'MEDIUM', CURRENT_TIMESTAMP + INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Create view for overdue todos
CREATE OR REPLACE VIEW overdue_todos AS
SELECT * FROM todos 
WHERE due_date < CURRENT_TIMESTAMP 
AND completed = FALSE 
AND due_date IS NOT NULL;

-- Create view for todos due today
CREATE OR REPLACE VIEW todos_due_today AS
SELECT * FROM todos 
WHERE DATE(due_date) = CURRENT_DATE 
AND completed = FALSE 
AND due_date IS NOT NULL;

-- Create view for high priority incomplete todos
CREATE OR REPLACE VIEW high_priority_todos AS
SELECT * FROM todos 
WHERE priority IN ('HIGH', 'URGENT') 
AND completed = FALSE;

-- Grant permissions on views
GRANT SELECT ON overdue_todos TO todoapp;
GRANT SELECT ON todos_due_today TO todoapp;
GRANT SELECT ON high_priority_todos TO todoapp;

-- Create function to get todo statistics
CREATE OR REPLACE FUNCTION get_todo_statistics()
RETURNS TABLE(
    total_todos BIGINT,
    completed_todos BIGINT,
    incomplete_todos BIGINT,
    overdue_todos BIGINT,
    high_priority_todos BIGINT,
    completion_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_todos,
        COUNT(*) FILTER (WHERE completed = TRUE)::BIGINT as completed_todos,
        COUNT(*) FILTER (WHERE completed = FALSE)::BIGINT as incomplete_todos,
        COUNT(*) FILTER (WHERE due_date < CURRENT_TIMESTAMP AND completed = FALSE AND due_date IS NOT NULL)::BIGINT as overdue_todos,
        COUNT(*) FILTER (WHERE priority IN ('HIGH', 'URGENT') AND completed = FALSE)::BIGINT as high_priority_todos,
        ROUND(
            (COUNT(*) FILTER (WHERE completed = TRUE)::NUMERIC / COUNT(*)::NUMERIC) * 100, 
            1
        ) as completion_rate
    FROM todos;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_todo_statistics() TO todoapp;

-- Create function to search todos
CREATE OR REPLACE FUNCTION search_todos(search_term TEXT)
RETURNS TABLE(
    id BIGINT,
    title VARCHAR(255),
    description TEXT,
    completed BOOLEAN,
    priority VARCHAR(20),
    due_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.title, t.description, t.completed, t.priority, t.due_date, t.created_at, t.updated_at
    FROM todos t
    WHERE 
        to_tsvector('english', COALESCE(t.title, '') || ' ' || COALESCE(t.description, '')) @@ plainto_tsquery('english', search_term)
        OR t.title ILIKE '%' || search_term || '%'
        OR t.description ILIKE '%' || search_term || '%'
    ORDER BY 
        ts_rank(to_tsvector('english', COALESCE(t.title, '') || ' ' || COALESCE(t.description, '')), plainto_tsquery('english', search_term)) DESC,
        t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the search function
GRANT EXECUTE ON FUNCTION search_todos(TEXT) TO todoapp;

-- Display created objects
\echo 'Database schema created successfully!'
\echo 'Tables: todos'
\echo 'Views: overdue_todos, todos_due_today, high_priority_todos'
\echo 'Functions: update_updated_at_column(), get_todo_statistics(), search_todos()'
\echo 'Triggers: update_todos_updated_at'
\echo 'Indexes: Multiple performance indexes created'
\echo 'Sample data: 5 sample todos inserted'
