
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

RUN pnpm install --frozen-lockfile --filter api...

# Génération Prisma + compilation des packages partagés
RUN pnpm run generer

# Compilation API
RUN pnpm --filter api build

# --------------------------------------------------
# Dépendances de production
# --------------------------------------------------
FROM base AS production-deps

COPY . .

RUN pnpm install \
    --prod \
    --frozen-lockfile \
    --filter api...

# --------------------------------------------------
# Image finale
# --------------------------------------------------
FROM node:24-bookworm-slim AS runtime

ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Dépendances
COPY --from=production-deps --chown=node:node /app/node_modules ./node_modules

COPY --from=production-deps --chown=node:node /app/apps/api/node_modules ./apps/api/node_modules

COPY --from=production-deps --chown=node:node /app/packages/database/node_modules ./packages/database/node_modules

# Manifests
COPY --from=production-deps --chown=node:node /app/apps/api/package.json ./apps/api/package.json

COPY --from=production-deps --chown=node:node /app/packages/database/package.json ./packages/database/package.json

COPY --from=production-deps --chown=node:node /app/packages/contrats/package.json ./packages/contrats/package.json

# Builds
COPY --from=build --chown=node:node /app/apps/api/dist ./apps/api/dist

COPY --from=build --chown=node:node /app/packages/database/dist ./packages/database/dist

COPY --from=build --chown=node:node /app/packages/contrats/dist ./packages/contrats/dist

# Données OCR (Tesseract) embarquées : évite un téléchargement au premier KYC.
# Le dossier doit appartenir à node : Tesseract y écrit son cache.
COPY --from=build --chown=node:node /app/apps/api/fra.traineddata ./apps/api/fra.traineddata
RUN chown node:node /app/apps/api

# Port documentaire uniquement
EXPOSE 3000

USER node

WORKDIR /app/apps/api

CMD ["node", "dist/main.js"]
