# x-logo -- the Logo lang for x-lang
#
# Install copies this bundle to <share>/langs/logo, where `x -l` looks: a lang
# is installed when its files are there. No registry, no database.
#
#   make install                        into the x on PATH
#   PREFIX=$HOME/.local make install    into a particular prefix
#
# A pin (lang.pin.xon + Pin bundle) freezes a verified tarball for one project
# and is what a build should depend on. An install is one unversioned copy for
# the whole machine. Pin when the version matters; install to get `x -l logo`
# working.

X ?= x

# The version is derived from git describe, never committed: a version literal
# is true only at the commit it is tagged on and wrong on every commit after.
# lang.xon declares what this bundle requires; the installed artifact carries
# what it is, in a version stamp -- the same split as x-lang's own
# $(X_RELEASE) -> <lib>/contract/release.
LANG_VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
# PREFIX wins when given, so this matches x-lang's own `PREFIX=... make
# install`.  Otherwise ask the x on PATH where its tree is -- the question
# --share-dir exists to answer.
SHARE := $(if $(PREFIX),$(PREFIX)/share/x,$(shell $(X) --share-dir))
DEST  := $(SHARE)/langs/logo

# What a consumer needs to RUN the lang: the declaration, the entry, the
# modules -- and viewer.html, which is in logo/ with them.  That last file is
# why this bundle needed %lang-root: it is DATA, read at runtime and handed to
# a browser, and no `import` can express it.  Not the suite, not the tooling,
# not CI -- those are this repository's business, not the installed platform's.
PAYLOAD := lang.xon run.x logo

.PHONY: install
install: ## Install into <share>/langs/logo
	@test -n "$(SHARE)" || { echo "x-logo: cannot find an x tree -- set PREFIX or X" >&2; exit 1; }
	@test -d "$(SHARE)" || { echo "x-logo: no x tree at $(SHARE)" >&2; exit 1; }
	rm -rf "$(DEST)"
	mkdir -p "$(DEST)"
	cp -R $(PAYLOAD) "$(DEST)/"
	printf '%s\n' '$(LANG_VERSION)' > "$(DEST)/version"
	@echo "x-logo: installed to $(DEST)"
	@echo "x-logo: writing the boot image"
	"$(X)" --image -l logo || true
	@echo "x-logo: try  x -l logo"

.PHONY: uninstall
uninstall: ## Remove it again
	rm -rf "$(DEST)"
	@echo "x-logo: removed $(DEST)"

.PHONY: lint
lint: ## Lint the bundle's sources with the platform's linter
	X="$(X)" sh tests/lint.sh

.PHONY: test
test: ## Run the spec suite (heavy -- see tests/spec-runner.sh)
	X="$(X)" sh tests/spec-runner.sh

.PHONY: examples
examples: ## Run every example and check its pinned output
	X="$(X)" sh tests/examples.sh

# NOT IN `test`, and the reason is the environment rather than the code: these
# drive real ptys, which `make -j` and most CI containers do not provide.  It
# skips with a note where expect(1) is absent, and CI runs it as its own job.
.PHONY: tty
tty: ## Run the interactive-contract pty tests (needs expect)
	X="$(X)" sh tests/tty-runner.sh

.PHONY: bundle
bundle: ## Roll a release tarball and print its pin
	sh tools/bundle.sh

.PHONY: help
help: ## Show targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
