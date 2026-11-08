
# --------------------------------------------------
# Base commune
# --------------------------------------------------
FROM node:24-bookworm-slim AS base

WORKDIR /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install --global pnpm@12.4.1

# --------------------------------------------------
# Build
# --------------------------------------------------
FROM base AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       python3 \
       make \
       g++ \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN pnpm install --frozen-lockfile --filter worker...

RUN pnpm run generer

RUN pnpm --filter worker build

# --------------------------------------------------
# Dépendances de production
# --------------------------------------------------
FROM base AS production-deps

COPY . .

RUN pnpm install \
    --prod \
    --frozen-lockfile \
    --filter worker...

# --------------------------------------------------
# Image finale
# --------------------------------------------------
FROM node:24-bookworm-slim AS runtime

ENV NODE_ENV=production

WORKDIR /app

COPY --from=production-deps --chown=node:node /app/node_modules ./node_modules

COPY --from=production-deps --chown=node:node /app/apps/worker/node_modules ./apps/worker/node_modules

COPY --from=production-deps --chown=node:node /app/packages/database/node_modules ./packages/database/node_modules

COPY --from=production-deps --chown=node:node /app/apps/worker/package.json ./apps/worker/package.json

COPY --from=production-deps --chown=node:node /app/packages/database/package.json ./packages/database/package.json

COPY --from=production-deps --chown=node:node /app/packages/contrats/package.json ./packages/contrats/package.json

COPY --from=build --chown=node:node /app/apps/worker/dist ./apps/worker/dist

COPY --from=build --chown=node:node /app/packages/database/dist ./packages/database/dist

COPY --from=build --chown=node:node /app/packages/contrats/dist ./packages/contrats/dist

USER node

WORKDIR /app/apps/worker

CMD ["node", "dist/main.js"]
