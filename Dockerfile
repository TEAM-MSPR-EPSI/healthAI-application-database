FROM minio/minio:latest

LABEL org.opencontainers.image.title="healthAI-application-database"
LABEL org.opencontainers.image.description="Base de données pour l'application healthAI"
LABEL org.opencontainers.image.vendor="MSPR Team"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/TEAM-MSPR-EPSI/healthAI-application-database"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2026-06-16T12:00:00+02:00"

# LABEL maintainer="you@example.com"
LABEL description="MinIO object storage for social media app"

# mc (MinIO Client) est déjà inclu dans l'image minio/minio
# On expose les deux ports standards
EXPOSE 9000 9001

# Les données sont stockées dans /data
VOLUME ["/data"]

# Lancement du serveur MinIO avec la console activée
CMD ["server", "/data", "--console-address", ":9001"]
