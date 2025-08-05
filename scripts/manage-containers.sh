#!/bin/bash
# /Users/millz./vita-strategies/scripts/manage-containers.sh

ACTION=$1

case $ACTION in
  "pause")
    echo "Pausing containers for IDE update..."
    docker-compose stop
    ;;
  "resume")
    echo "Resuming containers after IDE update..."
    docker-compose start
    ;;
  "restart")
    echo "Restarting containers..."
    docker-compose restart
    ;;
  *)
    echo "Usage: $0 {pause|resume|restart}"
    exit 1
    ;;
esac
