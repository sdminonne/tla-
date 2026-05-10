INSTALL_DIR := $(CURDIR)
BIN_DIR     := $(INSTALL_DIR)/bin
LIB_DIR     := $(INSTALL_DIR)/lib

TLA2TOOLS_JAR           := $(LIB_DIR)/tla2tools.jar
COMMUNITY_MODULES_JAR   := $(LIB_DIR)/CommunityModules-deps.jar

TLA2TOOLS_URL           := https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar
COMMUNITY_MODULES_URL   := https://github.com/tlaplus/CommunityModules/releases/latest/download/CommunityModules-deps.jar

JAVA_MIN_VERSION := 11

.PHONY: check-prereq install clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

check-prereq: ## Check that java (>= 11) and python3 are available
	@echo "Checking prerequisites..."
	@command -v java >/dev/null 2>&1 || { echo "ERROR: java not found. Install Java >= $(JAVA_MIN_VERSION)."; exit 1; }
	@java_version=$$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+)(\.[0-9]+)*.*/\1/'); \
	if [ "$$java_version" -lt $(JAVA_MIN_VERSION) ] 2>/dev/null; then \
		echo "ERROR: Java >= $(JAVA_MIN_VERSION) required, found version $$java_version."; exit 1; \
	fi; \
	echo "  java: OK (version $$java_version)"
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found."; exit 1; }
	@python3_version=$$(python3 --version 2>&1 | sed -E 's/Python //'); \
	echo "  python3: OK (version $$python3_version)"
	@echo "All prerequisites satisfied."

install: check-prereq ## Download TLA+ tools and create wrapper scripts
	@mkdir -p $(BIN_DIR) $(LIB_DIR)
	@echo "Downloading tla2tools.jar..."
	curl -fSL -o $(TLA2TOOLS_JAR) $(TLA2TOOLS_URL)
	@echo "Downloading CommunityModules-deps.jar..."
	curl -fSL -o $(COMMUNITY_MODULES_JAR) $(COMMUNITY_MODULES_URL)
	@echo "Creating wrapper scripts in $(BIN_DIR)..."
	@printf '#!/usr/bin/env bash\nexec java -XX:+UseParallelGC -cp "%s:%s" tlc2.TLC "$$@"\n' \
		"$(TLA2TOOLS_JAR)" "$(COMMUNITY_MODULES_JAR)" > $(BIN_DIR)/tlc
	@chmod +x $(BIN_DIR)/tlc
	@printf '#!/usr/bin/env bash\nexec java -cp "%s:%s" tla2sany.SANY "$$@"\n' \
		"$(TLA2TOOLS_JAR)" "$(COMMUNITY_MODULES_JAR)" > $(BIN_DIR)/sany
	@chmod +x $(BIN_DIR)/sany
	@printf '#!/usr/bin/env bash\nexec java -cp "%s:%s" pcal.trans "$$@"\n' \
		"$(TLA2TOOLS_JAR)" "$(COMMUNITY_MODULES_JAR)" > $(BIN_DIR)/pcal
	@chmod +x $(BIN_DIR)/pcal
	@printf '#!/usr/bin/env bash\nexec java -cp "%s:%s" tla2tex.TLA "$$@"\n' \
		"$(TLA2TOOLS_JAR)" "$(COMMUNITY_MODULES_JAR)" > $(BIN_DIR)/tla2tex
	@chmod +x $(BIN_DIR)/tla2tex
	@printf '#!/usr/bin/env bash\nexec java -cp "%s:%s" tlc2.REPL "$$@"\n' \
		"$(TLA2TOOLS_JAR)" "$(COMMUNITY_MODULES_JAR)" > $(BIN_DIR)/tlcrepl
	@chmod +x $(BIN_DIR)/tlcrepl
	@echo ""
	@echo "Installation complete. Add the following to your shell profile:"
	@echo ""
	@echo "  export PATH=\"$(BIN_DIR):\$$PATH\""
	@echo ""
	@echo "Available commands: tlc, sany, pcal, tla2tex, tlcrepl"

clean: ## Remove downloaded jars and wrapper scripts
	rm -rf $(BIN_DIR) $(LIB_DIR)
