FROM node:20-alpine3.20 AS deps 
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat \
    unzip \
    wget \
    python3 \
    py3-pip \
    build-base \
    gcc \
    g++ \
    make

# Use an official Node.js runtime as a parent image

# Set the working directory inside the container
WORKDIR /app

# Copy only package.json and yarn.lock to utilize Docker cache for dependencies installation
#COPY package.json yarn.lock ./
#COPY package.json yarn.lock package-lock.json* pnpm-lock.yaml* ./
#RUN \
#  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
#  elif [ -f package-lock.json ]; then npm ci; \
#  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i; \
#  else echo "Lockfile not found." && exit 1; \
#  fi
# Install dependencies using Yarn
RUN yarn install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:18.15-alpine AS builder 

# Copy the rest of the application code to the working directory
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Build the application if necessary (optional)
RUN yarn build
# Production image, copy all the files and run next
FROM node:18.15-alpine AS runner
WORKDIR /app

#ENV NODE_ENV production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1
# Copy application files from builder stage
COPY --from=builder /app ./

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Expose the port on which the app will run (if applicable)
EXPOSE 3001

# Command to run the application
CMD ["yarn", "start"]


