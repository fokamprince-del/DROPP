
#!/usr/bin/env bash
set -Eeuo pipefail

# Configuration fixe du serveur.
APP_DIR="/opt/dropp"
ENV_FILE="/etc/dropp/.env.production"
COMPOSE_FILE="$APP_DIR/compose.production.yml"
STATE_DIR="/var/lib/dropp"
ACTIVE_SHA_FILE="$STATE_DIR/active-sha"
LOCK_FILE="/var/lock/dropp-deploy.lock"

# Paramètre strictement validé.
SHA="${1:-}"

if [[ ! "$SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Erreur : SHA invalide"
  exit 1
fi

# Le propriétaire GHCR est défini par l'administrateur.
source /etc/dropp/deploy.conf

if [[ ! "$GHCR_OWNER" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Erreur : propriétaire GHCR invalide"
  exit 1
fi

mkdir -p "$STATE_DIR"

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
  echo "Un autre déploiement est déjà en cours"
  exit 1
fi

export DROPP_API_IMAGE="ghcr.io/$GHCR_OWNER/dropp-api:$SHA"
export DROPP_WORKER_IMAGE="ghcr.io/$GHCR_OWNER/dropp-worker:$SHA"
export DROPP_MIGRATIONS_IMAGE="ghcr.io/$GHCR_OWNER/dropp-migrations:$SHA"

COMPOSE=(
  docker compose
  --env-file "$ENV_FILE"
  -f "$COMPOSE_FILE"
)

PREVIOUS_SHA=""

if [[ -f "$ACTIVE_SHA_FILE" ]]; then
  PREVIOUS_SHA="$(cat "$ACTIVE_SHA_FILE")"
fi

echo "Téléchargement des images $SHA"

"${COMPOSE[@]}" pull api worker migrations

echo "Exécution des migrations"

"${COMPOSE[@]}" --profile maintenance \
  run --rm --no-deps migrations

echo "Redémarrage API et Worker"

"${COMPOSE[@]}" up -d --no-deps api worker

echo "Vérification de l'API"

for attempt in {1..15}; do
  if curl --fail --silent \
    http://127.0.0.1:3000/sante >/dev/null; then
    break
  fi

  if [[ "$attempt" -eq 15 ]]; then
    echo "Échec du contrôle de santé API"

    if [[ "$PREVIOUS_SHA" =~ ^[0-9a-f]{40}$ ]]; then
      export DROPP_API_IMAGE="ghcr.io/$GHCR_OWNER/dropp-api:$PREVIOUS_SHA"
      export DROPP_WORKER_IMAGE="ghcr.io/$GHCR_OWNER/dropp-worker:$PREVIOUS_SHA"

      "${COMPOSE[@]}" up -d --no-deps api worker
    fi

    exit 1
  fi

  sleep 2
done

# Vérification minimale du processus Worker.
if [[ "$(docker inspect -f '{{.State.Running}}' dropp-worker)" != "true" ]]; then
  echo "Le Worker n'est pas actif"

  if [[ "$PREVIOUS_SHA" =~ ^[0-9a-f]{40}$ ]]; then
    export DROPP_API_IMAGE="ghcr.io/$GHCR_OWNER/dropp-api:$PREVIOUS_SHA"
    export DROPP_WORKER_IMAGE="ghcr.io/$GHCR_OWNER/dropp-worker:$PREVIOUS_SHA"

    "${COMPOSE[@]}" up -d --no-deps api worker
  fi

  exit 1
fi

printf '%s\n' "$SHA" > "$ACTIVE_SHA_FILE"

echo "Déploiement terminé : $SHA"
