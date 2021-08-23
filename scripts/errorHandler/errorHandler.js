/**
 * Parse error and try to extract address
 * @param {Object} err 
 * @returns {String}
 */
function tryToExtractAddress(err) {
    if (err.code == 414) {
        if (err.data.exit_code == 51) {
            return err.data.account_address;
        }
    }
    return '';
}

module.exports = tryToExtractAddress;