SHELL := /bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

.PHONY: all clean deploy destroy dry-api logs-tail native-compile native-deploy native-dry-api native-pack
BUCKET_NAME=menard-lambda
STACK_NAME=menard-lambda-stack-native
APP_REGION=eu-central-1
LAMBDA_NAME=GenerateNL

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	native_image_cmd=native-image -jar target/output.jar --report-unsupported-elements-at-runtime -H:ConfigurationFileDirectories=resources/native-configuration --no-fallback --enable-url-protocols=http,https --no-server  --initialize-at-build-time
	DRY_API_WARNING=""
else
	native_image_cmd=docker run -v ${PWD}:/project:Z -it fierycod/graalvm-native-image:latest bash -c "cd /project && native-image -jar target/output.jar --report-unsupported-elements-at-runtime -H:ConfigurationFileDirectories=resources/native-configuration --no-fallback --enable-url-protocols=http,https --no-server  --initialize-at-build-time "
	DRY_API_WARNING="'dry-api' does not work on your platform: use 'native-dry-api' instead to run within Docker."
endif

all: native-deploy

clean:
	-rm -rf target/ packaged.yml resources/native-packaged.yml resources/latest.zip

deploy: pack
	@sam deploy --template-file ./packaged.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

make-bucket:
	@(aws s3 ls s3://$(BUCKET_NAME) || aws s3 mb s3://$(BUCKET_NAME))

destroy-bucket:
	@aws s3 rb s3://$(BUCKET_NAME) --force --region $(APP_REGION)

agent-trace-native-configuration:
	@choly graal -e "java -agentlib:native-image-agent=trace-output=trace.json -Dexecutor=native-agent -jar target/output.jar" \
	 	           -s	"--env-file=resources/envs.list"

trace-to-configuration:
	@choly graal -e "native-image-configure generate --trace-input=trace.json --output-dir=trace-configuration"

dry-api:
	@sam local start-api --skip-pull-image

gen-native-configuration:
	@choly graal -e "java -agentlib:native-image-agent=config-merge-dir=resources/native-configuration -Dexecutor=native-agent -jar target/output.jar"

gen-native-template:
	choly template -t template.yml

native-compile: target/output.jar
	choly graal -e "native-image -jar target/output.jar \
			--report-unsupported-elements-at-runtime \
			-H:ConfigurationFileDirectories=resources/native-configuration \
			--no-fallback \
			--enable-url-protocols=http,https \
			--no-server \
			--initialize-at-build-time"
	mv -f output server
	zip -j latest resources/bootstrap server
	mv latest.zip resources/
	rm -Rf server

pack: compile
	@sam package --template-file ./template.yml --output-template-file packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

native-pack: native-compile
	@sam package --template-file ./resources/native-template.yml --output-template-file resources/native-packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

native-deploy: native-pack make-bucket
	@sam deploy --template-file ./resources/native-packaged.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

native-destroy:
	@aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(APP_REGION)

logs-tail:
	sam logs -n $(LAMBDA_NAME) --stack-name $(STACK_NAME) -t

target/output.jar: src/hello_lambda/core.clj
	@lein uberjar


