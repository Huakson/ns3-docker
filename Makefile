# ============================================================================
# NS-3 Docker Makefile - Simplified commands for common operations
# ============================================================================

.PHONY: help build up down shell run test clean clean-all logs ps

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

##@ General

help: ## Display this help message
	@echo "$(BLUE)NS-3 Docker - Available Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(GREEN)<target>$(NC)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Docker Operations

pull: ## Pull images from Docker Hub (try first, build if needed)
	@echo "$(BLUE)Pulling NS-3 images from Docker Hub...$(NC)"
	docker compose pull || echo "$(YELLOW)Pull failed, will build locally$(NC)"

build: ## Build Docker images
	@echo "$(BLUE)Building NS-3 Docker images...$(NC)"
	docker compose build --parallel

build-dev: ## Build development image with tools
	@echo "$(BLUE)Building NS-3 development image...$(NC)"
	docker compose build ns3-dev

rebuild: ## Rebuild images without cache
	@echo "$(BLUE)Rebuilding NS-3 Docker images (no cache)...$(NC)"
	docker compose build --no-cache --parallel

push: ## Push images to Docker Hub (single arch)
	@./scripts/docker-push --all

push-runtime: ## Push runtime image only (single arch)
	@./scripts/docker-push --runtime

push-dev: ## Push development image only (single arch)
	@./scripts/docker-push --dev

push-latest: ## Push and tag as latest (single arch)
	@./scripts/docker-push --all --latest

push-multiarch: ## Build and push multi-arch (amd64 + arm64)
	@./scripts/buildx-push --all --latest

push-multiarch-runtime: ## Build and push runtime multi-arch
	@./scripts/buildx-push --runtime

push-multiarch-dev: ## Build and push dev multi-arch
	@./scripts/buildx-push --dev

up: ## Start NS-3 container
	@echo "$(BLUE)Starting NS-3 container...$(NC)"
	docker compose up -d ns3
	@echo "$(GREEN)Container started!$(NC)"

down: ## Stop and remove containers
	@echo "$(BLUE)Stopping containers...$(NC)"
	docker compose down

restart: down up ## Restart containers

ps: ## Show running containers
	docker compose ps

logs: ## Show container logs
	docker compose logs -f ns3

##@ Development

shell: ## Open interactive shell in container
	@./scripts/ns3-shell

dev-shell: ## Open development shell with tools
	@echo "$(BLUE)Starting development environment...$(NC)"
	docker compose --profile dev up -d ns3-dev
	docker compose exec ns3-dev /bin/bash

watch: ## Watch for file changes and auto-rebuild
	@./scripts/ns3-watch

##@ NS-3 Operations

configure: ## Configure NS-3
	@echo "$(BLUE)Configuring NS-3...$(NC)"
	docker compose exec ns3 ./ns3 configure --enable-examples --enable-tests

ns3-build: ## Build NS-3 projects
	@./scripts/ns3-build

ns3-clean: ## Clean NS-3 build artifacts
	@./scripts/ns3-clean

run-example: ## Run example simulation (usage: make run-example SIM=wifi-simple)
	@if [ -z "$(SIM)" ]; then \
		echo "$(YELLOW)Usage: make run-example SIM=<simulation-name>$(NC)"; \
		exit 1; \
	fi
	@./scripts/ns3 run $(SIM)

test: ## Run NS-3 tests
	@echo "$(BLUE)Running NS-3 tests...$(NC)"
	docker compose exec ns3 ./test.py

##@ Batch Operations

batch: ## Run batch simulations (usage: make batch CMD="python3 scratch/sim2.py")
	@if [ -z "$(CMD)" ]; then \
		echo "$(YELLOW)Usage: make batch CMD=\"<command>\"$(NC)"; \
		exit 1; \
	fi
	@./scripts/ns3-batch $(CMD)

##@ Cleanup

clean: ## Clean build artifacts only
	@./scripts/ns3-clean

clean-results: ## Clean results directory
	@./scripts/ns3-clean --results

clean-all: ## Deep clean (build + results + Docker)
	@./scripts/ns3-clean --all

prune: ## Prune unused Docker resources
	@echo "$(YELLOW)Pruning unused Docker resources...$(NC)"
	docker system prune -f
	docker volume prune -f

##@ Utilities

status: ## Show system status
	@echo "$(BLUE)NS-3 Docker Status$(NC)"
	@echo ""
	@echo "$(YELLOW)Containers:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(YELLOW)Images:$(NC)"
	@docker images | grep ns3 || echo "No NS-3 images found"
	@echo ""
	@echo "$(YELLOW)Volumes:$(NC)"
	@docker volume ls | grep ns3 || echo "No NS-3 volumes found"

size: ## Show Docker image sizes
	@echo "$(BLUE)Docker Image Sizes$(NC)"
	@docker images | grep -E "^(REPOSITORY|ns3)" | grep -E "ns3|REPOSITORY"

inspect: ## Inspect NS-3 container
	docker compose exec ns3 ./ns3 --version
	@echo ""
	docker compose exec ns3 ls -lh /ns3/scratch

copy-results: ## Copy results to host (with timestamp)
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	mkdir -p backups; \
	cp -r results backups/results_$$TIMESTAMP; \
	echo "$(GREEN)Results backed up to: backups/results_$$TIMESTAMP$(NC)"

##@ Quick Start

init: pull up ## Initialize (pull from Docker Hub or build if needed)
	@echo "$(GREEN)NS-3 Docker is ready!$(NC)"
	@echo ""
	@echo "Try these commands:"
	@echo "  make shell          # Open interactive shell"
	@echo "  make run-example SIM=wifi-simple-adhoc"
	@echo "  make help           # Show all commands"

init-build: build up ## Initialize with local build (skip pull)
	@echo "$(GREEN)NS-3 Docker is ready!$(NC)"

demo: init ## Run demo simulation
	@echo "$(BLUE)Running demo simulation...$(NC)"
	@./scripts/ns3 run wifi-simple-adhoc
	@echo ""
	@echo "$(GREEN)Demo completed! Check results/ directory$(NC)"
