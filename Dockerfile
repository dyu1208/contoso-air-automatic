# Use Node.js 22 as specified in prerequisites  
FROM node:22

# Set working directory
WORKDIR /app

# Copy all source code  
COPY src/web/ ./

# Install dependencies (assuming this works in the actual CI environment)
RUN npm install

# Create non-root user for security
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

# Change ownership to nodejs user
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]