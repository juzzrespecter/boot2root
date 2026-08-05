VENV ?= .venv
PYTHON ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
MKDOCS ?= $(VENV)/bin/mkdocs

.PHONY: build
build: $(VENV)
	$(MKDOCS) build --strict

.PHONY: serve
serve: $(VENV)
	$(MKDOCS) serve

$(VENV):
	python3 -m venv $(VENV)
	$(PIP) install --upgrade PIP
	$(PIP) install -r requirements.txt
