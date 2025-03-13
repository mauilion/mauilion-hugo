HTMLTEST_IMG ?= wjdp/htmltest
HUGO_IMG ?= jojomi/hugo:0.61.0
IMG ?= mauilion/mauiliondev
PORT ?= 8080

PRIMARY_IP := ""
RUN_MSG := "View the local build of CNFE Documentations at http://localhost:${PORT}"
UNAME_S := $(shell uname -s)
CMD := ""

ifeq ($(UNAME_S),Darwin)
	PRIMARY_IP := $(shell ipconfig getifaddr en0)
else ifeq ($(UNAME_S),Linux) 
	PRIMARY_IP := $(shell ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
endif

ifneq ($(PRIMARY_IP),"")
	RUN_MSG += "or http://${PRIMARY_IP}:${PORT}"	
endif



build:
	docker build --build-arg HUGO_IMG=${HUGO_IMG} . -t ${IMG}

run: build
	@echo "\n\n${RUN_MSG}"
	@docker run -v mauiliondev:/out -p ${PORT}:80 ${IMG}

htmltest:
ifdef EXTERNAL
	$(eval CMD := "htmltest ")
else
	$(eval CMD := "htmltest -s ")
endif

	@echo "Running htmltest against recent build."
	@echo "Command = $(CMD)"
	docker build \
		--network=host\
		--build-arg IMG=${IMG} \
		--build-arg ARGS=$(CMD) \
		--build-arg HTMLTEST_IMG=${HTMLTEST_IMG} \
		-f Dockerfile.htmltest . -t ${IMG}\htmltest

livedocs:
	@docker run --rm -d --name=livedocs -p 1313:1313 -v ${PWD}:/src/ ${HUGO_IMG} hugo server -w --bind=0.0.0.0
	@echo "Started a container nameed livedocs. To follow the log you can run docker logs -f livedocs"
	@echo "to stop or clean up the container you can run docker stop livedocs"
	@echo "livedocs is available at http://127.0.0.1:1313"
	@echo "Any changes to files in this directory will immediately be reloaded in livedocs"


