const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");

async function main() {
    let contracts = await loadDefaultContaracts();
    let messages = await contracts.locklift.ton.client.net.query_collection({
        collection: 'messages',
        filter: {
            dst: { eq: contracts.farmContract.address },
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
                    value: contracts.farmContract.abi
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