/**
 * @typedef ScriptConfiguration
 * @type {Object}
 * 
 * @property {String} network
 * @property {String} buildDirectory
 * @property {String} pathToLockliftConfig
 */

/**
 * @type {ScriptConfiguration}
 */
const configuration = {
    network: 'local',
    buildDirectory: './build',
    pathToLockliftConfig: './scripts/l.conf.js'
}

module.exports = configuration;