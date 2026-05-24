# Adım Adım Kurulum Rehberi

## 1. Gerekli Araçları Kur

### Git
- İndir: https://git-scm.com/download/win
- Kurulum sırasında tüm varsayılan seçenekleri onayla
- Doğrula: `git --version`

### GitHub CLI
- İndir: https://cli.github.com/
- Kurulum sonrası: `gh auth login` → tarayıcıda GitHub hesabınla giriş yap

### Node.js 20 LTS
- İndir: https://nodejs.org/ (LTS sürümünü seç)
- Doğrula: `node --version` ve `npm --version`

### Godot 4.x
- İndir: https://godotengine.org/download/windows/
- `.exe` dosyasını istediğin bir klasöre koy
- Yol eklemek zorunda değilsin, direkt çift tıkla

### Docker Desktop (opsiyonel)
- İndir: https://www.docker.com/products/docker-desktop/

---

## 2. GitHub Deposunu Oluştur

Araçları kurduktan sonra terminal (PowerShell) açıp şu komutları çalıştır:

```powershell
# Cell-conquest klasörüne gir
cd "C:\Users\Aselman\Desktop\VisualCode\cell-conquest"

# Git başlat
git init
git add .
git commit -m "ilk commit: Cell Conquest proje yapısı"

# GitHub'da repo oluştur ve push et
gh repo create cell-conquest --public --source=. --remote=origin --push
```

---

## 3. Sunucuyu Çalıştır

```powershell
cd "C:\Users\Aselman\Desktop\VisualCode\cell-conquest\server"
npm install
npm run dev
```

Sunucu `ws://localhost:2567` adresinde çalışmaya başlar.

---

## 4. Godot İstemcisini Çalıştır

1. Godot 4'ü aç
2. "Import Project" → `C:\Users\Aselman\Desktop\VisualCode\cell-conquest\client\project.godot`
3. Projeyi aç
4. `client/scripts/NetworkManager.gd` dosyasını aç
5. `_use_local := false` satırını `_use_local := true` yap (yerel sunucu için)
6. F5 veya "Run Project" ile oyunu başlat

---

## 5. GitHub Actions Secrets Tanımla

GitHub deposu oluşturduktan sonra:
1. Repo sayfası → Settings → Secrets and variables → Actions
2. "New repository secret" ile şunları ekle:

| Secret Adı | Değer | Nereden Alınır |
|------------|-------|----------------|
| `NETLIFY_AUTH_TOKEN` | Netlify kişisel token | Netlify → User Settings → OAuth |
| `NETLIFY_SITE_ID` | Site ID | Netlify → Site → Settings → General |
| `RENDER_DEPLOY_HOOK` | Deploy hook URL | Render → Service → Settings → Deploy Hook |

---

## 6. Ücretsiz Hosting Kur

### Netlify (HTML5 web versiyonu)
1. netlify.com → Sign up (GitHub ile)
2. "Add new site" → "Import from Git" → GitHub repoyu seç
3. Build command: (boş bırak, GitHub Actions build eder)
4. Publish dir: `client/export/web`

### Render (Oyun sunucusu)
1. render.com → Sign up (GitHub ile)
2. "New Web Service" → GitHub repoyu bağla
3. Root directory: `server`
4. Build command: `npm install && npm run build`
5. Start command: `npm start`
6. Deploy Hook URL'ini kopyala → GitHub secret olarak ekle

---

## Hazır! 

Her şey kurulduktan sonra:
- `main` branch'e push ettiğinde otomatik olarak:
  - Sunucu Render'a deploy olur
  - HTML5 versiyonu Netlify'e deploy olur
  - APK artifact GitHub Actions'ta oluşur
