.PHONY: help install build
.DEFAULT_GOAL= help

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-10s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

init: ## Initialize a new or existing Terraform working directory by creating initial files
	terraform init

validate: ## Validate configuration files
	terraform validate

plan: init validate ## Generates an execution plan for Terraform.
	terraform plan

apply: plan ## Builds or changes infrastructure according to Terraform configuration files in DIR.
	terraform apply -auto-approve

destroy: ## Destroy Terraform-managed infrastructure.
	terraform destroy

clean:  ## Clean unused
	rm -rf .terraform
	rm -rf **/.terraform
