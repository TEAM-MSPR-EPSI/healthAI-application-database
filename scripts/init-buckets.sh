#!/bin/sh
set -e

echo "⏳  Attente que MinIO soit prêt..."
until mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" 2>/dev/null; do
  sleep 2
done
echo "✅  MinIO est prêt."

# ─────────────────────────────────────────────
#  Création des buckets
# ─────────────────────────────────────────────

# Avatars & photos de profil (publiques en lecture)
mc mb --ignore-existing local/avatars


# Photos postées (publiques en lecture)
mc mb --ignore-existing local/photos

# Vidéos postées (publiques en lecture)
mc mb --ignore-existing local/videos



echo "✅  Buckets créés."

# ─────────────────────────────────────────────
#  Politiques d'accès
# ─────────────────────────────────────────────

# Buckets en lecture publique (anonymous GET)
for bucket in avatars photos videos; do
  mc anonymous set download local/$bucket
  echo "🔓  $bucket → lecture publique"
done


#  Compte de service pour l'application
# ─────────────────────────────────────────────
mc admin user add local "$APP_ACCESS_KEY" "$APP_SECRET_KEY" 2>/dev/null || true

# Appliquer la politique JSON custom
mc admin policy create local social-app-policy /policies/app-policy.json 2>/dev/null || true
mc admin policy attach local social-app-policy --user "$APP_ACCESS_KEY"

echo "👤  Utilisateur app '$APP_ACCESS_KEY' configuré avec la politique social-app-policy."

# ─────────────────────────────────────────────
#  Quota par bucket (optionnel)
# ─────────────────────────────────────────────
# mc quota set local/videos --size 100GiB
# mc quota set local/photos --size 50GiB

echo ""
echo "🎉  Initialisation MinIO terminée !"
echo "    Console  : http://localhost:9001"
echo "    API S3   : http://localhost:9000"
