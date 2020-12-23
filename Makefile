SHELL := /bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

.PHONY: all clean deploy destroy dry-api logs-tail make-bucket native-compile native-deploy native-dry-api native-pack pack
BUCKET_NAME=menard-lambda
STACK_NAME=menard-lambda-stack-native
APP_REGION=eu-central-1
LAMBDA1_NAME=GenerateNL
LAMBDA2_NAME=ParseNL
LAMBDA3_NAME=GenerateWithAlternatesNL

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
	sam deploy --template-file ./packaged.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

dry-api:
	sam local start-api --skip-pull-image

logs-tail:
	sam logs -n $(LAMBDA1_NAME) --stack-name $(STACK_NAME) -t

make-bucket:
	(aws s3 ls s3://$(BUCKET_NAME) || aws s3 mb s3://$(BUCKET_NAME))

native-compile: target/output.jar
	${native_image_cmd}
	mv -f output server
	zip -j latest resources/bootstrap server
	mv latest.zip resources/
	rm -Rf server

native-deploy: native-pack
	sam deploy --template-file ./resources/native-packaged.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

native-dry-api: native-compile
	sam local start-api --template ./resources/native-template.yml --skip-pull-image

native-pack: native-compile
	sam package --template-file ./resources/native-template.yml --output-template-file resources/native-packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

pack: target/output.jar
	sam package --template-file ./template.yml --output-template-file packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

target/output.jar: src/menard_lambda/core.clj
	lein uberjar


