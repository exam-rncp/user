NAME = exam-rncp/user
DBNAME = exam-rncp/user-db
INSTANCE = user
TESTDB = testuserdb
OPENAPI = $(INSTANCE)-testopenapi
TAG=$(COMMIT)

default: docker

pre: 
	go get -v github.com/Masterminds/glide

deps: pre
	glide install

rm-deps:
	rm -rf vendor

test:
	@glide novendor|xargs go test -v

dockerdev:
	docker build -t $(INSTANCE)-dev .

dockertestdb:
	docker build -t $(TESTDB) -f docker/user-db/Dockerfile docker/user-db/

dockerruntest: dockertestdb dockerdev
	docker run -d --name my$(TESTDB) -h my$(TESTDB) $(TESTDB)
	docker run -d --name $(INSTANCE)-dev -p 8084:8084 --link my$(TESTDB) -e MONGO_HOST="my$(TESTDB):27017" $(INSTANCE)-dev

docker:
	docker build -t $(NAME) -f docker/user/Dockerfile-release .

dockerlocal:
	docker build -t $(INSTANCE)-local -f docker/user/Dockerfile-release .

dockertravisbuild: 
	docker build -t $(NAME):$(TAG) -f docker/user/Dockerfile-release .
	docker build -t $(DBNAME):$(TAG) -f docker/user-db/Dockerfile docker/user-db/
	if [ -z "$(DOCKER_PASS)" ]; then \
		echo "This is a build triggered by an external PR. Skipping docker push."; \
	else \
		docker login -u $(DOCKER_USER) -p $(DOCKER_PASS); \
		chmod +x scripts/push.sh; \ 
		scripts/push.sh; \
	fi


dockertest: dockerruntest
	chmod +x scripts/testcontainer.sh
	docker run -h openapi --rm --name $(OPENAPI) --link user-dev -v $(PWD)/apispec/:/tmp/specs/\
		weaveworksdemos/openapi /tmp/specs/$(INSTANCE).json\
		http://$(INSTANCE)-dev:8084/\
		-f /tmp/specs/hooks.js
	 $(MAKE) cleandocker

cleandocker:
	-docker rm -f my$(TESTDB)
	-docker rm -f $(INSTANCE)-dev
	-docker rm -f $(OPENAPI)