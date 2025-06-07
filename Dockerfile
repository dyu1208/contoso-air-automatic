# Use Node.js 22 LTS as the base image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy application source code
COPY src/web/ ./

# Install dependencies
RUN npm install --production

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of the app directory to nodejs user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose the application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (res) => { if(res.statusCode !== 200) process.exit(1) })"

# Start the application
CMD ["npm", "start"]