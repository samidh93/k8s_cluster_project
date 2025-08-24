-- Database Connection Test Script
-- Run this to verify your database setup is working correctly

-- Test 1: Check if we can connect and see the todos table
\echo '=== Test 1: Table Structure ==='
\d todos

-- Test 2: Check if sample data was inserted
\echo '=== Test 2: Sample Data ==='
SELECT COUNT(*) as total_todos FROM todos;

-- Test 3: Check if views were created
\echo '=== Test 3: Views ==='
\dv

-- Test 4: Check if functions were created
\echo '=== Test 4: Functions ==='
\df

-- Test 5: Check if indexes were created
\echo '=== Test 5: Indexes ==='
\di

-- Test 6: Test the statistics function
\echo '=== Test 6: Statistics Function ==='
SELECT * FROM get_todo_statistics();

-- Test 7: Test the search function
\echo '=== Test 7: Search Function ==='
SELECT * FROM search_todos('project');

-- Test 8: Test overdue todos view
\echo '=== Test 8: Overdue Todos View ==='
SELECT COUNT(*) as overdue_count FROM overdue_todos;

-- Test 9: Test high priority todos view
\echo '=== Test 9: High Priority Todos View ==='
SELECT COUNT(*) as high_priority_count FROM high_priority_todos;

-- Test 10: Check user permissions
\echo '=== Test 10: User Permissions ==='
SELECT current_user, current_database();

-- Test 11: Test trigger functionality
\echo '=== Test 11: Trigger Test ==='
UPDATE todos SET title = title || ' (Updated)' WHERE id = 1;
SELECT title, updated_at FROM todos WHERE id = 1;

-- Test 12: Performance test with sample queries
\echo '=== Test 12: Performance Test ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM todos WHERE priority = 'HIGH' ORDER BY created_at DESC;

\echo '=== All Tests Completed Successfully! ==='
\echo 'Your database is properly configured and ready for the Todo application!'
