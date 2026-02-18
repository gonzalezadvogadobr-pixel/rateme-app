# 📌 PROJETO RateMe — Arquivo de Contexto

> **INSTRUÇÕES PARA O ASSISTENTE AI:**
> Leia este arquivo inteiro antes de qualquer ação.
> Ele contém todo o histórico, estado atual e próximos passos do projeto.
> Após ler, confirme: *"Li o PROJETO.md. Estou pronto para continuar o RateMe de onde paramos."*

---

## 🎯 Visão Geral do App

**Nome:** RateMe
**Conceito:** Rede social onde usuários publicam fotos e outras pessoas avaliam partes específicas da foto usando "pins" interativos. Cada pin tem uma nota de 0 a 10, um título (ex: "Cabelo", "Roupa", "Expressão") e um comentário. A foto recebe uma nota média com base em todos os pins.
**Slogan:** "Avalie fotos com pinos interativos"
**Público-alvo:** Pessoas que querem feedback visual detalhado sobre fotos (moda, fitness, arte, etc.)

---

## 👤 Dados do Proprietário

**GitHub:** gonzalezadvogadobr-pixel
**Repositório:** https://github.com/gonzalezadvogadobr-pixel/rateme-app
**Token GitHub:** NÃO armazenar aqui por segurança.

> Para gerar um novo token quando necessário:
> 1. Acesse: https://github.com/settings/tokens/new
> 2. Note: "RateMe App", Expiration: 90 days
> 3. Marque o escopo: **repo** (checkbox principal)
> 4. Clique "Generate token" e copie o resultado (começa com ghp_...)
> 5. Envie o token para o assistente no início da sessão

---

## 🛠️ Stack Tecnológica

| Item | Detalhe |
|------|---------|
| **Framework** | Flutter 3.35.4 |
| **Linguagem** | Dart 3.9.2 |
| **Plataformas** | Android + Web (preview) |
| **Estado** | Provider 6.1.5+1 |
| **Banco local** | SharedPreferences (metadados) + IndexedDB (imagens) |
| **Package Android** | com.pinscore.rating |
| **Pasta do projeto** | /home/user/flutter_app |

---

## 📦 Dependências Atuais (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: 6.1.5+1
  shared_preferences: 2.5.3
  image_picker: 1.1.2
  uuid: 4.5.1
  intl: 0.19.0
  path_provider: 2.1.5
  cupertino_icons: ^1.0.8
  google_fonts: 6.2.1
```

---

## 🗂️ Estrutura de Arquivos

```
flutter_app/
├── lib/
│   ├── main.dart                          # Entry point, Provider setup, AppGate
│   ├── models/
│   │   └── models.dart                    # AppUser, Post, Pin, PostComment, AppNotification, Follow
│   ├── services/
│   │   ├── database_service.dart          # TODA a lógica de negócio (auth, posts, pins, etc.)
│   │   ├── image_storage.dart             # Interface de armazenamento de imagens
│   │   ├── image_storage_web.dart         # Implementação Web via IndexedDB (JS interop)
│   │   └── image_storage_io.dart          # Implementação Mobile via arquivos locais
│   ├── screens/
│   │   ├── auth_screen.dart               # Login + Cadastro (tela de entrada com logomarca)
│   │   ├── home_screen.dart               # Scaffold principal com BottomNavigationBar
│   │   ├── feed_screen.dart               # Feed de posts (todos / seguindo)
│   │   ├── create_post_screen.dart        # Publicar nova foto
│   │   ├── post_detail_screen.dart        # Detalhe do post + pins interativos + zoom
│   │   ├── profile_screen.dart            # Perfil do usuário logado
│   │   ├── ranking_screen.dart            # Ranking de posts por nota
│   │   ├── search_screen.dart             # Busca de usuários
│   │   ├── notifications_screen.dart      # Notificações
│   │   └── user_profile_screen.dart       # Perfil público de outro usuário
│   ├── theme/
│   │   └── app_theme.dart                 # Cores, gradientes, ThemeData (tema escuro atual)
│   └── widgets/
│       └── common_widgets.dart            # AppImage, UserAvatar, ScoreBadge, GradientButton, PinMarker
├── assets/
│   ├── icons/
│   │   └── rateme_logo.png                # Logomarca: pino dentro de círculo (roxo/rosa)
│   └── images/                            # (pasta reservada para imagens futuras)
├── web/
│   └── index.html                         # Inclui helpers JS para IndexedDB
└── android/
    └── app/
        ├── build.gradle.kts               # applicationId = "com.pinscore.rating"
        └── src/main/kotlin/com/pinscore/rating/
            └── MainActivity.kt
