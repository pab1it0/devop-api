current_dir = $(shell pwd)
USER := $(shell id -u -n)
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
GIT_ROOT := $(shell git rev-parse --show-toplevel)

APP_HOST := 0.0.0.0
APP_PORT := 5400
devops_api_tag := latest
tf_version := 1.8.2

help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'


## install/tf: Install terraform
install/tf:
	curl -sL https://releases.hashicorp.com/terraform/$(tf_version)/terraform_$(tf_version)_$(OS)_amd64.zip -o /tmp/terraform.zip
	sudo unzip -o /tmp/terraform.zip -d /usr/local/bin/
	sudo chmod a+x /usr/local/bin/terraform
	terraform version

## cleanup: clean temp files and test containers
cleanup:
	@echo Cleaning up...
	-docker rm -f devops-api &> /dev/null

## build: Build local devops-api container
.ONESHELL:
build:
	@echo Building devops-api:$(devops_api_tag)
	docker build --force-rm -t devops-api:$(devops_api_tag) . || { ${MAKE} cleanup ; exit 1; };

## run: Run devops-api locally
run: cleanup build
	docker run -d --name devops-api -p $(APP_PORT):$(APP_PORT) -e PORT=$(APP_PORT) -e HOST=$(APP_HOST) devops-api:$(devops_api_tag) || { ${MAKE} cleanup ; exit 1; };
	docker logs -f devops-api || { ${MAKE} cleanup ; exit 1; };

## tffmt: Run terraform fmt
tffmt:
	@echo Running terraform fmt...
	terraform fmt -recursive -check --diff || { exit 1; };

## fix/tffmt: Run terraform fmt with automatic format fixing
fix/tffmt:
	@echo Running terraform fmt...
	terraform fmt -recursive --diff --write=true

## plan: Run terraform plan. example -> make plan env_id=prod-us-east-1
.ONESHELL:
plan: tffmt
	@echo "Running terraform plan..."
	cd $(GIT_ROOT)/devops-api/$(env_id)/ecr
	terraform init
	-@terraform workspace new $(env_id)
	-@terraform workspace select $(env_id)
	terraform plan -lock=false -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json"
	export TF_VAR_devops_api_image_name=some-repo:$(devops_api_tag)
	cd $(GIT_ROOT)/devops-api/$(env_id)/infra
	terraform init
	-@terraform workspace new $(env_id)
	-@terraform workspace select $(env_id)
	terraform plan -lock=false -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json"

## deploy: Run terraform apply. example -> make deploy env_id=prod-us-east-1
.ONESHELL:
deploy: tffmt
	@echo "Running terraform deploy..."
	# Deploy infra
	cd $(GIT_ROOT)/devops-api/$(env_id)/ecr
	terraform init
	-@terraform workspace new $(env_id)
	-@terraform workspace select $(env_id)
	terraform apply -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json" -auto-approve

	export ECR_REPO_URL=$$(terraform output -raw provision_api_ecr_repository_url)
	export AWS_ACCOUNT=$$(terraform output -raw aws_account)
	export AWS_REGION=$$(terraform output -raw aws_region)
	aws ecr get-login-password --region $$AWS_REGION | docker login --username AWS --password-stdin $$AWS_ACCOUNT.dkr.ecr.$$AWS_REGION.amazonaws.com
	docker tag devops-api:$(devops_api_tag) $$ECR_REPO_URL:$(devops_api_tag)
	docker push $$ECR_REPO_URL:$(devops_api_tag)

	export TF_VAR_devops_api_image_name=$$ECR_REPO_URL:$(devops_api_tag)
	cd $(GIT_ROOT)/devops-api/$(env_id)/infra
	terraform init
	-@terraform workspace new $(env_id)
	-@terraform workspace select $(env_id)
	terraform apply -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json" -auto-approve

## destroy: Run terraform destroy. example -> make destroy env_id=prod-us-east-1
.ONESHELL:
destroy:
	@echo "Running terraform destroy..."
	cd $(GIT_ROOT)/devops-api/$(env_id)/infra
	terraform init
	if terraform workspace select $(env_id) ; then
		echo "Workspace exists destroying infra resources..."
		terraform workspace select $(env_id)
		terraform destroy -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json" -auto-approve
	else
		echo "Workspace does not exist, skipping to next state"
	fi

	cd $(GIT_ROOT)/devops-api/$(env_id)/ecr
	terraform init
	if terraform workspace select $(env_id) ; then
		echo "Workspace exists destroying ecr resources..."
		terraform workspace select $(env_id)
		terraform destroy -compact-warnings -var-file="$(GIT_ROOT)/tfvars/$(env_id).tfvars.json" -auto-approve
	else
		echo "Workspace does not exist, skipping to next state"
	fi
	cd $(GIT_ROOT)&& ${MAKE} cleanup

.PHONY: cleanup build run tffmt fix/tffmt deploy destroy plan install/tf 