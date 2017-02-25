
name='scan-llen'
network="$name-network"
redisName="$name-redis"

removeContainers() {
    for name in $@
    do
      if docker ps -a -q -f "name=/$name" | grep '\w'
      then
        docker rm -f `docker ps -a -q -f "name=/$name"`
      fi
    done
}

removeNetwork() {
    if docker network ls -q -f name=^$network | grep '\w'
    then
      docker network rm $network
    fi
}

(
  removeContainers $redisName
  removeNetwork
  set -u -e -x
  sleep 1
  docker network create -d bridge scan-llen-network
  redisContainer=`docker run --network=scan-llen-network \
      --name $redisName -d redis`
  redisHost=`docker inspect $redisContainer |
      grep '"IPAddress":' | tail -1 | sed 's/.*"\([0-9\.]*\)",/\1/'`
  sleep 1
  redis-cli -h $redisHost lpush list1 1
  redis-cli -h $redisHost lpush list2 1
  redis-cli -h $redisHost lpush list2 2
  redis-cli -h $redisHost keys '*'
  docker build -t scan-llen https://github.com/evanx/scan-llen.git
  docker run --name scan-llen-instance --rm -i \
    --network=scan-llen-network \
    -e host=$redisHost \
    -e pattern='list*' \
    scan-lleb
  sleep 2
  redis-cli -h $redisHost keys '*'
  docker rm -f $redisName
  docker network rm $network
)
