
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Create a lightweight production image
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
# For better security, run as a non-root user (optional but recommended)
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs_user
USER nextjs_user
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
EXPOSE 3000
CMD ["npm", "start"]