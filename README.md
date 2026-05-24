# Cell Conquest

Gerçek zamanlı çok oyunculu hücre strateji oyunu.  
Android · iOS · Tarayıcı (HTML5)

## Oynanış

Haritadaki renk kodlu hücreleri kontrol et. Her hücre zamanla kuvvet kazanır.
Kendi hücrenden düşman/nötr bir hücreye **sürükle** → kuvvet gönder.
3 dakika sonunda en çok hücreye sahip oyuncu kazanır.

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Oyun istemcisi | Godot 4.x (GDScript) |
| Oyun sunucusu | Node.js + Colyseus |
| Veritabanı | Supabase |
| Web hosting | Netlify |
| Sunucu hosting | Render |
| CI/CD | GitHub Actions |

## Kurulum

### Gereksinimler

- [Godot 4.x](https://godotengine.org/)
- [Node.js 20 LTS](https://nodejs.org/)
- [Git](https://git-scm.com/)
- [Docker Desktop](https://www.docker.com/) (opsiyonel, sunucu container'ı için)
- Android Studio (Android APK export için)
- Xcode + Mac (iOS IPA export için)

### Sunucuyu Yerel Çalıştır

```bash
cd server
npm install
npm run dev
# Sunucu: ws://localhost:2567
```

### İstemciyi Çalıştır

1. Godot 4.x'i aç
2. `client/project.godot` dosyasını aç
3. `NetworkManager.gd` içinde `_use_local = true` yap
4. F5 ile çalıştır

### Docker ile Sunucu

```bash
cd server
docker build -t cell-conquest-server .
docker run -p 2567:2567 cell-conquest-server
```

## Platform Export

### Android APK

1. Godot → Project → Export → Android
2. `export_presets.cfg` zaten yapılandırılmış
3. Keystore imzalama için `android/` klasöründe debug.keystore gerekli

### iOS IPA

> Mac + Xcode + Apple Developer hesabı gereklidir.

1. Godot → Project → Export → iOS
2. Xcode'da aç, Team ID gir, archive et

### HTML5 (Tarayıcı)

```bash
# GitHub Actions otomatik build eder ve Netlify'e deploy eder
# Manuel: Godot → Project → Export → HTML5
```

## CI/CD Pipeline

| Workflow | Tetikleyici | Ne Yapar |
|----------|-------------|----------|
| `test.yml` | Her push/PR | TypeScript derleme ve tip kontrolü |
| `godot-export.yml` | `main` branch | HTML5 + APK build, Netlify deploy |
| `server-deploy.yml` | `main` branch (`server/` değişince) | Docker image build + Render deploy |

## GitHub Secrets (Yapılandırılması Gerekenler)

```
NETLIFY_AUTH_TOKEN    → Netlify kullanıcı token'ı
NETLIFY_SITE_ID       → Netlify site ID
RENDER_DEPLOY_HOOK    → Render servis deploy hook URL'i
```

## Proje Yapısı

```
cell-conquest/
├── client/          # Godot 4 oyun istemcisi
│   ├── scenes/      # .tscn sahne dosyaları
│   ├── scripts/     # GDScript dosyaları
│   ├── assets/      # Görseller, sesler, fontlar
│   └── export_presets.cfg
├── server/          # Node.js + Colyseus oyun sunucusu
│   ├── src/
│   │   ├── rooms/   # GameRoom.ts — oyun odası mantığı
│   │   └── schema/  # GameState.ts — senkronize durum
│   └── Dockerfile
├── .github/
│   └── workflows/   # CI/CD pipeline'ları
└── README.md
```

## Lisans

MIT
