#!/usr/bin/env bash

set -ev

if [[ -z "$GROUP" ]] ; then
    echo "Cannot find GROUP env var"
    exit 1
fi

if [[ -z "$COMMIT" ]] ; then
    echo "Cannot find COMMIT env var"
    exit 1
fi

push() {
    DOCKER_PUSH=1;
    while [ $DOCKER_PUSH -gt 0 ] ; do
        echo "Pushing $1";
        docker push $1;
        DOCKER_PUSH=$(echo $?);
        if [[ "$DOCKER_PUSH" -gt 0 ]] ; then
            echo "Docker push failed with exit code $DOCKER_PUSH";
        fi;
    done;
}

tag_and_push_all() {
    if [[ -z "$1" ]] ; then
        echo "Please pass the tag"
        exit 1
    else
        TAG=$1
    fi
    for m in ./docker/*/; do
        REPO=${GROUP}/$(basename $m)
        if [[ "$COMMIT" != "$TAG" ]]; then
            docker tag ${REPO}:${COMMIT} ${REPO}:${TAG}
        fi
        push "$REPO:$TAG";
    done;
}

# Push tag and latest when tagged
if [ -n "$IMAGE_TAG" ]; then
    tag_and_push_all ${IMAGE_TAG}
    tag_and_push_all latest
fi;
