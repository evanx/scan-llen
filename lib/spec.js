module.exports = {
    description: 'Containerized utility to scan and print llen of Redis keys.',
    required: {
        pattern: {
            description: 'the matching pattern for Redis scan',
            example: '*'
        },
        limit: {
            description: 'the maximum number of keys to print',
            note: 'zero means unlimited',
            default: 10
        },
        host: {
            description: 'the Redis host',
            default: 'localhost'
        },
        port: {
            description: 'the Redis port',
            default: 6379
        },
        loggerLevel: {
            description: 'the logging level',
            default: 'info',
            options: ['debug', 'warn', 'error']
        }
    },
    development: {
        loggerLevel: 'debug'
    },
    test: {
        loggerLevel: 'debug'
    }
}
