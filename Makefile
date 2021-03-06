UPSTREAM_REV = `git rev-parse upstream/master`
ORIGIN_REV   = `git rev-parse origin/master`
CURRENT_REV  = `git rev-parse HEAD`
RES_VERSION  ?= $(shell cat RES_VERSION)
NIX_TYPE     =  $(shell uname -s)
GEMS         = aggregate_root bounded_context ruby_event_store rails_event_store \
	           rails_event_store_active_record ruby_event_store_rom_sql \
						rails_event_store-browser rails_event_store-rspec

ifeq ($(NIX_TYPE),Linux)
  SED_OPTS = -i
endif

ifeq ($(NIX_TYPE),Darwin)
  SED_OPTS = -i ""
endif

$(addprefix install-, $(GEMS)):
	@make -C $(subst install-,,$@) install

$(addprefix test-, $(GEMS)):
	@make -C $(subst test-,,$@) test

$(addprefix mutate-, $(GEMS)):
	@make -C $(subst mutate-,,$@) mutate

$(addprefix build-, $(GEMS)):
	@make -C $(subst build-,,$@) build

$(addprefix push-, $(GEMS)):
	@make -C $(subst push-,,$@) push

$(addprefix clean-, $(GEMS)):
	@make -C $(subst clean-,,$@) clean

git-check-clean:
	@git diff --quiet --exit-code

git-check-committed:
	@git diff-index --quiet --cached HEAD

git-tag:
	@git tag -m "Version v$(RES_VERSION)" v$(RES_VERSION)
	@git push origin master --tags

git-rebase-from-upstream:
	@git remote remove upstream > /dev/null 2>&1 || true
	@git remote add upstream git@github.com:RailsEventStore/rails_event_store.git
	@git fetch upstream master
	@git rebase upstream/master
	@git push origin master

set-version: git-check-clean git-check-committed
	@echo $(RES_VERSION) > RES_VERSION
	@find . -name version.rb -exec sed $(SED_OPTS) "s/\(VERSION = \)\(.*\)/\1\"$(RES_VERSION)\"/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('ruby_event_store', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('rails_event_store_active_record', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('aggregate_root', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('rails_event_store-rspec', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('bounded_context', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('rails_event_store', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed $(SED_OPTS) "s/\('rails_event_store-browser', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@git add -A **/*.gemspec **/version.rb RES_VERSION
	@git commit -m "Version v$(RES_VERSION)"

install: $(addprefix install-, $(GEMS)) ## Install all dependencies

test: $(addprefix test-, $(GEMS)) ## Run all unit tests

mutate: $(addprefix mutate-, $(GEMS)) ## Run all mutation tests

build: $(addprefix build-, $(GEMS)) ## Build all gem packages

push: $(addprefix push-, $(GEMS)) ## Push all gem packages to RubyGems

clean: $(addprefix clean-, $(GEMS)) ## Remove all previously built packages

release: git-check-clean git-check-committed install test git-tag clean build push ## Make a new release on RubyGems
	@echo Released v$(RES_VERSION)

rebase: git-rebase-from-upstream
	@echo "Rebased with upstream/master"
	@echo "  upstream/master at $(UPSTREAM_REV)"
	@echo "  origin/master   at $(ORIGIN_REV)"
	@echo "  current branch  at $(CURRENT_REV)"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
