const Contract = require("locklift/locklift/contract");
const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { loadContractData } = require("../../utils/migration/manageContractData");

async function main() {
    let contracts = await loadDefaultContaracts();
    /**
     * @type {Contract}
     */
    let tip3WalletContract = await loadContractData(contracts.locklift, configuration, `${configuration.network}_StackingWallet.json`);
    tip3WalletContract.setAddress('0:56034e8aa1084ed80589a7cc39cd04ad87783dc90a36c8c0186d4d0f0cadbfc1');

    let messages = await contracts.locklift.ton.client.net.query_collection({
        collection: 'messages',
        filter: {
            dst: { eq: tip3WalletContract.address },
        },
        order: [{
            path: 'created_lt',
            direction: 'ASC'
        }],
        result: "id created_lt msg_type status src dst value boc body"
    });

    for (let message of messages.result) {
        try {
            let result = await contracts.locklift.ton.client.abi.decode_message_body({
                body: message.body,
                is_internal: true,
                abi: {
                    type: 'Contract',
                    value: tip3WalletContract.abi
                }
            });
            console.log(result);
        } catch (err) {
            console.log('cannot decode');
        }
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)