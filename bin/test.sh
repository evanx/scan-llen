
set -u -e

PATH=$PATH:./node_modules/.bin

name='scan-llen'
network="$name-network"
redisName="$name-redis"

tearDown() {
  docker-rm $redisName
  docker-network-rm $network
}

setUp() {
  docker network create -d bridge scan-llen-network
  redisContainer=`docker run --network=scan-llen-network \
      --name $redisName -d redis`
  redisHost=`docker inspect $redisContainer |
      grep '"IPAddress":' | tail -1 | sed 's/.*"\([0-9\.]*\)",/\1/'`
}

populate() {
  redis-cli -h $redisHost lpush list1 1 | grep -q '^1$'
  redis-cli -h $redisHost lpush list2 1 | grep -q '^1$'
  redis-cli -h $redisHost lpush list2 2 | grep -q '^2$'
}

build() {
  docker build -t scan-llen https://github.com/evanx/scan-llen.git
}

run() {
  docker run --name scan-llen-instance --rm -i \
    --network=scan-llen-network \
    -e host=$redisHost \
    -e pattern='list*' \
    scan-llen
}

main() {
    tearDown
    setUp
    sleep 1
    populate
    build
    run | grep '^1 list1$'
    run | grep '^2 list2$'
    tearDown
    echo 'OK'
}

main
