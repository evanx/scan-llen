
module.exports = async context => {
    const {config, logger, client} = context;
    Object.assign(global, context);
    try {
        let count = 0;
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
                    console.log(`${result} ${key}`);
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
    } catch (err) {
       throw err;
    } finally {
    }
};
