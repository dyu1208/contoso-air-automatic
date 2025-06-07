# Use Node.js 22 as specified in prerequisites
FROM node:22-slim

# Install necessary system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files first for better layer caching
COPY src/web/package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application source code
COPY src/web/ ./

# Create non-root user for security
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

# Change ownership to nodejs user
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]