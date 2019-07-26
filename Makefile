##############################################
# WARNING : THIS FILE SHOULDN'T BE TOUCHED   #
#    FOR ENVIRONNEMENT CONFIGURATION         #
# CONFIGURABLE VARIABLES SHOULD BE OVERRIDED #
# IN THE 'artifacts' FILE, AS NOT COMMITTED  #
##############################################

SHELL=/bin/bash

commit       := $(shell git rev-parse HEAD | cut -c1-8)
date         := $(shell date -I)
version-file := 'src/assets/json/version.json'

# name of app
export APP_PATH = av
export COMPOSE_PROJECT_NAME = cartav

# default exposition port, should be overrided in 'artifacts' only
export PORT=80
# default elasticsearch settings, should be overrided in 'artifacts' only
# default elasticsearch is ok for developpement usage, not for production
export ES_MEM = 512m
export ES_VERSION = 6.1.2
export BRANCH=dev

# artifacts including enable overriding of global vars
dummy		    := $(shell touch artifacts)
include ./artifacts

update:
	git pull origin ${BRANCH}

clean-docker:
	docker container rm cartav-build || echo
	docker image rm cartav-build || echo
	docker image rm cartav-dev || echo

clean:
	sudo rm -rf build-dist

dev:  
	touch nginx-dev.conf
	docker-compose -f docker-compose-dev.yml up -d

dev-stop:
	docker-compose -f docker-compose-dev.yml down

frontend-build: clean
	echo "{\"version\": \"prod-$(date)-$(commit)\"}" > $(version-file)
	mkdir -p build-dist dist
	docker container rm cartav-build || echo
	docker-compose -f docker-compose-build.yml up
	rsync -avz --delete build-dist/. dist/. 
	git reset -- $(version-file)

down: 
	docker-compose -f docker-compose.yml  down
up: 
	touch nginx-run.conf
	docker-compose -f docker-compose.yml up -d

images-dir:
	if [ ! -d images ] ; then mkdir -p images ; fi

save-images: images-dir elasticsearch-save-image nginx-save-image

elasticsearch-save-image:
	elasticsearch_image_name=$$(export EXEC_ENV=production && docker-compose -f docker-compose.yml config | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | jq -r .services.esnode1.image) ; \
	docker image save -o images/cartav-esnode1-image.tar $$elasticsearch_image_name

nginx-save-image:
	nginx_image_name=$$(export EXEC_ENV=production && docker-compose -f docker-compose.yml config | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | jq -r .services.nginx.image) ; \
	docker image save -o images/cartav-nginx-image.tar $$nginx_image_name

download-all-images: nginx-download-image elasticsearch-download-image

elasticsearch-download-image:

nginx-download-image:

load-images: images-dir nginx-load-image elasticsearch-load-image

elasticsearch-load-image:
	docker image load -i images/cartav-esnode1-image.tar

nginx-download-image:

nginx-load-image:
	docker image load -i images/cartav-nginx-image.tar

