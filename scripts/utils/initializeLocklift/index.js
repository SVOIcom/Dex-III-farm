const { Locklift } = require('locklift/locklift');

const { loadConfig } = require('./load_config');

let locklift = undefined;

/**
 * 
 * @param {String} configPath 
 * @param {String} network 
 * @returns { Locklift }
 */
module.exports = async(configPath, network) => {
    if (!locklift) {
        locklift = new Locklift(await loadConfig(configPath), network);
        await locklift.setup();
    }
    return locklift;
}