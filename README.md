# scan-llen

Containerized utility to scan and print llen of Redis keys.

<img src="https://raw.githubusercontent.com/evanx/scan-llen/master/docs/readme/main.png"/>

## Use case

We wish to expire a set of keys in Redis matching some pattern.

## Config

See `lib/config.js`
```javascript
module.exports = {
    description: 'Containerized utility to scan Redis keys and expire all matching keys.',
    required: {
        pattern: {
            description: 'the matching pattern for Redis scan',
            example: '*'
        },
        ttl: {
            description: 'the TTL expiry to set on archived keys',
            unit: 'seconds',
            example: 60
        },
        limit: {
            description: 'the maximum number of keys to expire',
            default: 10,
            note: 'zero means unlimited'
        },
        host: {
            description: 'the Redis host',
            default: 'localhost'
        },
        port: {
            description: 'the Redis port',
            default: 6379
        }
    }
}
```

## Docker

You can build as follows:
```shell
docker build -t scan-llen https://github.com/evanx/scan-llen.git
```

See `test/demo.sh` https://github.com/evanx/scan-llen/blob/master/test/demo.sh

Builds:
- isolated network `scan-llen-network`
- isolated Redis instance named `scan-llen-redis`
- this utility `evanx/scan-llen`

First we create the isolated network:
```shell
docker network create -d bridge scan-llen-network
```

Then the Redis container on that network:
```
redisContainer=`docker run --network=scan-llen-network \
    --name $redisName -d redis`
redisHost=`docker inspect $redisContainer |
    grep '"IPAddress":' | tail -1 | sed 's/.*"\([0-9\.]*\)",/\1/'`
```
where we parse its IP number into `redisHost`

We set our test keys:
```
redis-cli -h $redisHost set user:evanxsummers '{"twitter": "@evanxsummers"}'
redis-cli -h $redisHost set user:other '{"twitter": "@evanxsummers"}'
redis-cli -h $redisHost set group:evanxsummers '["evanxsummers"]'
```
where the will expire keys `user:*` and then should only have the `group:evanxsummers` remaining.

We build a container image for this service:
```
docker build -t scan-llen https://github.com/evanx/scan-llen.git
```

We interactively run the service on our test Redis container:
```
docker run --name scan-llen-instance --rm -i \
  --network=scan-llen-network \
  -e host=$redisHost \
  -e pattern='user:*' \
  -e ttl=1 \
  scan-llen
sleep 2
```
where since the `ttl` is 1 second, we sleep for 2 seconds before checking the keys.
```
evan@dijkstra:~/scan-llen$ sh test/demo.sh
...
1 user:evanxsummers
1 user:other
...
+ redis-cli -h $redisHost keys '*'
1) "group:evanxsummers"
```
where we expired keys `user:*` and so indeed only have `group:evanxsummers` remaining.


## Implementation

See `lib/main.js`

```javascript
    let cursor;
    while (true) {
        const [result] = await multiExecAsync(client, multi => {
            multi.scan(cursor || 0, 'match', config.pattern);
        });
        cursor = parseInt(result[0]);
        const keys = result[1];
        count += keys.length;
        if (config.limit > 0 && count > config.limit) {
            console.error(clc.yellow('Limit reached. Try: limit=0'));
            break;
        }
        const results = await multiExecAsync(client, multi => {
            keys.forEach(key => multi.expire(key, config.ttl));
        });
        results.forEach((result, index) => {
            console.log(clc.green(result), keys[index]);
        });
        if (cursor === 0) {
            break;
        }
    }
```

### Appication archetype

Incidently `lib/index.js` uses the `redis-app-rpf` application archetype.
```
require('redis-app-rpf')(require('./spec'), require('./main'));
```
where we extract the `config` from `process.env` according to the `spec` and invoke our `main` function.

See https://github.com/evanx/redis-app-rpf.

This provides lifecycle boilerplate to reuse across similar applications.

<hr>
https://twitter.com/@evanxsummers