```

---

## 🎨 Design e Tema

**Estilo:** Escuro (dark theme) com gradiente roxo → rosa
**Cores principais:**
- Background: `#0D0D1A` (fundo principal)
- Cards: `#16213E`
- Roxo: `#7C3AED`
- Rosa: `#EC4899`
- Texto primário: branco
- Texto secundário: cinza claro

**Logomarca:** Pino de localização dentro de um círculo, gradiente roxo→rosa, minimalista
**Arquivo:** `assets/icons/rateme_logo.png`

**Tela de auth:** Gradiente no topo, logo centralizada, campos de login/cadastro centralizados, hint de contas demo

---

## ⚙️ Funcionalidades Implementadas

### Autenticação
- [x] Cadastro com nome, email, senha
- [x] Login com email e senha
- [x] Logout
- [x] 3 contas demo: ana@demo.com, pedro@demo.com, mariana@demo.com (senha: 123456)

### Posts
- [x] Publicar foto (qualquer tamanho — salva no IndexedDB)
- [x] Legenda opcional
- [x] Feed geral e feed "seguindo"
- [x] Deletar post

### Pins (avaliações interativas)
- [x] Tocar na foto para criar pin
- [x] Definir título do pin (ex: "Cabelo")
- [x] Nota de 0 a 10
- [x] Comentário no pin
- [x] Pin público ou privado
- [x] Limite de 10 pins por usuário por foto
- [x] Editar e deletar pin
- [x] Cálculo automático de nota média

### Perfil
- [x] Foto de perfil (tamanho 112px, clicável)
- [x] Bio editável
- [x] Configuração de privacidade dos pins
- [x] Ver posts próprios no perfil

### Social
- [x] Seguir/deixar de seguir usuários
- [x] Contagem de seguidores/seguindo
- [x] Notificações (novo pin, novo comentário, novo seguidor)
- [x] Busca de usuários
- [x] Ver perfil público de outros usuários

### Ranking
- [x] Posts ordenados por nota média
- [x] Mínimo de 5 pins para entrar no ranking

### Comentários
- [x] Comentar em posts
- [x] Deletar comentário

---

## 🗄️ Armazenamento Atual (IMPORTANTE)

**Arquitetura híbrida — tudo LOCAL no dispositivo:**

| Dado | Onde fica |
|------|-----------|
| Metadados (posts, pins, users) | SharedPreferences (localStorage no web) |
| Imagens de posts | IndexedDB (via JS interop no web) |
| Imagens de avatares | IndexedDB (via JS interop no web) |

**Limitação crítica:** É armazenamento LOCAL. Cada usuário vê apenas seus próprios dados.
Não existe feed compartilhado entre dispositivos diferentes.
**Isso precisa ser resolvido com Firebase (próximo passo).**

---

## 📋 Histórico de Decisões Importantes

### Por que não usamos Firebase ainda?
- Tentamos integrar Firebase em uma sessão anterior
- A integração causou erros que quebraram o app
- Decidimos reverter para a versão local funcional
- **Próxima tentativa será com protocolo de segurança rigoroso (branch separada)**

### Por que IndexedDB em vez de só SharedPreferences?
- SharedPreferences usa localStorage do browser: limite de ~5MB
- Uma foto base64 pode ter 500KB–1MB
- Com 3–4 fotos o localStorage estourava silenciosamente
- IndexedDB suporta centenas de MB
- Solução: metadados no SharedPreferences + imagens no IndexedDB

### Por que o tema é escuro?
- Decisão estética do proprietário
- Gradiente roxo→rosa é a identidade visual do app

---

## 🚀 Próximos Passos (em ordem de prioridade)

### ETAPA 1 — Firebase Backend (PRÓXIMO A FAZER)
**Objetivo:** Transformar o app de local para rede social real na nuvem

