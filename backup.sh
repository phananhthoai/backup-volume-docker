#!/usr/bin/env bash

set -e

STACK=${1?'Stack required !'}
MOUNT=${2?'Moutn required !'}

if [ $(docker service ls --filter label=com.docker.stack.namespace=${STACK} --format '{{ .Name }}' | grep -E 'redis|db' > /dev/null && echo $?) == 0  ]; then
	for service in $(docker service ls --filter label=com.docker.stack.namespace=${STACK} --format '{{ .Name }}' | grep -E 'redis|db'); do
	  path=$(docker service inspect ${service} | jq -r '.[].Spec.TaskTemplate.ContainerSpec.Mounts[].Source' | xargs docker volume inspect | jq -r '.[].Mountpoint')
	  if [ $(docker service inspect ${service} | jq -r '.[].Spec.Mode.Replicated.Replicas') != 0  ]; then
		  printf "Need scale before backup: "
			read answer
			if [ ${answer} == "y" ]; then
				docker service update ${service} --replicas=0			
				if [ $(docker service inspect ${service} | jq -r '.[].Spec.TaskTemplate.ContainerSpec.Mounts[].Source' | xargs docker volume inspect | jq -r '.[].Mountpoint' > /dev/null && echo $?) == 0 ]; then			  
					if ! [ -f ${path}${service}.tar ]; then
						pushd ${path}
						tar cvf ../${service}.tar .
						cp ../${service}.tar ${MOUNT}
						popd
					else
						pushd ${path}
						cp ../${service}.tar ${MOUNT}
						popd
					fi
				fi
			else
				exit 1
			fi
		fi
	done
fi
