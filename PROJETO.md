# 📌 PROJETO PinZap — Arquivo de Contexto

> **INSTRUÇÕES PARA O ASSISTENTE AI:**
> Leia este arquivo inteiro antes de qualquer ação.
> Ele contém todo o histórico, estado atual e próximos passos do projeto.
> Após ler, confirme: *"Li o PROJETO.md. Estou pronto para continuar o PinZap de onde paramos."*

---

## 🎯 Visão Geral do App

**Nome:** PinZap
**Conceito:** Rede social onde usuários publicam fotos e outras pessoas avaliam partes específicas da foto usando "pins" interativos. Cada pin tem uma nota de 0 a 10, um título (ex: "Cabelo", "Roupa", "Expressão") e um comentário. A foto recebe uma nota média com base em todos os pins.
**Slogan:** "Avalie. Marque. Zap!"
**Público-alvo:** Pessoas que querem feedback visual detalhado sobre fotos (moda, fitness, arte, etc.)
**Package Android:** `com.pinscore.rating`
**Nome interno (pubspec):** `pin_zap`

---

## 👤 Dados do Proprietário

**GitHub:** gonzalezadvogadobr-pixel
**Repositório:** https://github.com/gonzalezadvogadobr-pixel/rateme-app
**Token GitHub:** NÃO armazenar aqui por segurança.

> Para gerar um novo token quando necessário:
> 1. Acesse: https://github.com/settings/tokens/new
> 2. Note: "PinZap Push", Expiration: 90 days
> 3. Tipo: **Classic token**
> 4. Marque o escopo: **repo** (checkbox principal)
> 5. Clique "Generate token" e copie o resultado (começa com ghp_...)
> 6. Envie o token para o assistente no início da sessão
>
> ⚠️ Token fine-grained (github_pat_...) NÃO funcionou — use sempre classic (ghp_...)

---

## 🛠️ Stack Tecnológica

| Item | Detalhe |
|------|---------|
| **Framework** | Flutter 3.35.4 |
| **Linguagem** | Dart 3.9.2 |
| **Plataformas** | Android + Web (preview) |
| **Estado** | Provider 6.1.5+1 |
| **Backend** | Firebase (Auth + Firestore) |
| **Imagens** | Base64 salvo direto no Firestore |
| **Package Android** | com.pinscore.rating |
| **Projeto Firebase** | rateme-a1de6 |
| **Pasta do projeto** | /home/user/flutter_app |

---

## 📦 Dependências Atuais (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: 6.1.5+1
  firebase_core: 3.6.0
  firebase_auth: 5.3.1
  cloud_firestore: 5.4.3
  shared_preferences: 2.5.3
  image_picker: 1.1.2
  uuid: 4.5.1
  intl: 0.19.0
  path_provider: 2.1.5
  cupertino_icons: ^1.0.8
  google_fonts: 6.2.1
```

> ⚠️ `firebase_storage` foi **removido intencionalmente** — imagens salvas como base64 no Firestore.
> Não adicionar `firebase_storage` de volta sem planejamento cuidadoso (risco de CORS no web).

---

## 🗂️ Estrutura de Arquivos

```
flutter_app/
├── lib/
│   ├── main.dart                          # Entry point, Provider setup, AppGate, init Firebase
│   ├── firebase_options.dart              # Configuração Firebase (projeto rateme-a1de6)
│   ├── models/
│   │   └── models.dart                    # AppUser, Post, Pin, PostComment, AppNotification, Follow
│   ├── services/
│   │   └── database_service.dart          # TODA a lógica de negócio (auth, posts, pins, etc.)
│   ├── screens/
│   │   ├── auth_screen.dart               # Login + Cadastro (tela de entrada com logomarca)
│   │   ├── home_screen.dart               # Scaffold principal com BottomNavigationBar
│   │   ├── feed_screen.dart               # Feed de posts em tempo real (StreamBuilder)
│   │   ├── create_post_screen.dart        # Publicar nova foto (com compressão dart:ui)
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
│   └── index.html                         # Bootstrap Flutter Web
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
- [x] Cadastro com nome, email, senha (Firebase Auth)
- [x] Login com email e senha
- [x] Logout
- [x] 3 contas demo: ana@demo.com, pedro@demo.com, mariana@demo.com (senha: 123456)

