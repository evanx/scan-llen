
set -u -e

PATH=$PATH:./node_modules/.bin

name='scan-llen'
network="$name-network"
redisName="$name-redis"

run

run() {
    tearDown
    setUp
    sleep 1
    populate
    build
    run
    sleep 1
    test
    tearDown
}

tearDown() {
  remove-containers $redisName
  remove-network $network
}

setUp() {
  docker network create -d bridge scan-llen-network
  redisContainer=`docker run --network=scan-llen-network \
      --name $redisName -d redis`
  redisHost=`docker inspect $redisContainer |
      grep '"IPAddress":' | tail -1 | sed 's/.*"\([0-9\.]*\)",/\1/'`
}

populate() {
  redis-cli -h $redisHost lpush list1 1
  redis-cli -h $redisHost lpush list2 1
  redis-cli -h $redisHost lpush list2 2
  redis-cli -h $redisHost keys '*'
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

test() {
  redis-cli -h $redisHost keys '*'
}
