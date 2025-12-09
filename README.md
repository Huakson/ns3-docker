# 🐳 NS-3.42 Docker - Network Simulator Container

**Complete Docker solution for NS-3 (Network Simulator 3)** with pre-built images, easy-to-use scripts, batch processing, and multi-architecture support.

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-huakson%2Fns3--simulator-blue)](https://hub.docker.com/r/huakson/ns3-simulator)
[![NS-3 Version](https://img.shields.io/badge/NS--3-3.42-green)](https://www.nsnam.org/)
[![Alpine Linux](https://img.shields.io/badge/Alpine-3.19-0D597F)](https://alpinelinux.org/)
[![Size](https://img.shields.io/badge/Size-978MB-orange)](https://hub.docker.com/r/huakson/ns3-simulator)
[![Multi-Arch](https://img.shields.io/badge/Arch-amd64%20|%20arm64-lightgrey)](https://hub.docker.com/r/huakson/ns3-simulator/tags)

---

## 🌟 Features

- ✅ **Pre-built Docker images** - No 30-minute compilation, just pull and run!
- ✅ **Multi-stage Alpine-based** - Optimized image size (~978MB vs 2GB+)
- ✅ **Multi-Architecture** - Native support for **Intel/AMD** (amd64) and **Apple M1/M2** (arm64)
- ✅ **Simple wrapper scripts** - No need to remember Docker commands
- ✅ **Volume mapping** - Easy input/output with host filesystem
- ✅ **Multiple modes** - Runtime, Development, Batch processing
- ✅ **Auto-rebuild watch mode** - Development with hot-reload
- ✅ **Makefile shortcuts** - One command for everything

---

## 📋 Prerequisites

- **Docker Engine** 20.10+ ([Install Docker](https://docs.docker.com/engine/install/))
- **Docker Compose** 2.0+ (included in modern Docker)
- **Make** (optional, for shortcuts)
- **4GB RAM** minimum, 8GB recommended

### Quick Install Docker (Ubuntu/Debian)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

---

## 🚀 Quick Start (For End Users)

### Option 1: Using Make (Recommended)

```bash
# Clone repository
git clone <your-repo-url>
cd ns3-docker

# Pull pre-built image and start (Automatic!)
make init

# Open shell inside container
make shell

# Inside container:
./ns3 run wifi-simple
```

### Option 2: Docker Compose

```bash
# Pull and start
docker compose pull
docker compose up -d ns3

# Run simulation
docker compose exec ns3 ./ns3 run wifi-simple
```

---

## 📁 Directory Structure

```
ns3-docker/
├── Dockerfile              # Multi-stage Alpine image definition
├── docker-compose.yml      # Service orchestration
├── .env                    # Configuration variables
├── Makefile               # Convenient shortcuts
│
├── scripts/               # 🔧 Wrapper scripts
│   ├── ns3               # Main NS-3 executor
│   ├── ns3-build         # Build simulations
│   ├── ns3-shell         # Interactive shell
│   ├── ns3-batch         # Batch processing
│   ├── ns3-watch         # Auto-rebuild on changes
│   ├── ns3-clean         # Clean artifacts
│   ├── docker-push       # Push to Docker Hub
│   └── buildx-push       # Multi-arch build & push
│
├── scratch/              # 📝 YOUR simulation scripts (.cc files)
│   └── (put your .cc files here)
│
├── results/              # 📊 Output files (CSV, logs, pcap)
│   └── logs/
│
├── contrib/              # 🧩 Custom NS-3 modules (optional)
│
└── examples/             # 📚 Example simulations
    ├── wifi-simple.cc
    └── batch-example.py
```

---

## 🎯 Usage Modes

### Mode 1: Quick Execution

Run a simulation and see results immediately:

```bash
./scripts/ns3 run "wifi-simple --distance=100 --time=20"

# Results saved to results/
ls -lh results/
```

### Mode 2: Interactive Shell

Enter the container for manual work:

```bash
./scripts/ns3-shell

# Inside container:
./ns3 configure --enable-examples
./ns3 build
./ns3 run wifi-simple-adhoc
exit
```

### Mode 3: Batch Processing

Run multiple simulations automatically (e.g., parameter sweep):

```bash
# Copy batch script to scratch/
cp examples/batch-example.py scratch/

# Run batch
./scripts/ns3-batch python3 scratch/batch-example.py

# Check results
ls -lh results/*.csv
```

### Mode 4: Development with Auto-Rebuild (Watch Mode)

Watch for file changes and rebuild automatically:

```bash
# Terminal 1: Start watch mode
./scripts/ns3-watch

# Terminal 2: Edit files
vim scratch/my-simulation.cc
# Save file → Container auto-rebuilds!

# Terminal 3: Test
./scripts/ns3 run my-simulation
```

### Mode 5: Development Environment (Jupyter + Tools)

Full dev environment with Jupyter, gdb, valgrind:

```bash
# Start dev container
make dev-shell

# Access Jupyter at http://localhost:8888
```

---

## 🐳 Docker Hub & Image Maintenance

**Repository:** [`huakson/ns3-simulator`](https://hub.docker.com/r/huakson/ns3-simulator)

| Tag | Architecture | Size | Purpose |
|-----|--------------|------|---------|
| `3.42-runtime` | amd64, arm64 | 978MB | Production simulations |
| `latest` | amd64, arm64 | 978MB | Same as runtime |
| `3.42-dev` | amd64, arm64 | ~1.2GB | Development with tools |

### For Maintainers: Build & Push Workflow

If you want to update the images on Docker Hub:

#### 1. Setup

Edit `.env` to set your Docker Hub username:
```bash
DOCKER_USERNAME=your-username
DOCKER_REPO=ns3-simulator
```

#### 2. Build & Push (Single Arch - amd64)

Fastest method if you only support Intel/AMD:
```bash
docker login
make build         # Build locally
make push-latest   # Push to Docker Hub
```

#### 3. Build & Push (Multi-Arch - amd64 + arm64)

To support both Intel/AMD and Apple M1/M2:
```bash
docker login
make push-multiarch
```
*Note: This takes ~20-30 minutes as it builds for both architectures using QEMU emulation.*

### Security Notes

1. **Never commit `.env` with credentials**.
2. **Use Access Tokens**: Instead of your password, use a Docker Hub Access Token (`Account Settings -> Security`).
   ```bash
   docker login -u username -p YOUR_TOKEN
   ```

---

## 🌍 Multi-Architecture Support

This project supports **multi-architecture builds**, meaning the same image tag works on different hardware:

- ✅ **Intel/AMD (amd64)**: Standard Linux servers, Windows WSL2, older Macs.
- ✅ **Apple Silicon (arm64)**: MacBook M1/M2/M3.
- ✅ **ARM Servers (arm64)**: AWS Graviton, Raspberry Pi 4+.

### How it works
When a user runs `make init`, Docker automatically detects their CPU architecture and pulls the correct image layer.

### Creating Multi-Arch Images
Use the provided script:
```bash
./scripts/buildx-push --all --latest
```
This builds separate images for amd64 and arm64, then pushes a "manifest list" that points to both.

---

## ⚙️ Configuration (.env)

Customize your environment by editing `.env`:

```bash
# Docker Hub Settings
DOCKER_USERNAME=huakson
DOCKER_REPO=ns3-simulator

# NS-3 Build Settings
NS3_VERSION=3.42
NS3_BUILD_PROFILE=optimized
NS3_JOBS=4

# User/Group (Match host user to avoid permission issues)
NS3_UID=1000  # run: id -u
NS3_GID=1000  # run: id -g

# Directories
SCRATCH_DIR=./scratch
RESULTS_DIR=./results

# Resource Limits
NS3_CPU_LIMIT=4.0
NS3_MEM_LIMIT=4G
```

---

## 🛠️ Common Commands

### Using Scripts (Direct)

```bash
# Run simulation
./scripts/ns3 run <simulation> [args]

# Build project
./scripts/ns3-build [target]

# Open shell
./scripts/ns3-shell

# Watch mode
./scripts/ns3-watch [target]

# Clean artifacts
./scripts/ns3-clean [--all]
```

### Using Makefile (Shortcuts)

| Command | Description |
|---------|-------------|
| `make init` | Pull images and start container |
| `make shell` | Open interactive shell |
| `make ns3-build` | Build simulations |
| `make run-example SIM=name` | Run specific example |
| `make batch CMD="..."` | Run batch processing |
| `make clean-all` | Clean build, results, and containers |
| `make status` | Show container status |
| `make push-multiarch` | Build & push for amd64 + arm64 |

---

## 🔧 Troubleshooting

### "ninja: no work to do"
This is **good**! It means your code is already compiled and up-to-date.

### Pull Fails
```bash
# Check internet
ping docker.io
# Try manual pull
docker pull huakson/ns3-simulator:3.42-runtime
# If all else fails, build locally
make build
```

### Permission Issues (Linux)
If you can't edit files in `results/`:
```bash
# Edit .env and set your UID/GID
NS3_UID=1000
NS3_GID=1000
# Restart
make restart
```

### Build Fails on Apple M1 (arm64)
If building locally fails, try using the pre-built image (ensure you pulled `huakson/ns3-simulator`).
If you MUST build locally:
```bash
# Ensure Rosetta is enabled or use buildx
make build
```

---

## 📄 License

This Docker setup is provided under the MIT License.
NS-3 is licensed under GNU GPLv2.

---

**Made with ❤️ for NS-3 researchers**
**Docker Hub:** [`huakson/ns3-simulator`](https://hub.docker.com/r/huakson/ns3-simulator)