### Posts
- [x] Publicar foto (comprimida automaticamente para < 700KB)
- [x] Legenda opcional
- [x] Feed em tempo real via Firestore Stream
- [x] Feed geral e feed "seguindo"
- [x] Deletar post

### Pins (avaliações interativas)
- [x] Tocar na foto para criar pin
- [x] Definir título do pin (ex: "Cabelo")
- [x] Nota de 0 a 10
- [x] Comentário no pin
- [x] Pin público ou privado
- [x] **Limite de 5 pins por usuário por foto** ← atualizado (era 10)
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

**Arquitetura Firebase — dados na nuvem, compartilhados entre todos os usuários:**

| Dado | Onde fica |
|------|-----------|
| Autenticação (login/senha) | Firebase Auth |
| Metadados (posts, pins, users, follows, notificações) | Firestore |
| Imagens de posts | **Base64 no Firestore** (campo `imageBase64`) |
| Imagens de avatares | **Base64 no Firestore** (campo `avatarBase64`) |

**Detalhes da compressão de imagens:**
- Etapa 1: ImagePicker limita a 1200px e qualidade 80%
- Etapa 2: dart:ui redimensiona para máx. 800px, qualidade progressiva até caber em < 700KB
- Resultado: fotos de 3–5MB ficam em ~150–400KB; cabe no limite do Firestore (1MB/doc)

**Limitação:** Firestore tem limite de 1 MB por documento. Fotos muito grandes podem falhar.
**Solução futura:** Migrar imagens para Firebase Storage (sem impacto nas contas ou dados existentes).

**⚠️ Por que firebase_storage foi removido:**
- Firebase Storage retornava URLs que o browser bloqueava por CORS
- Solução temporária (e funcional): salvar como base64 direto no Firestore
- Migração para Storage pode ser feita no futuro sem perda de dados

---

## 📋 Histórico de Decisões Importantes

### Firebase integrado com sucesso (Junho/2025)
- Auth, Firestore e feed em tempo real funcionando
- `firebase_storage` removido por problema de CORS no web
- Imagens salvas como base64 no Firestore funcionam corretamente
- Domínio `sandbox.novita.ai` adicionado como "Authorized domain" no Firebase Console

### Por que o nome mudou de RateMe para PinZap?
- RateMe é nome muito genérico e possivelmente já usado
- PinZap é mais original, memorável, e reflete a mecânica de "pins" do app
- Slogan atualizado: "Avalie. Marque. Zap!"

### Limite de pins reduzido de 10 para 5
- Decisão do proprietário para tornar as avaliações mais seletivas e significativas

### Por que o tema é escuro?
- Decisão estética do proprietário
- Gradiente roxo→rosa é a identidade visual do app

### Token GitHub
- Token fine-grained (github_pat_...) NÃO funcionou (403 Forbidden)
- Usar sempre token classic (ghp_...) com escopo `repo`

---

## 🚀 Próximos Passos (em ordem de prioridade)

### ✅ ETAPA 1 — Firebase Backend — CONCLUÍDA
- [x] Firebase Auth (email/senha)
- [x] Firestore para posts, pins, comentários, usuários, follows, notificações
- [x] Feed compartilhado entre todos os usuários
- [x] Imagens salvas como base64 (firebase_storage removido por CORS)

### ETAPA 2 — Google Play Store (PRÓXIMO A FAZER)
**Objetivo:** Publicar no Android

**O que o assistente faz:**
- [x] Criar política de privacidade (texto gerado)
- [x] Gerar AAB assinado (app-release.aab — 48MB — versão 1.0.0+1)
- [x] Preparar descrição do app (título, descrição curta e completa)
- [ ] Gerar novo AAB após alterações pendentes

