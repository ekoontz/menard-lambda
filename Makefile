SHELL := /bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

.PHONY: all clean deploy destroy dry-api logs-tail make-bucket native-deploy native-destroy native-dry-api
BUCKET_NAME=menard-lambda
STACK_NAME=menard-lambda-stack
NATIVE_STACK_NAME=menard-lambda-stack-native
APP_REGION=eu-central-1
LAMBDA1_NAME=GenerateNL
LAMBDA2_NAME=ParseNL
LAMBDA3_NAME=GenerateWithAlternatesNL

native_image_cmd=docker run -v ${PWD}:/project:Z -it fierycod/graalvm-native-image:latest bash -c "cd /project && native-image --verbose -jar target/output.jar --report-unsupported-elements-at-runtime --enable-url-protocols=http,https --no-server --initialize-at-build-time "

all: native-deploy

clean:
	-rm -rf target/ packaged.yml native-packaged.yml latest.zip

deploy: pack
	sam deploy --template-file ./packaged.yml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

dry-api:
	sam local start-api --skip-pull-image

logs-tail:
	sam logs -n $(LAMBDA1_NAME) --stack-name $(STACK_NAME) -t

make-bucket:
	(aws s3 ls s3://$(BUCKET_NAME) || aws s3 mb s3://$(BUCKET_NAME))

latest.zip: server bootstrap
	zip -j latest bootstrap server

server: target/output.jar
	${native_image_cmd}
	mv -f output server

native-deploy: native-packaged.yml
	sam deploy --template-file native-packaged.yml --stack-name $(NATIVE_STACK_NAME) --capabilities CAPABILITY_IAM --region $(APP_REGION)

native-destroy:
	aws cloudformation delete-stack --stack-name $(NATIVE_STACK_NAME) --region $(APP_REGION)

native-dry-api: latest.zip
	sam local start-api --template native-template.yml

native-packaged.yml: latest.zip native-template.yml
	sam package --template-file native-template.yml --output-template-file native-packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

packaged.yml: target/output.jar template.yml
	sam package --template-file template.yml --output-template-file packaged.yml --s3-bucket $(BUCKET_NAME) --s3-prefix "menard-lambda-latest"

target/output.jar: src/menard_lambda/core.clj
	lein uberjar


