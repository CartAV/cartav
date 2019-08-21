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
export ES_CHUNK=5000
export ES_VERBOSE=50000
export ES_VERBOSE_UPDATE=1000
export ES_TIMEOUT=30
export ES_JOBS=4
export ES_CONTAINER=esnode1
export ES_MAPPINGS=mappings
export ES_SETTINGS={"index": {"number_of_shards": 1, "refresh_interval": "300s", "number_of_replicas": 0}}
export NGINX_CONTAINER=nginx

export BRANCH=dev

export OS_DELAY=5
export OS_TIMEOUT=10
export OS_RETRY=10
export OS_CURL_OPTS=-k --retry ${OS_RETRY} --retry-delay ${OS_DELAY} --connect-timeout ${OS_TIMEOUT} --fail

export DATA_PATTERN=json
export DATA_SETS=communes radars acc acc_usagers acc_vehicules pve
export DATA_FILE_EXT=.json.gz
export DATA_SCHEMA_EXT=_schema.json
export DATA_MD5_EXT=.json.gz.md5
export DATA_DOWNLOAD_DIR=data-download

export DC=/usr/local/bin/docker-compose

# artifacts including enable overriding of global vars
dummy		    := $(shell touch artifacts)
include ./artifacts

# activate token when a pwd is present in artifact, for swift interaction (data source)
export OS_AUTH_TOKEN:=$(shell [ ! -z "$(OS_PASSWORD)" ] && curl ${OS_CURL_OPTS} -s -D - -L -H "Content-Type: application/json" -d '{ "auth": { "identity": { "methods": ["password"], "password": { "user": { "name": "'$(OS_USER)'", "domain": { "name": "'$(OS_DOMAIN)'" }, "password": "'$(OS_PASSWORD)'" } } } } }' ${OS_AUTH_URL}/auth/tokens  | grep X-Subject-Token | sed 's/X-Subject-Token:\s*//; s/\r//')

install-prerequisites:
ifeq ("$(wildcard /usr/bin/docker /usr/local/bin/docker)","")
	@echo "Installing docker-ce"
	sudo apt-get update
	sudo apt-get install apt-transport-https ca-certificates ${CURL_CMD} software-properties-common
	${CURL_CMD}-fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -
	sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu `lsb_release -cs` stable"
	sudo apt-get update
	sudo apt-get install -y docker-ce
	@(if (id -Gn ${USER} | grep -vc docker); then sudo usermod -aG docker ${USER} ;fi) > /dev/null
endif
ifeq ("$(wildcard /usr/bin/gawk /usr/local/bin/gawk)","")
	@echo "Installing gawk"
	@sudo apt-get install -y gawk
endif
ifeq ("$(wildcard /usr/bin/jq /usr/local/bin/jq)","")
	@echo "Installing jq"
	@sudo apt-get install -y jq
endif
ifeq ("$(wildcard /usr/bin/parallel /usr/local/bin/parallel)","")
	@echo "Installing parallel"
	@sudo apt-get install -y parallel
endif
ifeq ("$(wildcard /usr/local/bin/docker-compose)","")
	@echo "Installing docker-compose"
	@sudo ${CURL_CMD}-s -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	@sudo chmod +x /usr/local/bin/docker-compose
endif

network-stop:
	@docker network rm ${APP}

network: install-prerequisites
	@docker network create ${APP} 2> /dev/null; true

update:
	git pull origin ${BRANCH}

clean-docker:
	docker container rm ${COMPOSE_PROJECT_NAME}-build || echo
	docker image rm ${COMPOSE_PROJECT_NAME}-build || echo
	docker image rm ${COMPOSE_PROJECT_NAME}-dev || echo

clean:
	sudo rm -rf build-dist

dev:
	@touch nginx-dev.conf
	@echo starting dev mode
	@${DC} -f docker-compose-dev.yml up -d

dev-stop:
	@echo stopping docker dev services
	@${DC} -f docker-compose-dev.yml down

