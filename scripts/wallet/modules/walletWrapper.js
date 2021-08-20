const Contract = require('locklift/locklift/contract');

/**
 * Add functionality of MsigWallet (multisig) to contract. THIS IS INTERFACE, to gain real functionality use extendContractToWallet
 * @name MsigWallet
 * @class
 * @augments Contract
 */
class MsigWallet extends Contract {
    /**
     * Transfer TONs to specified destination
     * @param {String} destination 
     * @param {String} value 
     * @param {Number} flags 
     * @param {Boolean} bounce
     * @param {String} payload 
     */
    async transfer(destination, value, flags, bounce, payload) {}
}

/**
 * Extend contract to multisig wallet
 * @param {Contract} contract 
 * @returns {MsigWallet}
 */
function extendContractToWallet(contract) {
    contract.transfer = async function(destination, value, flags, bounce, payload) {
        return await contract.run({
            method: 'sendTransaction',
            params: {
                dest: destination,
                value: value,
                bounce: bounce,
                flags: flags,
                payload: payload
            },
            keyPair: contract.keyPair
        })
    }

    return contract;
}

module.exports = {
    MsigWallet,
    extendContractToWallet
}