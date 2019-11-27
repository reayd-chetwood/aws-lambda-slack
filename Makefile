FUNCTION_NAME=Slack
STACK_NAME=Lambda$(FUNCTION_NAME)
REGION := $(shell bash -c 'read -p "REGION [dev, test, prod]: " var; echo $$var')
PROFILE=slack-$(REGION)

.PHONY: create
create: zip
	unset AWS_DEFAULT_REGION; \
	aws configure --profile $(PROFILE); \
	aws cloudformation create-stack \
		--profile $(PROFILE) \
		--stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--template-body file://lambda.yml \
		--tags Key=Name,Value=$(FUNCTION_NAME) \
		--parameters ParameterKey=Environment,ParameterValue=$(REGION) > /dev/null; \
	sleep 61; \
	aws lambda update-function-code \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://function.zip > /dev/null

.PHONY: update
update: zip
	unset AWS_DEFAULT_REGION; \
	aws configure --profile $(PROFILE); \
	aws cloudformation update-stack \
		--profile $(PROFILE) \
		--stack-name $(STACK_NAME)\
		--capabilities CAPABILITY_IAM \
		--template-body file://lambda.yml \
		--tags Key=Name,Value=$(FUNCTION_NAME) \
		--parameters ParameterKey=Environment,ParameterValue=$(REGION) > /dev/null; \
	aws lambda update-function-code \
		--profile $(PROFILE) \
		--function-name $(FUNCTION_NAME)\
		--zip-file fileb://function.zip > /dev/null

.PHONY:
hook:
	echo $(KMS_ENCRYPTED_HOOK_URL)

.PHONY: zip
zip:
	@-rm -f *.zip 
	@zip -r function.zip lambda_function.py > /dev/null


.PHONY: pipeline
pipeline:
	$(eval REPOSITORY_NAME := $(shell basename $$PWD))
	-@unset AWS_DEFAULT_REGION; \
	aws configure --profile $(PROFILE); \
	aws cloudformation create-stack \
		--profile $(PROFILE) \
		--stack-name Pipeline$(STACK_NAME) \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--template-body file://pipeline.yml \
		--output text \
		--parameters \
		  ParameterKey=Environment,ParameterValue=$(REGION) \
		  ParameterKey=StackName,ParameterValue=$(STACK_NAME) \
		  ParameterKey=RepositoryName,ParameterValue=$(REPOSITORY_NAME)


.PHONY: update_pipeline
update_pipeline:
	$(eval REPOSITORY_NAME := $(shell basename $$PWD))
	-@unset AWS_DEFAULT_REGION; \
	aws configure --profile $(PROFILE); \
	aws cloudformation update-stack \
		--profile $(PROFILE) \
		--stack-name Pipeline$(STACK_NAME) \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--template-body file://pipeline.yml \
		--output text \
		--parameters \
		  ParameterKey=Environment,ParameterValue=$(REGION) \
		  ParameterKey=StackName,ParameterValue=$(STACK_NAME) \
		  ParameterKey=RepositoryName,ParameterValue=$(REPOSITORY_NAME) > /dev/null


.PHONY: release
release: update_pipeline
	@git status
	$(eval COMMENT := $(shell bash -c 'read -e -p "Comment: " var; echo $$var'))
	@git add --all; \
	 git commit -m "$(COMMENT)"; \
	 git push
