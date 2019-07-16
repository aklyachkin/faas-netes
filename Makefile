.PHONY: build local build-arm64 build-armhf build-ppc64le push namespaces install install-armhf charts ci-armhf-build ci-armhf-push ci-arm64-build ci-arm64-push ci-ppc64le-build ci-ppc64le-push
TAG?=latest

all: build

local:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o faas-netes

build-arm64:
	docker build -t openfaas/faas-netes:$(TAG)-arm64 . -f Dockerfile.arm64

build-armhf:
	docker build -t openfaas/faas-netes:$(TAG)-armhf . -f Dockerfile.armhf

build-ppc64le:
	docker build -t openfaas/faas-netes:$(TAG)-ppc64le . -f Dockerfile.ppc64le

build:
	docker build --build-arg http_proxy="${http_proxy}" --build-arg https_proxy="${https_proxy}" -t openfaas/faas-netes:$(TAG) .

push:
	docker push alexellis2/faas-netes:$(TAG)

namespaces:
	kubectl apply -f namespaces.yml

install: namespaces
	kubectl apply -f yaml/

install-armhf: namespaces
	kubectl apply -f yaml_armhf/

install-ppc64le: namespaces
	kubectl apply -f yaml_ppc64le/

charts:
	cd chart && helm package openfaas/ && helm package kafka-connector/
	mv chart/*.tgz docs/
	helm repo index docs --url https://openfaas.github.io/faas-netes/ --merge ./docs/index.yaml
	./contrib/create-static-manifest.sh
	./contrib/create-static-manifest.sh ./chart/openfaas ./yaml_arm64 ./chart/openfaas/values-arm64.yaml
	./contrib/create-static-manifest.sh ./chart/openfaas ./yaml_armhf ./chart/openfaas/values-armhf.yaml
	./contrib/create-static-manifest.sh ./chart/openfaas ./yaml_ppc64le ./chart/openfaas/values-armhf.yaml

ci-armhf-build:
	docker build -t openfaas/faas-netes:$(TAG)-armhf . -f Dockerfile.armhf

ci-armhf-push:
	docker push openfaas/faas-netes:$(TAG)-armhf

ci-arm64-build:
	docker build -t openfaas/faas-netes:$(TAG)-arm64 . -f Dockerfile.arm64

ci-arm64-push:
	docker push openfaas/faas-netes:$(TAG)-arm64

ci-ppc64le-build:
	docker build -t openfaas/faas-netes:$(TAG)-ppc64le . -f Dockerfile.ppc64le

ci-ppc64le-push:
	docker push openfaas/faas-netes:$(TAG)-ppc64le

start-kind: ## attempt to start a new dev environment
	@./contrib/create_dev.sh \
		&& echo "" \
		&& printf '%-15s:\t %s\n' 'Web UI' 'http://localhost:31112/ui' \
		&& printf '%-15s:\t %s\n' 'User' 'admin' \
		&& printf '%-15s:\t %s\n' 'Password' $(shell cat password.txt) \
		&& printf '%-15s:\t %s\n' 'CLI Login' "faas-cli login --username admin --password $(shell cat password.txt)"

stop-kind: ## attempt to stop the dev environment
	@./contrib/stop_dev.sh
