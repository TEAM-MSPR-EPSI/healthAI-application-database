FROM minio/minio:latest

LABEL maintainer="you@example.com"
LABEL description="MinIO object storage for social media app"

# mc (MinIO Client) est déjà inclu dans l'image minio/minio
# On expose les deux ports standards
EXPOSE 9000 9001

# Les données sont stockées dans /data
VOLUME ["/data"]

# Lancement du serveur MinIO avec la console activée
CMD ["server", "/data", "--console-address", ":9001"]