**Protocolo de segurança antes de começar:**
1. `git tag v1.0-stable` — marcar versão estável atual
2. `git checkout -b firebase-integration` — trabalhar em branch separada
3. Gerar backup .tar.gz atualizado
4. Só fazer merge na main quando 100% funcionando

**O que implementar:**
- [ ] Firebase Auth (email/senha)
- [ ] Firestore para posts, pins, comentários, usuários, follows, notificações
- [ ] Firebase Storage para imagens (substitui IndexedDB)
- [ ] Manter todas as funcionalidades atuais
- [ ] Feed compartilhado entre todos os usuários

**Credenciais Firebase necessárias (proprietário deve fornecer):**
- Arquivo `google-services.json` (Android)
- Arquivo `firebase-admin-sdk.json` (para criar coleções iniciais)
- Ou: criar novo projeto Firebase do zero em console.firebase.google.com

### ETAPA 2 — Google Play Store
**Objetivo:** Publicar no Android

**O que fazer:**
- [ ] Gerar AAB (Android App Bundle) assinado
- [ ] Criar política de privacidade (assistente gera o texto)
- [ ] Preparar screenshots (mínimo 2, ideal 8)
- [ ] Escrever descrição do app
- [ ] Proprietário: criar conta em play.google.com/console (US$25)
- [ ] Proprietário: fazer upload do AAB no Play Console
- [ ] Aguardar revisão (~3–7 dias)

### ETAPA 3 — Apple App Store
**Objetivo:** Publicar no iOS

**O que fazer:**
- [ ] Preparar código Flutter para iOS
- [ ] Proprietário: criar conta em developer.apple.com (US$99/ano)
- [ ] Build via Codemagic (CI/CD gratuito — assistente guia o processo)
- [ ] Preparar screenshots para iPhone
- [ ] Aguardar revisão Apple (~1–3 dias)

---

## 🐛 Problemas Conhecidos e Soluções

| Problema | Causa | Status |
|----------|-------|--------|
| Fotos somem após alguns minutos | localStorage cheio (limite 5MB) | ✅ Resolvido com IndexedDB |
| App quebrou ao integrar Firebase | Sem branch separada, sem backup prévio | ✅ Resolvido — protocolo de segurança definido |
| Dois MainActivities no Android | Pastas duplicadas com package names diferentes | ✅ Resolvido |
| firebase_options.dart com erros | Arquivo residual do Firebase anterior | ✅ Arquivo removido |

---

## 🔧 Comandos Úteis para Retomar

```bash
# Navegar para o projeto
cd /home/user/flutter_app

# Verificar estado do git
git status && git log --oneline

# Instalar dependências
flutter pub get

# Verificar erros de código
flutter analyze

# Build web para preview
flutter build web --release
cd build/web && python3 -c "
import http.server, socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('X-Frame-Options','ALLOWALL')
        super().end_headers()
    def log_message(self, *a): pass
with socketserver.TCPServer(('0.0.0.0',5060),H) as s: s.serve_forever()
" &

# Salvar no GitHub
git add . && git commit -m "descrição" && git push origin main

# Voltar para versão estável se algo der errado
git checkout main
```

---

## 💰 Custos Planejados

| Item | Valor | Status |
|------|-------|--------|
| Google Play (taxa única) | ~R$ 130 (US$25) | ⏳ Pendente |
| Apple Developer (anual) | ~R$ 515 (US$99/ano) | ⏳ Pendente |
| Domínio para política de privacidade | ~R$ 60/ano | ⏳ Pendente |
| Firebase (backend) | Grátis até ~50k usuários | ⏳ Pendente |

---

## 📝 Contas Demo para Testes

```
ana@demo.com      / 123456  (Ana Silva)
pedro@demo.com    / 123456  (Pedro Costa)
mariana@demo.com  / 123456  (Mariana Lima)
```

---

## 🗒️ Observações Finais

- O proprietário está no Brasil — comunicação em **português brasileiro**
- Decisões de design são do proprietário — respeitar preferências visuais
- Antes de qualquer alteração grande: **backup + branch separada + confirmar com proprietário**
- O proprietário valoriza: honestidade sobre limitações, explicações claras, sem surpresas
- Linguagem: direta, sem jargão técnico desnecessário

---

*Arquivo criado em: Junho/2025*
*Última atualização: Junho/2025*
*Versão do app: 1.0.0+1*
*Commit estável: ee73dcf*
