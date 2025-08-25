import React, { useEffect, useState, useCallback } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  Chip,
} from '@mui/material';
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker';
import { useNavigate, useParams } from 'react-router-dom';
import dayjs, { Dayjs } from 'dayjs';
import { TodoFormData, Priority } from '../../types/Todo';
import { todoApi } from '../../services/todoApi';

const TodoForm: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const isEditing = Boolean(id);

  const [formData, setFormData] = useState<TodoFormData>({
    title: '',
    description: '',
    priority: Priority.MEDIUM,
    dueDate: undefined,
  });

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  const fetchTodo = useCallback(async () => {
    try {
      setLoading(true);
      const todo = await todoApi.getTodoById(parseInt(id!));
      setFormData({
        title: todo.title,
        description: todo.description || '',
        priority: todo.priority,
        dueDate: todo.dueDate || undefined,
      });
    } catch (err) {
      setError('Failed to load todo');
      console.error('Error fetching todo:', err);
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    if (isEditing) {
      fetchTodo();
    }
  }, [isEditing, fetchTodo]);

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};

    if (!formData.title.trim()) {
      errors.title = 'Title is required';
    } else if (formData.title.length > 255) {
      errors.title = 'Title must be less than 255 characters';
    }

    if (formData.description && formData.description.length > 1000) {
      errors.description = 'Description must be less than 1000 characters';
    }

    setValidationErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      setSaving(true);
      setError(null);

      if (isEditing) {
        await todoApi.updateTodo(parseInt(id!), formData);
      } else {
        await todoApi.createTodo(formData);
      }

      navigate('/todos');
    } catch (err) {
      setError('Failed to save todo');
      console.error('Error saving todo:', err);
    } finally {
      setSaving(false);
    }
  };

  const handleInputChange = (field: keyof TodoFormData, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear validation error when user starts typing
    if (validationErrors[field]) {
      setValidationErrors(prev => ({ ...prev, [field]: '' }));
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

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        {isEditing ? 'Edit Todo' : 'New Todo'}
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Card>
        <CardContent>
          <form onSubmit={handleSubmit}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
              {/* Title */}
              <TextField
                fullWidth
                label="Title *"
                value={formData.title}
                onChange={(e) => handleInputChange('title', e.target.value)}
                error={Boolean(validationErrors.title)}
                helperText={validationErrors.title}
                required
              />

              {/* Description */}
              <TextField
                fullWidth
                label="Description"
                value={formData.description}
                onChange={(e) => handleInputChange('description', e.target.value)}
                error={Boolean(validationErrors.description)}
                helperText={validationErrors.description}
                multiline
                rows={4}
                placeholder="Optional description for your todo..."
              />

              {/* Priority and Due Date */}
              <Box sx={{ display: 'flex', gap: 2, flexDirection: { xs: 'column', md: 'row' } }}>
                <FormControl fullWidth>
                  <InputLabel>Priority</InputLabel>
                  <Select
                    value={formData.priority}
                    label="Priority"
                    onChange={(e) => handleInputChange('priority', e.target.value)}
                  >
                    {Object.values(Priority).map((priority) => (
                      <MenuItem key={priority} value={priority}>
                        <Box display="flex" alignItems="center" gap={1}>
                          <Chip
                            label={priority}
                            size="small"
                            color={getPriorityColor(priority) as any}
                            variant="outlined"
                          />
                        </Box>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <DateTimePicker
                  label="Due Date (Optional)"
                  value={formData.dueDate ? dayjs(formData.dueDate) : null}
                  onChange={(newValue: Dayjs | null) => {
                    handleInputChange('dueDate', newValue?.toISOString() || undefined);
                  }}
                  slotProps={{
                    textField: {
                      fullWidth: true,
                      placeholder: 'Select due date and time...',
                    },
                  }}
                  minDateTime={dayjs()}
                />
              </Box>

              {/* Priority Info */}
              <Box display="flex" gap={1} flexWrap="wrap">
                <Chip
                  label="LOW - No rush, can be done later"
                  size="small"
                  color="default"
                  variant="outlined"
                />
                <Chip
                  label="MEDIUM - Normal priority"
                  size="small"
                  color="info"
                  variant="outlined"
                />
                <Chip
                  label="HIGH - Important, needs attention"
                  size="small"
                  color="warning"
                  variant="outlined"
                />
                <Chip
                  label="URGENT - Critical, must be done ASAP"
                  size="small"
                  color="error"
                  variant="outlined"
                />
              </Box>

              {/* Actions */}
              <Box display="flex" gap={2} justifyContent="flex-end">
                <Button
                  variant="outlined"
                  onClick={() => navigate('/todos')}
                  disabled={saving}
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="contained"
                  disabled={saving}
                  startIcon={saving ? <CircularProgress size={20} /> : null}
                >
                  {saving ? 'Saving...' : (isEditing ? 'Update Todo' : 'Create Todo')}
                </Button>
              </Box>
            </Box>
          </form>
        </CardContent>
      </Card>
    </Box>
  );
};

export default TodoForm;
