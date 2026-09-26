VENV ?= .venv
PYTHON ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
MKDOCS ?= $(VENV)/bin/mkdocs
DOCKER ?= docker
TOOLBOX ?= b2r-toolbox

RESOURCES ?= resources/
ADDR ?= 127.0.0.1:8081

.PHONY: build
build: $(VENV)
	$(MKDOCS) build --strict

.PHONY: serve
serve: $(VENV)
	$(MKDOCS) serve -a $(ADDR)

.PHONY: run-toolbox
run-toolbox: $(TOOLBOX)
	$(DOCKER) run --entrypoint /bin/bash -it --rm $(TOOLBOX)

$(VENV):
	python3 -m venv $(VENV)
	$(PIP) install --upgrade PIP
	$(PIP) install -r requirements.txt

.PHONY: deploy
deploy:
	./$(RESOURCES)setup.sh

.PHONY: $(TOOLBOX)
$(TOOLBOX): .FORCE
	@if ! docker image ls | grep -q $(TOOLBOX); then \
		echo "Image $TOOLBOX not found. Building..."; \
		$(DOCKER) build -t $(TOOLBOX) ./$(RESOURCES); \
	fi

.FORCE:

