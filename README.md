# VisionArt — Flutter Mobile App

Flutter mobile application for VisionArt. Generates context-aware AI artworks based on user preferences, location, and style. Supports Android and iOS.

## Tech Stack

- **Framework**: Flutter 3 + Dart
- **State**: Local state + services pattern
- **Auth**: Email/password + Google Sign-In
- **AI Generation**: VisionCraft API (Stable Diffusion)
- **Backend**: VisionArt NestJS API
- **Container**: Docker (Flutter web build → nginx)
- **Orchestration**: Kubernetes

---

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable production-ready code |
| `dev`  | Active development — all PRs target this branch |
| `feat/marketplace` | Marketplace feature in progress |

CI auto-triggers on every push to `dev`. Deployment to `main` is **manual** via GitHub Actions.

---

## Local Development

### Prerequisites

- Flutter SDK 3.x (`flutter --version`)
- Android Studio / Xcode for emulators
- VisionArt backend running (see [backend repo](https://github.com/Jizel14/VisionArt-Backend))

### Setup

```bash
flutter pub get
flutter run
```

### Configuration (`lib/core/app_config.dart`)

| Constant | Description |
|----------|-------------|
| `kApiBaseUrl` | Backend base URL — set to your machine's LAN IP for real device testing |
| `kVisionCraftApiKey` | VisionCraft AI API key (pass via `--dart-define`) |
| `kGoogleWebClientId` | Google OAuth Web Client ID (pass via `--dart-define`) |

```bash
# Run with secrets injected
flutter run \
  --dart-define=VISIONCRAFT_API_KEY=your_key \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your_client_id
```

> **Real device**: update `kApiBaseUrl` to your PC LAN IP (e.g. `http://192.168.1.x:3000`).
> **Android emulator**: use `http://10.0.2.2:3000`.

---

## Project Structure

```
lib/
├── core/
│   ├── api_client.dart          # HTTP client + error handling
│   ├── auth_service.dart        # Auth logic (login, register, Google, forgot password)
│   ├── app_config.dart          # Environment constants
│   ├── preferences_service.dart # User preferences persistence
│   ├── visioncraft_service.dart # AI image generation
│   ├── models/                  # Artwork, User, Follow, Preferences models
│   └── services/                # ArtworkService, FollowService
├── presentation/
│   └── screens/
│       ├── auth/                # Login + Sign-up screen (email + Google)
│       ├── home/                # Home feed + artwork generation
│       ├── preferences/         # Onboarding & preferences (aesthetic, context, privacy, UI)
│       └── profile/             # Profile, edit profile, artwork detail, gallery, inspect
└── main.dart
```

---

## Docker (Flutter Web)

The Docker image builds the Flutter web version and serves it with nginx.

```bash
# Build image
docker build -t visionart-flutter .

# Run locally
docker run -p 8080:80 visionart-flutter
# Open http://localhost:8080
```

With secrets:

```bash
docker build \
  --build-arg VISIONCRAFT_API_KEY=your_key \
  --build-arg GOOGLE_WEB_CLIENT_ID=your_client_id \
  -t visionart-flutter .
```

---

## CI/CD — GitHub Actions

### `ci-dev.yml` — Auto on push to `dev`

1. Flutter analyze
2. Build & push Docker image to `ghcr.io`

**Image tags**: `dev`, `dev-<sha>`

### `deploy-main.yml` — Manual (`workflow_dispatch`)

Triggered manually from GitHub Actions UI. Choose environment: `production` or `staging`.

**Image tags**: `latest`, `<environment>`, `<sha>`

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `VISIONCRAFT_API_KEY` | VisionCraft AI API key |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth Web Client ID |

> **Permissions**: Set repo → Settings → Actions → General → Workflow permissions to **Read and write**.

---

## Kubernetes

Manifests are in `k8s/`. Requires the `visionart` namespace (apply `k8s/namespace.yml` from the backend repo first).

```bash
kubectl apply -f k8s/deployment.yml
kubectl apply -f k8s/service.yml
```

| Resource | Details |
|----------|---------|
| `Deployment` | 2 replicas, nginx serving Flutter web build |
| `Service (NodePort)` | External access on `:30001` |

Image pulled from `ghcr.io/jizel14/visionart-flutter:latest`.

---

## Features

- **Auth**: Email/password login & registration, Google Sign-In, forgot/reset password
- **Onboarding**: Multi-step preferences (aesthetic styles, subjects, mood, colors, context, privacy)
- **Home feed**: Browse community artworks, like, save to collections
- **AI generation**: Generate artworks via VisionCraft API with context-aware prompts
- **Profile**: View & edit profile, personal gallery, follow/unfollow users
- **Social**: Follow system, user inspect screen, artwork detail with share
- **Notifications**: In-app notification feed
