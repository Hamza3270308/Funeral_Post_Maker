FROM node:22-slim

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy the rest of the backend source code (including public/flowers)
COPY . .

# Ensure uploads directory exists
RUN mkdir -p uploads

EXPOSE 5001

CMD ["npm", "start"]
