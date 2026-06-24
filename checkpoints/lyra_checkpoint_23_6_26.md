# Lyra — Checkpoint técnico
> Your Cosmic Companion · Junio 2026

---

## ¿Qué es Lyra?

Lyra es un asistente de IA de código abierto para GNU/Linux, diseñado para reducir la curva de aprendizaje de usuarios que inician en Linux. Funciona completamente offline usando modelos de lenguaje ligeros (SLMs) que corren en el propio equipo del usuario, sin telemetría ni dependencia de servicios en la nube.

La inspiración del nombre viene de la constelación Lyra, que representa la lira de Orfeo en la mitología griega. El tagline oficial es **"Your Cosmic Companion"**.

El proyecto ha sido destacado por MinTic Colombia en dos entrevistas públicas:
- [Ingenieros en Pereira desarrollan asistente de IA para programar código abierto](https://www.youtube.com/watch?v=KLSnCxgulKw)
- [Dos ingenieros en Pereira crean herramienta de IA – Ep.32 2024](https://www.youtube.com/watch?v=eayh7u85Jhk)

---

## Repositorios

El proyecto está dividido en tres repos independientes bajo la organización `lyra-ai-assistant`:

| Repo | Descripción |
|------|-------------|
| `lyra-server` | Backend Python — servidor HTTP + socket Unix + modelo LLM |
| `lyra-ui` | Frontend Electron — cliente de escritorio para GNU/Linux |
| `lyra-packaging` | Infraestructura de packaging para Arch y Debian |

Los tres repos se clonan por separado. `lyra-packaging` incluye a `lyra-server` y `lyra-ui` como subdirectorios (no como submódulos git).

---

## Arquitectura general

```
Usuario
  │
  ├── lyra-ui (Electron)
  │     └── IPC → main.js → lyraSocket.js
  │                              │
  │                         Unix socket (~/.local/share/lyra/lyra.sock)
  │                              │
  └── lyra -q "..."  ────────────┘
                                 │
                          lyra-server (Python daemon)
                                 │
                    ┌────────────┴─────────────┐
                    │                           │
             HTTP :4000                   Unix socket
             (FastAPI/uvicorn)         (asyncio server)
                    │                           │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────┴─────────────┐
                    │                           │
             GenerationAgent            KnowledgeResolver
             (llama-cpp-python)      (pacman/apt + wiki + PyPI)
             Qwen2.5-1.5B Q4_K_M
```

El daemon expone dos interfaces simultáneas:
- **Unix socket** — usado por el CLI (`lyra -q`) y por Electron vía `lyraSocket.js`
- **HTTP en localhost:4000** — usado por la API REST de FastAPI (endpoint `/chat` con streaming)

---

## lyra-server

### Stack
- **Python 3.13** gestionado con `uv`
- **FastAPI** + **uvicorn** para la API HTTP
- **llama-cpp-python** para inferencia local (compilado según GPU disponible)
- **ChromaDB** + **ONNXMiniLM** para memoria semántica (embeddings sin torch)
- **SQLite** para historial de sesiones

### Modelo
Actualmente **Qwen2.5-1.5B Instruct Q4_K_M** (GGUF). El modelo puede cambiar en futuras versiones. Se descarga en `~/.local/share/lyra/models/` mediante `lyra-install-backend`, que detecta NVIDIA/ROCm/Intel/CPU y compila `llama-cpp-python` con las flags correctas. `n_gpu_layers=0` por defecto porque Vulkan crashea en GPUs Vega 8 integradas.

### Estructura de carpetas

```
lyra/
├── agents/
│   ├── GenerationAgent.py   # Wrapper de llama-cpp-python
│   └── constants.py         # Rutas del modelo y kwargs de generación
├── api/
│   ├── dependencies.py      # Instancia global del agente
│   └── routers/
│       ├── chat.py          # POST /chat (streaming SSE)
│       └── health.py        # GET /health
├── cli/
│   ├── commands.py          # Entry point: lyra serve/stop/status/-q/config/profile
│   ├── client.py            # Cliente Unix socket para lyra -q
│   ├── config_cmd.py        # lyra config get/set/list
│   └── daemon.py            # Fork doble, PID, Unix socket server, signal handlers
├── config/
│   └── env_vars.py          # host, apiPort, mode, verbose
├── context/
│   └── manager.py           # SessionManager — SQLite, TTL 30min
├── db/
│   └── connection.py        # Conexión SQLite
├── knowledge/
│   ├── apt.py               # Búsqueda en apt-cache
│   ├── cargo.py             # Búsqueda en crates.io
│   ├── npm.py               # Búsqueda en npm registry
│   ├── pacman.py            # Búsqueda en pacman
│   ├── pypi.py              # Búsqueda en PyPI
│   ├── resolver.py          # Orquesta búsquedas en paralelo (ThreadPoolExecutor)
│   └── wiki.py              # Arch Wiki / Gentoo Wiki scraping
├── memory/
│   └── semantic.py          # ChromaDB + ONNXMiniLM para memoria semántica
├── scripts/
│   └── install_backend.py   # Detecta GPU e instala llama-cpp-python
├── services/
│   └── chat.py              # _try_direct_answer, handle_chat, persist_stream
├── templates/
│   └── config.json          # Config por defecto
├── tools/
│   ├── ecosystem.py         # Detecta python/node/rust/go/docker/flatpak
│   ├── linux.py             # disk/memory/cpu/processes + build_system_ctx
│   └── packages.py          # get_installed_packages, get_relevant_packages
└── util/
    ├── base_models.py
    ├── context_window.py    # trim_history para no exceder el contexto del modelo
    ├── dirs.py
    ├── formatting.py        # clean_response, to_html
    ├── profile.py           # ~/.config/lyra/profile.json (os, distro, pkg_mgr, arch)
    └── token_budget.py      # compute_max_tokens() según RAM disponible
```

### Runtime files

```
~/.config/lyra/config.json       # host, apiPort, mode, verbose
~/.config/lyra/profile.json      # os, distro, package_manager, arch, ecosystems
~/.local/share/lyra/models/      # qwen2.5-1.5b-instruct-q4_k_m.gguf
~/.local/share/lyra/venv/        # venv con llama-cpp-python
~/.local/share/lyra/chroma/      # ChromaDB embeddings
~/.local/share/lyra/lyra.sock    # Unix socket
~/.local/share/lyra/lyra.pid
~/.local/share/lyra/lyra.log
~/.local/share/lyra/lyra.db      # SQLite (sesiones + mensajes)
```

### CLI

```bash
lyra serve                  # foreground
lyra serve --daemon         # background (double fork)
lyra stop
lyra status
lyra -q "texto"
lyra config get/set/list
lyra profile show/refresh
lyra uninstall
lyra --version
```

### Flujo de una query por socket

1. `daemon.py` recibe `{"query": "...", "session_id": "..."}` por Unix socket
2. Recupera historial de sesión desde SQLite via `session_manager`
3. Extrae términos de búsqueda usando el modelo (few-shot, 20 tokens max)
4. `resolver.py` busca en paralelo: pacman/apt + wiki + ecosistemas (solo si query es dev)
5. `_try_direct_answer` intenta responder directamente desde el resolver sin pasar por el modelo:
   - Query de instalación → devuelve comando `pacman -S <paquete>`
   - Query de verificación ("¿tenemos X instalado?") → devuelve sí/no + comando
6. Si no hay respuesta directa, pasa al modelo con el contexto del resolver + historial
7. Persiste el intercambio en SQLite y devuelve `{"response": "...", "session_id": "..."}`

### Decisiones técnicas clave

- **llama-cpp-python en lugar de transformers** — soporta todas las GPUs sin compilación específica por backend
- **ONNXMiniLM en lugar de sentence-transformers** — elimina torch como dependencia (ChromaDB embeddings)
- **`_try_direct_answer`** — evita alucinaciones en queries de instalación respondiendo directamente desde el resolver
- **`_is_user_package`** en `resolver.py` — filtra paquetes de desarrollo (`lib*-`, `python-*`, `*-dev`) para no contaminar respuestas a usuarios no técnicos. Excepción explícita para `libre*` (libreoffice, librespot)
- **`SO_REUSEADDR`** en el socket HTTP — evita "Address already in use" entre reinicios rápidos del daemon
- **`session_id`** pasado por el protocolo socket — permite mantener contexto conversacional entre queries desde Electron y CLI

---

## lyra-ui

### Stack
- **Electron 30.5.1** con **electron-builder** para packaging
- **Node.js 20** con módulos ES (`type: module`)
- **pnpm** como gestor de paquetes
- **markdown-it** para renderizar respuestas del modelo en HTML
- **Chart.js** para widgets de métricas (RAM, CPU, Disk)
- Sin bundler (Webpack/Vite) — Electron vanilla con ES modules

### Estructura de carpetas

```
lyra-ui/
├── assets/              # Íconos y logo
├── eventHandlers/
│   ├── main.js          # Entry point del renderer — registra todos los listeners
│   ├── prompt.js        # handlePrompt, createMessage (con botón "Copiar")
│   ├── navbar.js        # addChat, prevChat, nextChat, deleteChat
│   ├── widget.js        # Charts de RAM/CPU/Disk
│   ├── window.js        # loadDefaults
│   └── daemonStatus.js  # Toast de estado del daemon
├── OS/
│   ├── RAM.js
│   ├── CPU.js
│   └── Disk.js
├── preloader/
│   └── preload.js       # contextBridge — expone electron API al renderer
├── scripts/             # Scripts de build
├── server/
│   └── lyraSocket.js    # Conexión al Unix socket del daemon
├── styles/
│   ├── main.css         # Imports de todos los CSS
│   ├── message.css      # Estilos de mensajes + bloques de código + botón copiar
│   └── ...
├── templates/           # HTML base
├── utils/
│   ├── config.js
│   └── storageHandler.js
├── index.html
└── main.js              # Proceso principal Electron — IPC handlers, BrowserWindow
```

### IPC handlers (main.js)

| Handler | Descripción |
|---------|-------------|
| `send-query` | Envía query al daemon, recibe respuesta, aplica `md.render()` |
| `get-ram-usage` | Métricas de RAM |
| `get-cpu-usage` | Métricas de CPU |
| `get-disk-usage` | Métricas de disco |
| `retry-daemon` | Reintenta conexión al daemon |
| `new-chat` | Llama `resetSession()` en lyraSocket para limpiar session_id |

### Protocolo socket (lyraSocket.js)

- Request: `JSON {"query": "...", "session_id": "..."}` → half-close (FIN)
- Response: `JSON {"response": "...", "session_id": "..."}` → read until EOF
- `_sessionId` se retiene en memoria entre queries de la misma ventana
- `resetSession()` se llama al crear un chat nuevo
- Timeouts: conexión 10s, query 60s
- Retry automático si el daemon muere durante una query

---

## lyra-packaging

### Propósito
Infraestructura para distribuir Lyra como paquete nativo en Arch Linux y Debian/Ubuntu. Los scripts generan artefactos listos para subir a repositorios oficiales.

### Estructura

```
lyra-packaging/
├── packages/
│   ├── arch/lyra/
│   │   ├── PKGBUILD         # Paquete unificado lyra 1.1.0
│   │   └── lyra.install     # Mensaje post-install
│   └── debian/lyra/
│       └── DEBIAN/
│           ├── control
│           └── postinst
├── scripts/
│   ├── build-app.sh         # Genera artifacts (binarios)
│   ├── build-arch.sh        # Construye .pkg.tar.zst
│   ├── build-deb.sh         # Construye .deb
│   ├── pip_installer.sh     # Detecta uv > pip > pip3
│   └── deb_builder.py       # Construye .deb sin dpkg-deb (Python puro)
├── artifacts/               # Binarios generados
├── dist/                    # Paquetes finales
├── lyra-server/             # Subdir (repo independiente)
├── lyra-ui/                 # Subdir (repo independiente)
└── manifests/
```

### Artefactos verificados

- `lyra-1.1.0-1-x86_64.pkg.tar.zst` (Arch)
- `lyra_1.1.0-1_amd64.deb` ~187MB (Debian — grande por chromadb + onnxruntime + grpcio)

### Versionado

- `lyra-server`: 0.1.0
- `lyra-ui`: 0.1.0
- Paquete combinado: 1.1.0 (versionado independiente)

### Dependencias Python vendoreadas

Las deps que no existen en repos oficiales de Arch ni Debian (chromadb, huggingface-hub, etc.) se instalan en `/usr/lib/lyra/vendor` via `pip install --target`.

### Distribución pendiente

- **Arch**: publicar en AUR apuntando a GitHub Releases
- **Debian/Ubuntu**: repositorio APT mínimo en GitHub Pages con `Packages.gz`, `Release` y `Release.gpg`

```bash
# Flujo de instalación objetivo (apt)
curl -fsSL https://lyra-ai-assistant.github.io/lyra-packaging/KEY.gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/lyra.gpg
echo "deb [signed-by=/etc/apt/keyrings/lyra.gpg] \
  https://lyra-ai-assistant.github.io/lyra-packaging stable main" \
  | sudo tee /etc/apt/sources.list.d/lyra.list
sudo apt update && sudo apt install lyra
```

---

## Instalación para desarrollo

```bash
# Backend
cd lyra-server
uv tool install . --force

# Verificar instalación del modelo
lyra-install-backend

# Arrancar daemon
lyra serve --daemon
lyra status

# Frontend
cd lyra-ui
pnpm install
pnpm start
```

> Después de cualquier cambio en `lyra-server` hay que reinstalar:
> ```bash
> cd lyra-server && uv tool install . --force
> ```

---

## Estado actual (Junio 2026)

### Resuelto en esta sesión

| # | Problema | Solución |
|---|----------|----------|
| 1 | Markdown no renderizaba en Electron | Estilos CSS para `pre`/`code` en `message.css` + botón copiar |
| 2 | "¿Y para office?" respondía `gedit` | Historial de sesión pasado al extractor de términos en `daemon.py` |
| 3 | Socket handler stateless | `session_id` en protocolo socket, `session_manager` en handler |
| 4 | Logs de debug en producción | Eliminados `[DEBUG]` prints de `services/chat.py` y `daemon.py` |
| 5 | Puerto 4000 ocupado entre reinicios | `SO_REUSEADDR` + `server.serve(sockets=[sock])` en `commands.py` |
| 6 | `_try_direct_answer` sin contexto | Resuelto junto con #2 y #3 |
| 7 | `libreoffice` filtrado por `_is_user_package` | Fix en `resolver.py`: `not name.startswith("libre")` |
| 8 | CLI imprimía JSON crudo | `client.py` parsea `{"response": ..., "session_id": ...}` |
| 9 | Query de verificación ("¿tenemos X?") | `_CHECK_KEYWORDS` + rama separada en `_try_direct_answer` |

### Pendiente

- Tests automatizados (post v1.0)
- Repositorio APT y entrada AUR
- Verificar si ChromaDB/memoria semántica está activa en producción
- Extractor de términos con few-shot (Qwen2.5-1.5B ignora "ONLY terms" y formatea como lista web)
- Persistencia de `session_id` entre invocaciones de `lyra -q` (actualmente stateless entre procesos)