frontend-build: clean
	echo "{\"version\": \"prod-$(date)-$(commit)\"}" > $(version-file)
	mkdir -p build-dist dist
	docker container rm ${COMPOSE_PROJECT_NAME}-build || echo
	${DC} -f docker-compose-build.yml up
	rsync -avz --delete build-dist/. dist/.
	git reset -- $(version-file)

down:
	${DC} -f docker-compose.yml  down

up:
	@touch nginx-run.conf
	@echo starting all services in production mode
	@${DC} -f docker-compose.yml up -d

elasticsearch:
	@${DC} -f docker-compose.yml up -d ${ES_CONTAINER}

wait-elasticsearch: elasticsearch
	@timeout=${ES_TIMEOUT} ; ret=1 ; until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do (docker exec -i ${USE_TTY} ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s --fail -XGET localhost:9200/_cat/indices > /dev/null) ; ret=$$? ; if [ "$$ret" -ne "0" ] ; then echo "waiting for elasticsearch to start $$timeout" ; fi ; ((timeout--)); sleep 1 ; done ; exit $$ret

images-dir:
	if [ ! -d images ] ; then mkdir -p images ; fi

save-images: images-dir elasticsearch-save-image nginx-save-image

elasticsearch-save-image:
	elasticsearch_image_name=$$(export EXEC_ENV=production && ${DC} -f docker-compose.yml config | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | jq -r .services.${ES_CONTAINER}.image) ; \
	docker image save -o images/${COMPOSE_PROJECT_NAME}-${ES_CONTAINER}-image.tar $$elasticsearch_image_name

nginx-save-image:
	nginx_image_name=$$(export EXEC_ENV=production && ${DC} -f docker-compose.yml config | python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' | jq -r .services.${NGINX_CONTAINER}.image) ; \
	docker image save -o images/${COMPOSE_PROJECT_NAME}-${NGINX_CONTAINER}-image.tar $$nginx_image_name

download-all-images: nginx-download-image elasticsearch-download-image

elasticsearch-download-image:

nginx-download-image:

load-images: images-dir nginx-load-image elasticsearch-load-image

elasticsearch-load-image:
	docker image load -i images/${COMPOSE_PROJECT_NAME}-${ES_CONTAINER}-image.tar

nginx-download-image:

nginx-load-image:
	docker image load -i images/${COMPOSE_PROJECT_NAME}-${NGINX_CONTAINER}-image.tar

data-list:
	@curl ${OS_CURL_OPTS} -s -H "X-Auth-Token: ${OS_AUTH_TOKEN}" ${OS_SWIFT_URL}/${OS_SWIFT_AUTH}/${OS_SWIFT_CONTAINER}/ | egrep '${DATA_PATTERN}'

data-download-clean:
	@rm -rf $(DATA_DOWNLOAD_DIR)

$(DATA_DOWNLOAD_DIR):
	@mkdir -p $(DATA_DOWNLOAD_DIR)
	@for SET in $(DATA_SETS); do \
		echo downloading dataset: $${SET};\
		curl ${OS_CURL_OPTS} -s -H "X-Auth-Token: ${OS_AUTH_TOKEN}" ${OS_SWIFT_URL}/${OS_SWIFT_AUTH}/${OS_SWIFT_CONTAINER}/$${SET}${DATA_FILE_EXT} > ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_FILE_EXT};\
		curl ${OS_CURL_OPTS} -s -H "X-Auth-Token: ${OS_AUTH_TOKEN}" ${OS_SWIFT_URL}/${OS_SWIFT_AUTH}/${OS_SWIFT_CONTAINER}/$${SET}${DATA_SCHEMA_EXT} > ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_SCHEMA_EXT};\
		curl ${OS_CURL_OPTS} -s -H "X-Auth-Token: ${OS_AUTH_TOKEN}" ${OS_SWIFT_URL}/${OS_SWIFT_AUTH}/${OS_SWIFT_CONTAINER}/$${SET}${DATA_MD5_EXT} > ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_MD5_EXT};\
	done;

