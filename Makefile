commit       := $(shell git rev-parse HEAD | cut -c1-8)
date         := $(shell date -I)
version-file := 'src/assets/json/version.json'

clean:
	sudo rm -rf dist
dev: 
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
	scp -r dist/* fa-gate-adm:/data/www/demo/francis/dist/test

prod: clean
	echo "{\"version\": \"prod-$(date)-$(commit)\"}" > $(version-file)
	# npm run build-production
	mkdir -p dist
	docker-compose -f docker-compose-build-production.yml up
	git reset -- $(version-file)
deploy-prod: prod
	scp -r dist/* fa-gate-adm:/data/www/demo/francis/dist
test: 
	docker-compose -f docker-compose-run-production.yml up -d

cloud: clean
	echo "{\"version\": \"cloud-$(date)-$(commit)\"}" > $(version-file)
	node build/build.js cloud
	git reset -- $(version-file)
deploy-cloud: cloud
	scp -r dist/* cloud-mi:/var/www/html

sync-cloud-es:
	./sync_elastic_search.sh
