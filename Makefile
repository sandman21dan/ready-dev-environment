.PHONY: lint format lint-with-docker format-with-docker help

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

lint: ## Check YAML files for formatting issues using locally installed prettier
	@echo "Checking YAML files formatting..."
	prettier --check "**/*.{yaml,yml}"

format: ## Format YAML files using locally installed prettier
	@echo "Formatting YAML files..."
	prettier --write "**/*.{yaml,yml}"

lint-with-docker: ## Check YAML files for formatting issues using Docker (no local dependencies required)
	@echo "Checking YAML files formatting with Docker..."
	docker run --rm -v $(PWD):/work tmknom/prettier --check "**/*.{yaml,yml}"

format-with-docker: ## Format YAML files using Docker (no local dependencies required)
	@echo "Formatting YAML files with Docker..."
	docker run --rm -v $(PWD):/work tmknom/prettier --write "**/*.{yaml,yml}"