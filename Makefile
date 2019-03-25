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

