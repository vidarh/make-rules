#
# A small set of rules for updating sites running
# under Nginx on a coreos machine.
#
#
# IP      ::=  IP address of host
# SERVICE ::=  Name of container
# VOLUME  ::=  Files will be stores in /home/core/sites/${VOLUME}
#
# Recommended:
#
# Include "rack.mk" to get "bundle", "shotgun" and "pry" targets
#

# Additional targets for "make build"
BUILD_TARGETS=

# Things to push to a remote server
PUSH_TARGETS=

ifndef VOLUME
VOLUME=${SERVICE}
endif

ifeq ($(wildcard ${PWD}/public),${PWD}/public)
STATIC_CONTENT=${PWD}/public
SITEDIR=${PWD}/output
TARGET_SITEDIR=/home/core/sites

${SITEDIR}: ${STATIC_CONTENT}
	cp -Rap ${STATIC_CONTENT} ${SITEDIR}

push-content: ${SITEDIR}
	ssh ${DEST} mkdir -p ${TARGET_SITEDIR}
	rsync -avzp --delete ${SITEDIR}/ ${DEST}:${TARGET_SITEDIR}/${VOLUME}

PUSH_TARGETS+=push-content
BUILD_TARGETS+=build-static

build-static: ${SITEDIR}


endif

ifneq ($(wildcard bin/build),)
BUILD_TARGETS+=build-bin

build-bin:
	bin/build
endif



ifneq ($(wildcard ${SERVICE}.conf),)
PUSH_TARGETS+=push-conf
push-conf: ${SERVICE}.conf
		ssh ${DEST} mkdir -p /home/core/conf
		scp ${SERVICE}.conf ${DEST}:conf/
endif

ifneq ($(wildcard ${SERVICE}.service),)
PUSH_TARGETS+=push-service
push-service: ${CONFIG_TARGET} ${SERVICE}.service
		scp ${SERVICE}.service ${DEST}:/tmp/${SERVICE}.service
		${DO} mv /tmp/${SERVICE}.service /etc/systemd/system/
		${SYS} daemon-reload
		${SYS} enable ${SERVICE}
		${SYS} restart ${SERVICE}
		${SYS} status ${SERVICE}
endif

CLEAN_DIRS+= ${SITEDIR}

DEST=core@${IP}
DO=ssh ${DEST} sudo 
SYS=${DO} systemctl

CLEAN_DIRS+=*~

.PHONY: clean

clean:
	rm -rf ${CLEAN_DIRS}

update-content: build push-content

update: update-content

status:
	${SYS} status ${SERVICE}

ssh:
	ssh ${DEST}

logs:
	ssh ${DEST} docker logs --tail=100 -f ${SERVICE}



build: clean ${BUILD_TARGETS}

push: ${PUSH_TARGETS}

all: build push