**O que o proprietário faz:**
- [x] Criar conta em play.google.com/console (US$25 — taxa única)
- [x] Hospedar política de privacidade (GitHub Pages — https://gonzalezadvogadobr-pixel.github.io/rateme-app/privacy_policy.html)
- [x] Criar app no Play Console
- [x] Preencher notas da versão (formato `<pt-BR>...</pt-BR>`)
- [ ] Verificação de identidade pelo Google (em andamento)
- [ ] Fazer upload do AAB no Play Console (aguardando verificação)
- [ ] Adicionar screenshots na ficha da Play Store
- [ ] Preencher formulário de classificação de conteúdo
- [ ] Configurar testadores para Teste Interno
- [ ] Aguardar revisão (~3–7 dias)

### ETAPA 3 — Apple App Store
**Objetivo:** Publicar no iOS

**O que fazer:**
- [ ] Preparar código Flutter para iOS
- [ ] Proprietário: criar conta em developer.apple.com (US$99/ano)
- [ ] Build via Codemagic (CI/CD — assistente guia o processo)
- [ ] Preparar screenshots para iPhone
- [ ] Aguardar revisão Apple (~1–3 dias)

### 🔧 Alterações Pendentes (aguardando fase de testes)
Implementar tudo de uma vez no próximo ciclo de desenvolvimento:

- [ ] **Nova logomarca** — substituir `assets/icons/rateme_logo.png` pelo novo ícone push_pin gradiente roxo→rosa (URL: https://www.genspark.ai/api/files/s/mAWvRQiO?cache_control=3600)
- [ ] **Nomes únicos** — no cadastro, verificar no Firestore se o nome já existe; se sim, exibir erro "Este nome já está em uso. Escolha outro."
- [ ] **Imagem pequena na tela de publicação** — aumentar o container de prévia da imagem na `create_post_screen.dart` para ficar proporcional ao feed
- [ ] **Fotos sem borda lateral (edge-to-edge)** — remover padding/margin lateral das fotos no feed e no detalhe do post para ocupar toda a largura da tela
- [ ] **Botão de configurações (engrenagem)** — adicionar ícone de engrenagem no perfil; tela de configurações com: conta privada/pública, privacidade dos pins, alterar senha, excluir conta
- [ ] **Bloquear usuário** — opção de bloquear outro usuário no perfil público; usuário bloqueado não vê os posts nem o perfil de quem bloqueou; lista de bloqueados nas configurações
- [ ] **Lista de seguidores e seguindo clicável** — no perfil, ao clicar em "Seguidores" ou "Seguindo" deve abrir lista com os respectivos usuários (com opção de visitar o perfil de cada um)
- [ ] **Stories** — publicar stories com foto ou vídeo curto (semelhante ao Instagram/TikTok); exibidos no topo do feed; desaparecem após 24 horas
- [ ] **Curtir título/alvo do pin** — ao receber um pin, o dono da foto pode curtir o título/alvo daquele pin (ex: curtir "Cabelo", "Roupa", etc.)
- [ ] **Marcar usuário em comentário (@menção)** — ao digitar "@" em um comentário, exibir lista de usuários para selecionar; o usuário marcado recebe notificação
- [ ] **Ajustar foto antes de publicar** — opção de crop (recorte), zoom e rotação da foto antes de publicar
- [ ] **Nome do app no celular** — alterar de "Pin Score" para "PinZap" (nome exibido embaixo do ícone e no cabeçalho do app)
- [ ] **Publicação de vídeos** — ⏸️ pausado; depende da migração para Firebase Storage (ETAPA 4); retomar análise no futuro
- [ ] Gerar novo AAB com todas as alterações acima
- [ ] Fazer upload do AAB atualizado no Play Console

---

### ETAPA 4 — Migração para Firebase Storage (futuro, opcional)
**Objetivo:** Escalar armazenamento de imagens além do Firestore
**Quando fazer:** Quando o app tiver usuários reais e o Firestore estiver chegando ao limite
**Impacto:** Zero — contas, fotos antigas e dados são preservados
**Protocolo:**
1. `git tag v1.x-stable` — marcar versão estável atual
2. `git checkout -b firebase-storage` — branch separada
3. Configurar CORS no Firebase Storage (1 comando via Google Cloud SDK)
4. Testar exaustivamente
5. Merge só quando 100% funcionando

---

## 🐛 Problemas Conhecidos e Soluções

| Problema | Causa | Status |
|----------|-------|--------|
| Fotos sumiam após alguns minutos | localStorage cheio (limite 5MB) | ✅ Resolvido — migrado para Firebase |
| App quebrou ao integrar Firebase | Sem branch separada, sem backup prévio | ✅ Resolvido — agora funciona |
| Fotos em branco após integração Firebase | Firebase Storage bloqueado por CORS | ✅ Resolvido — removido Storage, base64 no Firestore |
| Fotos grandes não carregavam | Firestore limita documento a 1MB | ✅ Resolvido — compressão dart:ui garante < 700KB |
| Erro network-request-failed | Domínio de preview não autorizado no Firebase | ✅ Resolvido — sandbox.novita.ai adicionado |
| Push para GitHub deu 403 | Token fine-grained sem permissão suficiente | ✅ Resolvido — usar token classic (ghp_...) |
| Dois MainActivities no Android | Pastas duplicadas com package names diferentes | ✅ Resolvido |

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
lsof -ti:5060 | xargs -r kill -9 2>/dev/null; sleep 1
cd /home/user/flutter_app && flutter build web --release
cd build/web && python3 -c "
import http.server, socketserver
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('X-Frame-Options','ALLOWALL')
        self.send_header('Content-Security-Policy','frame-ancestors *')
        super().end_headers()
    def log_message(self, *a): pass
with socketserver.TCPServer(('0.0.0.0',5060),H) as s: s.serve_forever()
" &

# Salvar no GitHub (usar token classic ghp_...)
git remote set-url origin https://SEU_TOKEN@github.com/gonzalezadvogadobr-pixel/rateme-app.git
git add . && git commit -m "descrição" && git push origin main

# Voltar para versão estável se algo der errado
git checkout main
git checkout v1.1-stable  # tag da versão com Firebase funcionando
```

---

## 💰 Custos Planejados

| Item | Valor | Status |
|------|-------|--------|
| Google Play (taxa única) | ~R$ 130 (US$25) | ⏳ Pendente |
| Apple Developer (anual) | ~R$ 515 (US$99/ano) | ⏳ Pendente |
| Domínio para política de privacidade | Grátis (GitHub Pages) | ⏳ Pendente |
| Firebase Spark (gratuito até ~50k usuários) | Grátis | ✅ Em uso |

---

## 📝 Contas Demo para Testes

```
ana@demo.com      / 123456  (Ana Silva)
pedro@demo.com    / 123456  (Pedro Costa)
mariana@demo.com  / 123456  (Mariana Lima)
```

---

## 🔐 Firebase — Informações do Projeto

| Campo | Valor |
|-------|-------|
| Project ID | rateme-a1de6 |
| Auth Domain | rateme-a1de6.firebaseapp.com |
| Storage Bucket | rateme-a1de6.firebasestorage.app |
| Messaging Sender ID | 641618795234 |
| API Key | AIzaSyBy_5Kkopj7XHdhEeF6xJdU7SFkR-nwFBs |
| Android App ID | 1:641618795234:android:b3182f5a24028df412dcbb |
| Web App ID | 1:641618795234:web:79bc6e9ed4ac8e6d12dcbb |

**Domínios autorizados no Firebase Auth:**
- localhost
- rateme-a1de6.firebaseapp.com
- sandbox.novita.ai ← adicionado para preview

---

## 🗒️ Observações Finais

- O proprietário está no Brasil — comunicação em **português brasileiro**
- Decisões de design são do proprietário — respeitar preferências visuais
- Antes de qualquer alteração grande: **backup + branch separada + confirmar com proprietário**
- O proprietário valoriza: honestidade sobre limitações, explicações claras, sem surpresas
- Linguagem: direta, sem jargão técnico desnecessário
- Usar sempre **token GitHub classic** (ghp_...) — fine-grained não funciona

---

*Arquivo criado em: Junho/2025*
*Última atualização: Julho/2025*
*Versão do app: 1.0.0+1*
*Commit estável atual: 5b9a53e (PinZap com Firebase funcionando)*
*Tag estável: v1.0-stable (antes do Firebase)*
