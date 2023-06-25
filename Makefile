BACKEND?=dockerv3
CONCURRENCY?=1
CI_ARGS?=
PACKAGES?=

# Abs path only. It gets copied in chroot in pre-seed stages
export LUET?=/usr/bin/luet-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/build
COMPRESSION?=zstd
export TREE?=$(ROOT_DIR)/packages
REPO_CACHE?=quay.io/geaaru/security-amd64-cache
export REPO_CACHE
BUILD_ARGS?=--pull --no-spinner
GENIDX_ARGS?=--only-upper-level --compress=false
SUDO?=
VALIDATE_OPTIONS?=
ARCH?=amd64
REPO_NAME?=macaroni-security
REPO_DESC?=Macaroni OS Security Phoenix
REPO_URL?=https://dl.macaronios.org/repos/macaroni-security/
REPO_VALUES?=values/amd64.yaml
export REPO_VALUES

ifneq ($(strip $(REPO_CACHE)),)
	BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

ifneq ($(strip $(REPO_VALUES)),)
  BUILD_ARGS+=--values $(REPO_VALUES)
endif

.PHONY: all
all: build

.PHONY: clean
clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: genidx
genidx:
	$(SUDO) $(LUET) tree genidx $(GENIDX_ARGS) --tree=$(TREE)

.PHONY: create-repo
create-repo: genidx
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(DESTINATION) \
    --packages $(DESTINATION) \
    --name "$(REPO_NAME)" \
    --descr "$(REPO_DESC) $(ARCH)" \
    --urls "$(REPO_URL)" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar \
    --meta-compression $(COMPRESSION) \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(DESTINATION)

autobump: auto-bump

repository:
	mkdir -p $(ROOT_DIR)/repository

repository/mottainai:
	git clone -b master --single-branch https://github.com/MottainaiCI/repo-stable $(ROOT_DIR)/repository/mottainai

repository/macaroni-commons:
	git clone -b master --single-branch https://github.com/funtoo/macaroni-commons $(ROOT_DIR)/repository/macaroni-commons

repository/macaroni-funtoo:
	git clone -b master --single-branch https://github.com/funtoo/macaroni-funtoo $(ROOT_DIR)/repository/macaroni-funtoo

validate: repository repository/mottainai repository/macaroni-commons repository/macaroni-funtoo
	$(LUET) tree validate --tree $(ROOT_DIR)/repository --tree $(TREE) $(VALIDATE_OPTIONS)
