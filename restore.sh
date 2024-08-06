#!/usr/bin/env bash

set -ex

STACK=${1?'Stack required !'}
MOUNT="/mount"

if [ $(docker service ls --filter label=com.docker.stack.namespace=${STACK} --format '{{ .Name }}' | grep -E 'redis|db' > /dev/null && echo $?) == 0  ]; then
	for service in $(docker service ls --filter label=com.docker.stack.namespace=${STACK} --format '{{ .Name }}' | grep -E 'redis|db'); do
	  path=$(docker service inspect ${service} | jq -r '.[].Spec.TaskTemplate.ContainerSpec.Mounts[].Source' | xargs docker volume inspect | jq -r '.[].Mountpoint')
	  if [ $(docker service inspect ${service} | jq -r '.[].Spec.Mode.Replicated.Replicas') != 0  ]; then
	    printf "Need scale before restore: "
	    read answer
	    if [ ${answer} == "y" ]; then
		  	docker service update ${service} --replicas=0
				if [ $(docker service inspect "${service}" | jq -r '.[].Spec.TaskTemplate.ContainerSpec.Mounts[].Source' | xargs docker volume inspect | jq -r '.[].Mountpoint' > /dev/null && echo $?) == 0 ]; then
					if [ -f ${MOUNT}/${service}.tar ]; then
					  rm -rf ${path}/*
						cp ${MOUNT}/${service}.tar ${path}
						pushd ${path}
						tar xvf ${service}.tar
						popd						
					else
					  echo "No File Backup"
					fi
				fi
			else
			  exit 1
			fi
		fi
	done
fi
