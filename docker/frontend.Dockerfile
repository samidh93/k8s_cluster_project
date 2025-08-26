# Use Node.js runtime for serving React app
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY src/frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy pre-built frontend
COPY src/frontend/build ./build

# Install serve package for production serving
RUN npm install -g serve

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start the React app
CMD ["serve", "-s", "build", "-l", "80"]
