current_dir = $(shell pwd)
USER := $(shell id -u -n)
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
GIT_ROOT := $(shell git rev-parse --show-toplevel)

env_id :=
host := 0.0.0.0
port := 5400
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
	docker run -d --name devops-api -p $(port):$(port) -e PORT=$(port) -e HOST=$(host) devops-api:$(devops_api_tag) || { ${MAKE} cleanup ; exit 1; };
	docker logs -f devops-api || { ${MAKE} cleanup ; exit 1; };

## tffmt: Run terraform fmt
tffmt:
	@echo Running terraform fmt...
	terraform fmt -recursive -check --diff || { exit 1; };

## fix/tffmt: Run terraform fmt with automatic format fixing
fix/tffmt:
	@echo Running terraform fmt...
	terraform fmt -recursive --diff --write=true

.ONESHELL:
deploy: tffmt
	@echo "Builing and deploying application resources..."
	cd $(GIT_ROOT)/terraform/provisioners/application
	terraform init
	terraform workspace select $(env_id) || terraform workspace new $(env_id)
	terraform apply -compact-warnings -var-file="$(GIT_ROOT)/terraform/provisioners/$(env_id).tfvars" -auto-approve
	@echo "Deployed successfully"
	export ECR_REPO_URL=$$(terraform output -raw devops_api_ecr_repository_url)
	export AWS_ACCOUNT=$$(terraform output -raw aws_account)
	export AWS_REGION=$$(terraform output -raw aws_region)

	@echo "Pushing devops-api:$(devops_api_tag) to ECR..."
	docker login -u AWS -p $(aws ecr get-login-password --region $$AWS_REGION) $$AWS_ACCOUNT.dkr.ecr.$$AWS_REGION.amazonaws.com
	docker tag devops-api:$(devops_api_tag) $$ECR_REPO_URL:$(devops_api_tag)
	docker push $$ECR_REPO_URL:$(devops_api_tag)
	export TF_VAR_devops_api_image_name=$$ECR_REPO_URL:$(devops_api_tag)
	export TF_VAR_devops_api_ecr_arn=$$(terraform output -raw ecr_repository_arn)

	@echo $$TF_VAR_devops_api_ecr_arn

	@echo "Deploying infra..."
	cd $(GIT_ROOT)/terraform/provisioners/infra
	terraform init
	terraform workspace select $(env_id) || terraform workspace new $(env_id)
	terraform apply -compact-warnings -var-file="$(GIT_ROOT)/terraform/provisioners/$(env_id).tfvars" -auto-approve
	export BUCKET_NAME=$$(terraform output -raw static_files_bucket_name)

	@echo "Uploading static files to S3..."
	cd $(GIT_ROOT)
	aws s3 sync $(GIT_ROOT)/public s3://$$BUCKET_NAME --delete
## destroy: Run terraform destroy. example -> make destroy env_id=prod-us-east-1
.ONESHELL:
destroy:
	@echo "Running terraform destroy..."
	cd $(GIT_ROOT)/devops-api/$(env_id)/infra
	terraform init
	if terraform workspace select $(env_id) ; then
		echo "Workspace exists destroying infra resources..."
		terraform workspace select $(env_id)
		terraform destroy -compact-warnings -var-file="$(GIT_ROOT)/terraform/provisioners/$(evn_id).tfvars/$(env_id).tfvars.json" -auto-approve
	else
		echo "Workspace does not exist, skipping to next state"
	fi

	cd $(GIT_ROOT)/devops-api/$(env_id)/ecr
	terraform init
	if terraform workspace select $(env_id) ; then
		echo "Workspace exists destroying ecr resources..."
		terraform workspace select $(env_id)
		terraform destroy -compact-warnings -var-file="$(GIT_ROOT)/terraform/provisioners/$(evn_id).tfvars/$(env_id).tfvars.json" -auto-approve
	else
		echo "Workspace does not exist, skipping to next state"
	fi
	cd $(GIT_ROOT)&& ${MAKE} cleanup

.PHONY: cleanup build run tffmt fix/tffmt deploy destroy install/tf 