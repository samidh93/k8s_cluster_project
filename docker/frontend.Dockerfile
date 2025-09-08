# Multi-stage build: Build React app first
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY src/frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src/frontend/ ./

# Build the React app
RUN npm run build

# Production stage: Use nginx to serve the built app
FROM nginx:alpine

# Copy built frontend from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy nginx configuration for React Router
COPY docker/nginx-frontend.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
