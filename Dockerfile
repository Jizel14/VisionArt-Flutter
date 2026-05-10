# ── Stage 1: Flutter web build ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache pub dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and build web
COPY . .
RUN flutter build web --release \
    --dart-define=VISIONCRAFT_API_KEY=${VISIONCRAFT_API_KEY:-} \
    --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-}

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine AS production

COPY --from=builder /app/build/web /usr/share/nginx/html

# SPA routing: fallback to index.html for Flutter web
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
