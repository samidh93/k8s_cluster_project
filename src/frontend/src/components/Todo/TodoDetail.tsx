import React, { useEffect, useState, useCallback } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  Alert,
  CircularProgress,
  IconButton,
  Divider,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckIcon,
  RadioButtonUnchecked as UncheckIcon,
  ArrowBack as BackIcon,
} from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import { Todo } from '../../types/Todo';
import { todoApi } from '../../services/todoApi';

const TodoDetail: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [todo, setTodo] = useState<Todo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [updating, setUpdating] = useState(false);

  const fetchTodo = useCallback(async () => {
    try {
      setLoading(true);
      const todoData = await todoApi.getTodoById(parseInt(id!));
      setTodo(todoData);
      setError(null);
    } catch (err) {
      setError('Failed to load todo');
      console.error('Error fetching todo:', err);
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    if (id) {
      fetchTodo();
    }
  }, [id, fetchTodo]);

  const handleStatusToggle = async () => {
    if (!todo) return;

    try {
      setUpdating(true);
      if (todo.completed) {
        await todoApi.markAsIncomplete(todo.id);
      } else {
        await todoApi.markAsCompleted(todo.id);
      }
      fetchTodo(); // Refresh the todo data
    } catch (err) {
      setError('Failed to update todo status');
    } finally {
      setUpdating(false);
    }
  };

  const handleDelete = async () => {
    if (!todo) return;

    if (window.confirm('Are you sure you want to delete this todo?')) {
      try {
        await todoApi.deleteTodo(todo.id);
        navigate('/todos');
      } catch (err) {
        setError('Failed to delete todo');
      }
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'URGENT': return 'error';
      case 'HIGH': return 'warning';
      case 'MEDIUM': return 'info';
      case 'LOW': return 'default';
      default: return 'default';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const isOverdue = (dueDate: string) => {
    return new Date(dueDate) < new Date();
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error || !todo) {
    return <Alert severity="error">{error || 'Todo not found'}</Alert>;
  }

  return (
    <Box>
      {/* Header */}
      <Box display="flex" alignItems="center" gap={2} mb={3}>
        <IconButton onClick={() => navigate('/todos')} color="primary">
          <BackIcon />
        </IconButton>
        <Typography variant="h4">Todo Details</Typography>
      </Box>

      <Card>
        <CardContent>
          {/* Title and Status */}
          <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={3}>
            <Box flexGrow={1}>
              <Typography
                variant="h5"
                sx={{
                  fontWeight: 'bold',
                  textDecoration: todo.completed ? 'line-through' : 'none',
                  color: todo.completed ? 'text.secondary' : 'text.primary',
                }}
              >
                {todo.title}
              </Typography>
              <Box display="flex" gap={1} mt={1}>
                <Chip
                  label={todo.completed ? 'Completed' : 'Pending'}
                  color={todo.completed ? 'success' : 'default'}
                  variant="outlined"
                />
                <Chip
                  label={todo.priority}
                  color={getPriorityColor(todo.priority) as any}
                  variant="outlined"
                />
              </Box>
            </Box>
            <Box display="flex" gap={1}>
              <IconButton
                onClick={handleStatusToggle}
                color={todo.completed ? 'success' : 'default'}
                disabled={updating}
              >
                {todo.completed ? <CheckIcon /> : <UncheckIcon />}
              </IconButton>
              <IconButton
                onClick={() => navigate(`/todos/${todo.id}/edit`)}
                color="primary"
              >
                <EditIcon />
              </IconButton>
              <IconButton
                onClick={handleDelete}
                color="error"
              >
                <DeleteIcon />
              </IconButton>
            </Box>
          </Box>

          <Divider sx={{ my: 2 }} />

          {/* Description */}
          {todo.description && (
            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                Description
              </Typography>
              <Typography variant="body1" color="text.secondary">
                {todo.description}
              </Typography>
            </Box>
          )}

          {/* Due Date */}
          {todo.dueDate && (
            <Box mb={3}>
              <Typography variant="h6" gutterBottom>
                Due Date
              </Typography>
              <Typography
                variant="body1"
                color={isOverdue(todo.dueDate) ? 'error' : 'text.secondary'}
                sx={{ fontWeight: isOverdue(todo.dueDate) ? 'bold' : 'normal' }}
              >
                {formatDate(todo.dueDate)}
                {isOverdue(todo.dueDate) && !todo.completed && (
                  <Chip
                    label="OVERDUE"
                    color="error"
                    size="small"
                    sx={{ ml: 1 }}
                  />
                )}
              </Typography>
            </Box>
          )}

          <Divider sx={{ my: 2 }} />

          {/* Metadata */}
          <Box display="flex" gap={4} flexWrap="wrap">
            <Box>
              <Typography variant="body2" color="text.secondary">
                Created
              </Typography>
              <Typography variant="body1">
                {formatDate(todo.createdAt)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">
                Last Updated
              </Typography>
              <Typography variant="body1">
                {formatDate(todo.updatedAt)}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">
                ID
              </Typography>
              <Typography variant="body1" fontFamily="monospace">
                #{todo.id}
              </Typography>
            </Box>
          </Box>

          {/* Actions */}
          <Box display="flex" gap={2} mt={4}>
            <Button
              variant="outlined"
              onClick={() => navigate('/todos')}
            >
              Back to List
            </Button>
            <Button
              variant="contained"
              onClick={() => navigate(`/todos/${todo.id}/edit`)}
              startIcon={<EditIcon />}
            >
              Edit Todo
            </Button>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default TodoDetail;
