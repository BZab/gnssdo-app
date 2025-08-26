VENV    = ./.venv
PATHCACHE   = ./cache
PATHPYCACHE = ./__pycache__
REQUIREMENTS = ./requirements/base.txt
PYTHON = python3.6

ifeq ($(OS),Windows_NT)
  ifeq ($(shell uname -s),) # not in a bash-like shell
	DISABLE_HELP = "y"
	CLEANUP = del /F /Q
	RMRF = rd /S /Q
	MKDIR = mkdir
	RMDIR = rd /S /Q
	SOURCE = " " # Leave it empty
	VENVSUBDIR = Scripts
  else # in a bash-like shell, like msys
	CLEANUP = rm -f
	RMRF = $(CLEANUP) -r
	MKDIR = mkdir -p
	RMDIR = rmdir
	SOURCE = source
	VENVSUBDIR = Scripts
  endif
	TARGET_EXTENSION = exe
else
	CLEANUP = rm -f
	RMRF = $(CLEANUP) -r
	MKDIR = mkdir -p
	TARGET_EXTENSION = out
	SOURCE = .
	VENVSUBDIR = bin
endif

VENV_ACTIVATE = $(SOURCE) $(VENV)/$(VENVSUBDIR)/activate

# Paths portability in Makefiles among OSes:
# https://skramm.blogspot.com/2013/04/writing-portable-makefiles.html

## Show this help
.PHONY: help
help: _help


## -- General targets --

.PHONY: $(VENV)
$(VENV): $(VENV)/.touchfile

$(VENV)/.touchfile: $(REQUIREMENTS)
	test -d $(VENV) || $(PYTHON) -m venv $(VENV)
	$(VENV_ACTIVATE); $(PYTHON) -m pip install --upgrade pip
	$(VENV_ACTIVATE); $(PYTHON) -m pip install -Ur $(REQUIREMENTS)
	touch $(VENV)/.touchfile

## Init, setup
.PHONY: init
init: $(VENV)

## Run ipython shell in venv
.PHONY: ipython
ipython: $(VENV)
	$(VENV_ACTIVATE); ipython

## Run the graphical app
.PHONY: run
run: $(VENV)
	$(VENV_ACTIVATE); fbs run

.PHONY: freeze
freeze: $(VENV)
	$(VENV_ACTIVATE) && $(PYTHON) -m pip freeze > $(REQUIREMENTS)

.PHONY: pull
pull:
	git pull

## Update the local copy of repo
.PHONY: update
update: $(VENV) pull
	$(VENV_ACTIVATE); $(PYTHON) -m pip install --upgrade pip
	$(VENV_ACTIVATE); $(PYTHON) -m pip install -Ur $(REQUIREMENTS)

## General cleaning procedure
.PHONY: clean
clean:
	$(RMRF) $(VENV)
	$(RMRF) $(PATHCACHE)
	$(RMRF) $(PATHPYCACHE)

# https://gist.github.com/prwhite/8168133#gistcomment-2749866
.PHONY: _help
_help:
ifndef DISABLE_HELP
	@printf "Usage:\n";
	@printf "make <target_1> <target_2> <target_3> ...\n";
	@printf "\n";
	@printf "Target:               Description:\n";
	@printf "=======               ============\n";
	

	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":") - 1); \
				if (helpMessage) { \
					printf "\033[36m%-20s\033[0m %s\n", \
						helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n                     "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)
endif # ifdef DISABLE_HELP
# TODO Add else with fallback for windows

.DEFAULT_GOAL := help
