VENV ?= .venv
PYTHON ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
MKDOCS ?= $(VENV)/bin/mkdocs
TOOLBOX ?= toolbox
PORT ?= 8000

.PHONY: build
build: $(VENV)
	$(MKDOCS) build --strict

.PHONY: serve
serve: $(VENV)
	$(MKDOCS) serve -a 127.0.0.1:$(PORT)

.PHONY: run-toolbox
run-toolbox: toolbox
	$(DOCKER) run  --entrypoint /bin/bash -it --rm -v ./resources:/mnt/resources $(TOOLBOX)

toolbox:
	@if ! docker image inspect $(TOOLBOX):latest >/dev/null 2>&1; then \
		docker build -t $(TOOLBOX):latest -f resources/Dockerfile .; \
	fi

$(VENV):
	python3 -m venv $(VENV)
	$(PIP) install --upgrade PIP
	$(PIP) install -r requirements.txt
