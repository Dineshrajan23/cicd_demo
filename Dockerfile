# Stage 1: Builder stage
FROM node:20-alpine AS builder
WORKDIR /app

ARG NEXT_PUBLIC_API_BASE
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_WS_URL
ARG NEXT_PUBLIC_CHAT_BACKEND_URL
ARG NEXT_PUBLIC_BACKEND_URL

#  environment variables for the build
ENV NEXT_PUBLIC_API_BASE=$NEXT_PUBLIC_API_BASE
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_WS_URL=$NEXT_PUBLIC_WS_URL
ENV NEXT_PUBLIC_CHAT_BACKEND_URL=$NEXT_PUBLIC_CHAT_BACKEND_URL
ENV NEXT_PUBLIC_BACKEND_URL=$NEXT_PUBLIC_BACKEND_URL


COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN sed -i '/const nextConfig: NextConfig = {/a \
  eslint: {\n\
    ignoreDuringBuilds: true,\n\
  },\n\
  typescript: {\n\
    ignoreBuildErrors: true,\n\
  },' next.config.ts

RUN npm run build

# Stage 2: Create a lightweight production image
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

# Re-declare the build-time variables for the production image at runtime
ENV NEXT_PUBLIC_API_BASE=$NEXT_PUBLIC_API_BASE
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_WS_URL=$NEXT_PUBLIC_WS_URL
ENV NEXT_PUBLIC_CHAT_BACKEND_URL=$NEXT_PUBLIC_CHAT_BACKEND_URL
ENV NEXT_PUBLIC_BACKEND_URL=$NEXT_PUBLIC_BACKEND_URL

# Create a non-root user for security (recommended)
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs_user
USER nextjs_user

# Copy only the necessary build artifacts from the builder stage
COPY --from=builder --chown=nextjs_user:nodejs /app/public ./public
COPY --from=builder --chown=nextjs_user:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs_user:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs_user:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs_user:nodejs /app/src/i18n/request.ts ./src/i18n/request.ts

EXPOSE 3000
CMD ["npm", "start"]