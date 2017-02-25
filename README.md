# scan-llen

Containerized utility to scan and print llen of Redis keys.

<img src="https://raw.githubusercontent.com/evanx/scan-llen/master/docs/readme/main.png"/>

## Use case

We wish to scan keys in Redis using a specified pattern, and print the lengths of the list keys.

```
$ docker run -i --rm -e pattern='*' --network=host scan-llen
12 list1
5 list2
```

## Config

See `lib/config.js`
```javascript
module.exports = {
    description: 'Containerized utility to scan and print llen of Redis keys.',
    required: {
        pattern: {
            description: 'the matching pattern for Redis scan',
            example: '*'
        },
        limit: {
            description: 'the maximum number of keys to print',
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
### Test 

See `bin/test.sh` https://github.com/evanx/scan-llen/blob/master/bin/test.sh

Builds:
- isolated network `scan-llen-network`
- isolated Redis instance named `scan-llen-redis`
- this utility `evanx/scan-llen`

We populate our test keys:
```
populate() {
  redis-cli -h $redisHost lpush list1 1 | grep -q '^1$'
  redis-cli -h $redisHost lpush list2 1 | grep -q '^1$'
  redis-cli -h $redisHost lpush list2 2 | grep -q '^2$'
}
```

We build a container image for this service:
```
docker build -t scan-llen https://github.com/evanx/scan-llen.git
```

We interactively run the service on our test Redis container:
```
docker run --name scan-llen-instance --rm -i \
  --network=scan-llen-network \
  -e host=$redisHost \
  -e pattern='*' \
  scan-llen
```

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
        const types = await multiExecAsync(client, multi => {
            keys.forEach(key => multi.type(key));
        });
        const listKeys = keys.filter((key, index) => types[index] === 'list');
        if (listKeys.length) {
            count += listKeys.length;
            const results = await multiExecAsync(client, multi => {
                listKeys.forEach(key => multi.llen(key));
            });
            listKeys.forEach((key, index) => {
                const result = results[index];
                console.log(key, result);
            });
            if (config.limit > 0 && count > config.limit) {
                console.error(clc.yellow('Limit exceeded. Try: limit=0'));
                break;
            }
        }
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
