import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  TablePagination,
  Alert,
  CircularProgress,
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckIcon,
  RadioButtonUnchecked as UncheckIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { Todo, Priority, TodoFilters } from '../../types/Todo';
import { todoApi } from '../../services/todoApi';

const TodoList: React.FC = () => {
  const navigate = useNavigate();
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [totalElements, setTotalElements] = useState(0);
  const [filters, setFilters] = useState<TodoFilters>({});
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchTodos();
  }, [page, rowsPerPage, filters]);

  const fetchTodos = async () => {
    try {
      setLoading(true);
      const response = await todoApi.getTodos(page, rowsPerPage, 'createdAt', 'desc');
      setTodos(response.content);
      setTotalElements(response.totalElements);
      setError(null);
    } catch (err) {
      setError('Failed to load todos');
      console.error('Error fetching todos:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (searchTerm.trim()) {
      try {
        const results = await todoApi.searchTodos(searchTerm);
        setTodos(results);
        setTotalElements(results.length);
        setPage(0);
      } catch (err) {
        setError('Search failed');
      }
    } else {
      fetchTodos();
    }
  };

  const handleFilterChange = (filterType: keyof TodoFilters, value: any) => {
    setFilters(prev => ({ ...prev, [filterType]: value }));
    setPage(0);
  };

  const handleStatusToggle = async (todo: Todo) => {
    try {
      if (todo.completed) {
        await todoApi.markAsIncomplete(todo.id);
      } else {
        await todoApi.markAsCompleted(todo.id);
      }
      fetchTodos(); // Refresh the list
    } catch (err) {
      setError('Failed to update todo status');
    }
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this todo?')) {
      try {
        await todoApi.deleteTodo(id);
        fetchTodos(); // Refresh the list
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
    return new Date(dateString).toLocaleDateString();
  };

  if (loading && todos.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">All Todos</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => navigate('/todos/new')}
        >
          New Todo
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {/* Filters */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box display="flex" gap={2} flexWrap="wrap" alignItems="center">
            <TextField
              label="Search"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
              size="small"
              sx={{ minWidth: 200 }}
              InputProps={{
                endAdornment: (
                  <IconButton onClick={handleSearch}>
                    <SearchIcon />
                  </IconButton>
                ),
              }}
            />

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Status</InputLabel>
              <Select
                value={filters.completed ?? ''}
                label="Status"
                onChange={(e) => handleFilterChange('completed', e.target.value)}
              >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="false">Pending</MenuItem>
                <MenuItem value="true">Completed</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Priority</InputLabel>
              <Select
                value={filters.priority ?? ''}
                label="Priority"
                onChange={(e) => handleFilterChange('priority', e.target.value)}
              >
                <MenuItem value="">All</MenuItem>
                {Object.values(Priority).map((priority) => (
                  <MenuItem key={priority} value={priority}>
                    {priority}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Button variant="outlined" onClick={() => {
              setFilters({});
              setSearchTerm('');
              setPage(0);
            }}>
              Clear Filters
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Todos Table */}
      <Card>
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Status</TableCell>
                <TableCell>Title</TableCell>
                <TableCell>Description</TableCell>
                <TableCell>Priority</TableCell>
                <TableCell>Due Date</TableCell>
                <TableCell>Created</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {todos.map((todo) => (
                <TableRow key={todo.id} hover>
                  <TableCell>
                    <IconButton
                      onClick={() => handleStatusToggle(todo)}
                      color={todo.completed ? 'success' : 'default'}
                    >
                      {todo.completed ? <CheckIcon /> : <UncheckIcon />}
                    </IconButton>
                  </TableCell>
                  <TableCell>
                    <Typography
                      variant="body1"
                      sx={{
                        fontWeight: 'bold',
                        textDecoration: todo.completed ? 'line-through' : 'none',
                      }}
                    >
                      {todo.title}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography
                      variant="body2"
                      color="textSecondary"
                      sx={{
                        maxWidth: 200,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {todo.description || '-'}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={todo.priority}
                      size="small"
                      color={getPriorityColor(todo.priority) as any}
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    {todo.dueDate ? (
                      <Typography
                        variant="body2"
                        color={new Date(todo.dueDate) < new Date() ? 'error' : 'textSecondary'}
                      >
                        {formatDate(todo.dueDate)}
                      </Typography>
                    ) : (
                      '-'
                    )}
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="textSecondary">
                      {formatDate(todo.createdAt)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Box display="flex" gap={1}>
                      <IconButton
                        size="small"
                        onClick={() => navigate(`/todos/${todo.id}/edit`)}
                        color="primary"
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton
                        size="small"
                        onClick={() => handleDelete(todo.id)}
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          count={totalElements}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[5, 10, 25, 50]}
        />
      </Card>
    </Box>
  );
};

export default TodoList;
