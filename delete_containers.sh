#!/bin/bash

LOG_FILE=${0%.*}.log
rm $LOG_FILE

print_msg() {
	echo "$@" | tee -a $LOG_FILE
}

print_dbg() {
	print_msg "[DBG]: $@"
}

read_input() {
  while true; do
  	read -s -n 1 yn
  	case $yn in
  		[Yy]* ) echo 1; exit;;
  		[Nn]* ) echo 0; exit;;
  	esac
  done
}

DOCKER_CONTAINER="docker container"

get_containers() {
	containers=$($DOCKER_CONTAINER list -a --no-trunc  --format '{{.ID}},{{.Names}},{{.Status}}')
	echo ${containers[@]}
}

CONTAINERS=($(get_containers))
CONTAINERS_CNT=${#CONTAINERS[@]}

if [ "$CONTAINERS_CNT" -le 0 ]
then
	print_msg "No local containers found."
	print_msg
	print_msg "Script aborted."
	exit 1
fi

DELETED=0
SKIPPED=0
ERRORS=0

for container in "${CONTAINERS[*]}";
do
	IFS=',' read -r -a containerInfo <<< "$container"
	containerId=${containerInfo[0]}
	containerName=${containerInfo[1]}
	containerStatus=${containerInfo[2]}
  print_msg -n "  * $containerName (ID: $containerId, Status: $containerStatus) - delete [y/n]? "
  answer=$(read_input)
  if [ $answer -eq 1 ]
  then
		DELETE_CMD="$DOCKER_CONTAINER rm $containerId"
		result=$($DELETE_CMD 2>&1 >/dev/null)
		if [ "$?" -le 0 ]
		then
	    print_msg "deleted."
			((DELETED++))
		else
			print_msg "error!"
			print_msg "    - An error has occurred: $result"
			((ERRORS++))
		fi
  else
    ((SKIPPED++))
    print_msg "skipped."
  fi
done

print_msg
print_msg "Finished: $DELETED container(s) deleted, $ERRORS erroed, $SKIPPED skipped"