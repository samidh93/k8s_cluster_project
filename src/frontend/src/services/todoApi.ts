import axios from 'axios';
import { Todo, TodoFormData, TodoStatistics, PaginatedTodos } from '../types/Todo';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080/api';

// Create axios instance with default config
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

// Request interceptor for logging
apiClient.interceptors.request.use(
  (config) => {
    console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

export const todoApi = {
  // Get all todos with pagination
  getTodos: async (page: number = 0, size: number = 10, sortBy: string = 'id', sortDir: string = 'desc'): Promise<PaginatedTodos> => {
    const response = await apiClient.get('/todos', {
      params: { page, size, sortBy, sortDir }
    });
    return response.data;
  },

  // Get all todos without pagination
  getAllTodos: async (): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/all');
    return response.data;
  },

  // Get todo by ID
  getTodoById: async (id: number): Promise<Todo> => {
    const response = await apiClient.get(`/todos/${id}`);
    return response.data;
  },

  // Create new todo
  createTodo: async (todoData: TodoFormData): Promise<Todo> => {
    const response = await apiClient.post('/todos', todoData);
    return response.data;
  },

  // Update existing todo
  updateTodo: async (id: number, todoData: Partial<TodoFormData>): Promise<Todo> => {
    const response = await apiClient.put(`/todos/${id}`, todoData);
    return response.data;
  },

  // Delete todo
  deleteTodo: async (id: number): Promise<void> => {
    await apiClient.delete(`/todos/${id}`);
  },

  // Mark todo as completed
  markAsCompleted: async (id: number): Promise<Todo> => {
    const response = await apiClient.patch(`/todos/${id}/complete`);
    return response.data;
  },

  // Mark todo as incomplete
  markAsIncomplete: async (id: number): Promise<Todo> => {
    const response = await apiClient.patch(`/todos/${id}/incomplete`);
    return response.data;
  },

  // Get todos by completion status
  getTodosByStatus: async (completed: boolean): Promise<Todo[]> => {
    const response = await apiClient.get(`/todos/status/${completed}`);
    return response.data;
  },

  // Get todos by priority
  getTodosByPriority: async (priority: string): Promise<Todo[]> => {
    const response = await apiClient.get(`/todos/priority/${priority}`);
    return response.data;
  },

  // Search todos
  searchTodos: async (searchTerm: string): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/search', {
      params: { q: searchTerm }
    });
    return response.data;
  },

  // Get overdue todos
  getOverdueTodos: async (): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/overdue');
    return response.data;
  },

  // Get todos due today
  getTodosDueToday: async (): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/due-today');
    return response.data;
  },

  // Get todos due this week
  getTodosDueThisWeek: async (): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/due-this-week');
    return response.data;
  },

  // Get high priority incomplete todos
  getHighPriorityIncompleteTodos: async (): Promise<Todo[]> => {
    const response = await apiClient.get('/todos/high-priority');
    return response.data;
  },

  // Get todo statistics
  getTodoStatistics: async (): Promise<TodoStatistics> => {
    const response = await apiClient.get('/todos/statistics');
    return response.data;
  },

  // Health check
  healthCheck: async (): Promise<string> => {
    const response = await apiClient.get('/todos/health');
    return response.data;
  },
};

export default todoApi;
