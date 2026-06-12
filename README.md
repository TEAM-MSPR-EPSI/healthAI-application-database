# 📦 MinIO — Stockage médias réseau social

Stack de stockage objet S3-compatible pour une application style réseau social.
Gère photos, vidéos et avatars.

---

## Architecture

```
Internet / App
      │
      ▼
  [ Nginx ]  ← reverse proxy + cache média
      │
      ▼
  [ MinIO ]  ← stockage objet S3-compatible
      │
  /data volume
```

## Buckets

| Bucket           | Usage                          | Accès         | Lifecycle  |
|------------------|--------------------------------|---------------|------------|
| `avatars`        | Photos de profil               | Public (GET)  | —          |

| `photos`         | Photos postées                 | Public (GET)  | —          |
| `videos`         | Vidéos postées                 | Public (GET)  | —          |

---

## Démarrage rapide

### 1. Configurer les secrets

```bash
cp .env.example .env
# Éditer .env avec vos mots de passe
```

### 2. Lancer la stack

```bash
docker compose up -d
```

Le service `minio-init` crée automatiquement les buckets, les politiques et
le compte de service applicatif au premier démarrage.

### 3. Accès

| Service       | URL                       | Credentials          |
|---------------|---------------------------|----------------------|
| API S3        | http://localhost:9000     | voir `.env`          |
| Console admin | http://localhost:9001     | `MINIO_ROOT_USER`    |
| Proxy Nginx   | http://localhost:80       | —                    |

---

## Connexion depuis l'application

### Node.js / TypeScript (AWS SDK v3)

```typescript
import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({
  endpoint: "http://localhost:9000",
  region: "us-east-1",          // valeur obligatoire, peu importe laquelle
  forcePathStyle: true,          // OBLIGATOIRE pour MinIO
  credentials: {
    accessKeyId: process.env.APP_ACCESS_KEY!,
    secretAccessKey: process.env.APP_SECRET_KEY!,
  },
});

// Upload d'une photo
await s3.send(new PutObjectCommand({
  Bucket: "photos",
  Key: `users/${userId}/${Date.now()}.jpg`,
  Body: fileBuffer,
  ContentType: "image/jpeg",
}));

// Download ou accès direct via URL publique
// Exemple: http://localhost/photos/...
```

### Python (boto3)

```python
import boto3

s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:9000",
    aws_access_key_id=APP_ACCESS_KEY,
    aws_secret_access_key=APP_SECRET_KEY,
    region_name="us-east-1",
)

# Upload
s3.upload_fileobj(file_obj, "photos", f"users/{user_id}/photo.jpg",
                  ExtraArgs={"ContentType": "image/jpeg"})


```

---

## Upload direct depuis le navigateur (presigned PUT)

Pour éviter que les fichiers transitent par votre backend :

```typescript
// Backend — génère l'URL signée
const uploadUrl = await getSignedUrl(
  s3,
  new PutObjectCommand({
    Bucket: "photos",
    Key: `users/${userId}/${uuid}.jpg`,
    ContentType: "image/jpeg",
  }),
  { expiresIn: 300 }   // 5 minutes
);

// Frontend — upload direct vers MinIO
await fetch(uploadUrl, {
  method: "PUT",
  body: file,
  headers: { "Content-Type": "image/jpeg" },
});
```

---

## Organisation recommandée des clés

```
avatars/
  {userId}/avatar.webp
  {userId}/avatar_thumb.webp

photos/
  {userId}/{postId}/{uuid}.jpg
  {userId}/{postId}/{uuid}_thumb.jpg

videos/
  {userId}/{postId}/{uuid}.mp4
  {userId}/{postId}/{uuid}_preview.gif
```

---

## Mise en production

### TLS avec Let's Encrypt (Certbot)

```bash
certbot certonly --standalone -d media.example.com -d console.example.com
# Copier les certs dans ./certs/ et décommenter le bloc TLS dans nginx/conf.d/minio.conf
```

### Scalabilité — mode distribué

Pour passer à plusieurs nœuds MinIO, adapter le `docker-compose.yml` avec
4+ instances et un pool de disques. Voir la [doc MinIO distributed](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node-multi-drive.html).

### Monitoring

```bash
# Ajouter le scraping Prometheus dans docker-compose.yml
MINIO_PROMETHEUS_AUTH_TYPE: public
# endpoint : http://minio:9000/minio/v2/metrics/cluster
```

---

## Commandes utiles

```bash
# Statut des buckets
docker exec minio-init mc ls local

# Logs MinIO
docker compose logs -f minio

# Vider le cache Nginx
docker exec minio-nginx nginx -s reload

# Inspecter les politiques IAM
docker exec minio-init mc admin policy list local
```
