# Use lightweight nginx for serving React app
FROM nginx:alpine

# Copy pre-built frontend
COPY src/frontend/build /usr/share/nginx/html

# Copy nginx configuration for React Router
COPY docker/nginx-frontend.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
