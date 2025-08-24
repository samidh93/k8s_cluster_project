export interface Todo {
  id: number;
  title: string;
  description?: string;
  completed: boolean;
  createdAt: string; // ISO date string
  updatedAt: string; // ISO date string
  dueDate?: string; // ISO date string
  priority: Priority;
}

export enum Priority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT'
}

export interface TodoFormData {
  title: string;
  description?: string;
  dueDate?: string;
  priority: Priority;
}

export interface TodoStatistics {
  totalTodos: number;
  completedTodos: number;
  incompleteTodos: number;
  overdueTodos: number;
  highPriorityTodos: number;
  completionRate: number;
}

export interface TodoFilters {
  completed?: boolean;
  priority?: Priority;
  search?: string;
  dueDate?: string;
}

export interface PaginatedTodos {
  content: Todo[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}
