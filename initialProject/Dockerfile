FROM ghcr.io/diploi/nextjs-postgresql-template-arm64

# Install application code
WORKDIR /app
COPY . .

RUN npm install
RUN npm run build
