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

# artifacts including enable overriding of global vars
dummy		    := $(shell touch artifacts)
include ./artifacts

clean-docker:
	docker container rm cartav-build-prod || echo
	docker image rm cartav-build-prod || echo
	docker image rm cartav-run-dev || echo

clean:
	sudo rm -rf build-dist

download:
ifeq ("$(wildcard esdata)","")
	mkdir -p esdata
endif
ifeq ("$(wildcard esdata/dev_cartav_1node.tar.gz.gpg)","")
	wget http://catalog.datalab.mi/s/resources/cartav-jeu-de-developpement-preindexe/20180320-080437/dev_cartav_1node.tar.gz.gpg.zip -O esdata/dev_cartav_1node.tar.gz.gpg
endif

decrypt: download
ifeq ("$(wildcard esdata/dev/nodes/0/)","")
	@echo unpacking sample data
	@cat esdata/dev_cartav_1node.tar.gz.gpg | gpg -q -d --batch --passphrase "*AH5xieZa!" | sudo tar xzf - -C esdata/
endif

dev:  
	touch nginx-dev.conf
	docker-compose -f docker-compose-run-dev.yml up -d



dev-stop:
	docker-compose -f docker-compose-run-dev.yml down

pre-prod: clean
	echo "{\"version\": \"pre-prod-$(date)-$(commit)\"}" > $(version-file)
	#npm run build-pre-prod
	mkdir -p dist
	docker-compose -f docker-compose-build-preprod.yml up
	git reset -- $(version-file)

deploy-pre-prod: pre-prod
	scp -r build-dist/* fa-proxy-muserfi:/var/www/demo/francis/dist/test

prod: frontend-build 

deploy-prod: prod
	scp -r dist/* fa-proxy-muserfi:/var/www/demo/francis/dist

frontend-build: clean
	echo "{\"version\": \"prod-$(date)-$(commit)\"}" > $(version-file)
	mkdir -p build-dist dist
	docker container rm cartav-build-prod || echo
	docker-compose -f docker-compose-build-production.yml up
	rsync -avz --delete build-dist/. dist/. 
	git reset -- $(version-file)

down: 
	docker-compose -f docker-compose-run-production.yml  down
up: 
	touch nginx-run.conf
	docker-compose -f docker-compose-run-production.yml up -d

cloud: clean
	echo "{\"version\": \"cloud-$(date)-$(commit)\"}" > $(version-file)
	node build/build.js cloud
	git reset -- $(version-file)
deploy-cloud: cloud
	scp -r dist/* cloud-mi:/var/www/html

sync-cloud-es:
	./sync_elastic_search.sh
