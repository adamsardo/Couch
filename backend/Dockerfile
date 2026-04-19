# --- build stage -----------------------------------------------------------
FROM node:22-slim AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# --- runtime stage ---------------------------------------------------------
FROM node:22-slim AS runtime

ENV NODE_ENV=production
WORKDIR /app

# We keep tsx for dev parity with `npm run agent`, but production uses dist/.
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund

COPY --from=build /app/dist ./dist

EXPOSE 8787
# Default to the token server. Override the CMD when running the agent:
#   docker run ... couch-backend node dist/agent.js start
CMD ["node", "dist/token-server.js"]