data-show-head:
	@for SET in $(DATA_SETS); do \
		echo downloading dataset: $${SET};\
		curl ${OS_CURL_OPTS} -s -H "X-Auth-Token: ${OS_AUTH_TOKEN}" ${OS_SWIFT_URL}/${OS_SWIFT_AUTH}/${OS_SWIFT_CONTAINER}/$${SET}${DATA_FILE_EXT} | head ;\
	done;

data-check: $(DATA_DOWNLOAD_DIR)
	@for SET in $(DATA_SETS); do \
		md5sum ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_FILE_EXT} | sed 's|${DATA_DOWNLOAD_DIR}/||' > /tmp/md5test;\
		diff -wb /tmp/md5test ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_MD5_EXT} || exit 1;\
	done;

data-index-purge: wait-elasticsearch
	@for SET in $(DATA_SETS); do \
		docker exec ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s -XPUT localhost:9200/$${SET}/_settings -H 'content-type:application/json' -d'{"index.blocks.read_only": false}' | sed 's/{"acknowledged":true.*/'"$${SET}"' index prepared for deletion\n/;s/.*no such index.*//';\
		docker exec ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s -XDELETE localhost:9200/$${SET} | sed 's/{"acknowledged":true.*/'"$${SET}"' index purged\n/;s/.*no such index.*//';\
		timeout=${ES_TIMEOUT} ; ret=0 ; until [ "$$timeout" -le 1 -o "$$ret" -eq "0"  ] ; do (docker exec -i ${USE_TTY} ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s --fail -XGET localhost:9200/$${SET} > /dev/null) ; ret=$$? ; if [ "$$ret" -ne "1" ] ; then echo "waiting for $${SET} index to be purged - $$timeout" ; fi ; ((timeout--)); sleep 1 ; done ; \
		if [ "$$ret" -ne "0" ]; then exit $$ret; fi;\
	done;


data-index-create: data-index-purge
	@for SET in $(DATA_SETS); do \
    if [ -f "${ES_MAPPINGS}/$${SET}.json" ]; then\
			mapping=`cat ${ES_MAPPINGS}/$${SET}.json | tr '\n' ' '`;\
			docker exec -i ${USE_TTY} ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s -H "Content-Type: application/json" -XPUT localhost:9200/$${SET} -d '{"settings": ${ES_SETTINGS}, "mappings": { "'"$${SET}"'": '"$${mapping}"'}}' | sed 's/{"acknowledged":true.*/'"$${SET}"' index created with mapping\n/';\
		else \
			docker exec -i ${USE_TTY} ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s -H "Content-Type: application/json" -XPUT localhost:9200/$${SET} | sed 's/{"acknowledged":true.*/'"$${SET}"' index created without mapping\n/';\
		fi;\
		timeout=${ES_TIMEOUT} ; ret=1 ; until [ "$$timeout" -le 0 -o "$$ret" -eq "0"  ] ; do (docker exec -i ${USE_TTY} ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s --fail -XGET localhost:9200/$${SET} > /dev/null) ; ret=$$? ; if [ "$$ret" -ne "0" ] ; then echo "waiting for $${SET} index - $$timeout" ; fi ; ((timeout--)); sleep 1 ; done ; \
		if [ "$$ret" -ne "0" ]; then exit $$ret; fi;\
	done;

data-index-load: data-check data-index-create
	@for SET in $(DATA_SETS); do \
		zcat ${DATA_DOWNLOAD_DIR}/$${SET}${DATA_FILE_EXT} |\
			awk 'BEGIN{n = 1;print "inject $${SET} to elasticsearch" > "/dev/stderr";}{print "{\"index\": {\"_index\": \"'"$${SET}"'\", \"_type\": \"'"$${SET}"'\"}}\n"};print;if ((n%${ES_VERBOSE})==0) {print "read " n " lines" > "/dev/stderr";} n++}' | \
			parallel --block-size 10M -N ${ES_CHUNK} -j${ES_JOBS} --pipe 'docker exec -i ${COMPOSE_PROJECT_NAME}-${ES_CONTAINER} curl -s -H "Content-Type: application/json" localhost:9200/_bulk  --data-binary @-;echo '; \
	done;

