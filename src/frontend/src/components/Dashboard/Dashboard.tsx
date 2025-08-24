import React, { useEffect, useState } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Chip,
  LinearProgress,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Assignment as TodoIcon,
  CheckCircle as CompletedIcon,
  Schedule as PendingIcon,
  PriorityHigh as HighPriorityIcon,
  Warning as OverdueIcon,
} from '@mui/icons-material';
import { TodoStatistics, Todo } from '../../types/Todo';
import { todoApi } from '../../services/todoApi';

const Dashboard: React.FC = () => {
  const [statistics, setStatistics] = useState<TodoStatistics | null>(null);
  const [recentTodos, setRecentTodos] = useState<Todo[]>([]);
  const [overdueTodos, setOverdueTodos] = useState<Todo[]>([]);
  const [highPriorityTodos, setHighPriorityTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        const [stats, recent, overdue, highPriority] = await Promise.all([
          todoApi.getTodoStatistics(),
          todoApi.getTodos(0, 5, 'createdAt', 'desc'),
          todoApi.getOverdueTodos(),
          todoApi.getHighPriorityIncompleteTodos(),
        ]);

        setStatistics(stats);
        setRecentTodos(recent.content);
        setOverdueTodos(overdue);
        setHighPriorityTodos(highPriority);
        setError(null);
      } catch (err) {
        setError('Failed to load dashboard data');
        console.error('Dashboard error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return <Alert severity="error">{error}</Alert>;
  }

  const StatCard: React.FC<{
    title: string;
    value: number;
    icon: React.ReactNode;
    color: string;
    subtitle?: string;
  }> = ({ title, value, icon, color, subtitle }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box>
            <Typography color="textSecondary" gutterBottom variant="h6">
              {title}
            </Typography>
            <Typography variant="h4" component="div" sx={{ color }}>
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="body2" color="textSecondary">
                {subtitle}
              </Typography>
            )}
          </Box>
          <Box sx={{ color, fontSize: '2rem' }}>
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  const PriorityChip: React.FC<{ priority: string }> = ({ priority }) => {
    const getPriorityColor = (priority: string) => {
      switch (priority) {
        case 'URGENT': return 'error';
        case 'HIGH': return 'warning';
        case 'MEDIUM': return 'info';
        case 'LOW': return 'default';
        default: return 'default';
      }
    };

    return (
      <Chip
        label={priority}
        size="small"
        color={getPriorityColor(priority) as any}
        variant="outlined"
      />
    );
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>

      {/* Statistics Cards */}
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' }, gap: 3, mb: 4 }}>
        <StatCard
          title="Total Todos"
          value={statistics?.totalTodos || 0}
          icon={<TodoIcon />}
          color="#1976d2"
        />
        <StatCard
          title="Completed"
          value={statistics?.completedTodos || 0}
          icon={<CompletedIcon />}
          color="#2e7d32"
          subtitle={`${statistics?.completionRate.toFixed(1) || 0}%`}
        />
        <StatCard
          title="Pending"
          value={statistics?.incompleteTodos || 0}
          icon={<PendingIcon />}
          color="#ed6c02"
        />
        <StatCard
          title="Overdue"
          value={statistics?.overdueTodos || 0}
          icon={<OverdueIcon />}
          color="#d32f2f"
        />
      </Box>

      {/* Completion Progress */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Completion Progress
          </Typography>
          <Box display="flex" alignItems="center" gap={2}>
            <Box flexGrow={1}>
              <LinearProgress
                variant="determinate"
                value={statistics?.completionRate || 0}
                sx={{ height: 10, borderRadius: 5 }}
              />
            </Box>
            <Typography variant="body2" color="textSecondary">
              {statistics?.completionRate.toFixed(1) || 0}%
            </Typography>
          </Box>
        </CardContent>
      </Card>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)' }, gap: 3 }}>
        {/* Recent Todos */}
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Recent Todos
            </Typography>
            {recentTodos.length === 0 ? (
              <Typography color="textSecondary">No todos yet</Typography>
            ) : (
              recentTodos.map((todo) => (
                <Box key={todo.id} sx={{ mb: 2, p: 2, border: '1px solid #e0e0e0', borderRadius: 1 }}>
                  <Box display="flex" justifyContent="space-between" alignItems="flex-start">
                    <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>
                      {todo.title}
                    </Typography>
                    <PriorityChip priority={todo.priority} />
                  </Box>
                  {todo.description && (
                    <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
                      {todo.description}
                    </Typography>
                  )}
                  <Box display="flex" gap={1} sx={{ mt: 1 }}>
                    <Chip
                      label={todo.completed ? 'Completed' : 'Pending'}
                      size="small"
                      color={todo.completed ? 'success' : 'default'}
                      variant="outlined"
                    />
                    {todo.dueDate && (
                      <Chip
                        label={`Due: ${new Date(todo.dueDate).toLocaleDateString()}`}
                        size="small"
                        variant="outlined"
                      />
                    )}
                  </Box>
                </Box>
              ))
            )}
          </CardContent>
        </Card>

        {/* High Priority & Overdue */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                High Priority Todos
              </Typography>
              {highPriorityTodos.length === 0 ? (
                <Typography color="textSecondary">No high priority todos</Typography>
              ) : (
                highPriorityTodos.slice(0, 3).map((todo) => (
                  <Box key={todo.id} sx={{ mb: 2, p: 2, border: '1px solid #ff9800', borderRadius: 1, backgroundColor: '#fff3e0' }}>
                    <Typography variant="subtitle2" sx={{ fontWeight: 'bold' }}>
                      {todo.title}
                    </Typography>
                    <Box display="flex" gap={1} sx={{ mt: 1 }}>
                      <PriorityChip priority={todo.priority} />
                      {todo.dueDate && (
                        <Chip
                          label={`Due: ${new Date(todo.dueDate).toLocaleDateString()}`}
                          size="small"
                          color="warning"
                          variant="outlined"
                        />
                      )}
                    </Box>
                  </Box>
                ))
              )}
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Overdue Todos
              </Typography>
              {overdueTodos.length === 0 ? (
                <Typography color="textSecondary">No overdue todos</Typography>
              ) : (
                overdueTodos.slice(0, 3).map((todo) => (
                  <Box key={todo.id} sx={{ mb: 2, p: 2, border: '1px solid #f44336', borderRadius: 1, backgroundColor: '#ffebee' }}>
                    <Typography variant="subtitle2" sx={{ fontWeight: 'bold' }}>
                      {todo.title}
                    </Typography>
                    <Box display="flex" gap={1} sx={{ mt: 1 }}>
                      <PriorityChip priority={todo.priority} />
                      <Chip
                        label={`Overdue since: ${new Date(todo.dueDate!).toLocaleDateString()}`}
                        size="small"
                        color="error"
                        variant="outlined"
                      />
                    </Box>
                  </Box>
                ))
              )}
            </CardContent>
          </Card>
        </Box>
      </Box>
    </Box>
  );
};

export default Dashboard;
