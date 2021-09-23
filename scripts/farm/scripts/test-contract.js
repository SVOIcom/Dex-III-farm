const OutputDecoder = require("locklift/locklift/contract/output-decoder");
const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");
const { stringToBytesArray } = require("../../utils/utils");

async function main() {
    let contracts = await loadDefaultContaracts();

    let testContract = await contracts.locklift.factory.getContract('test', configuration.buildDirectory);

    await contracts.locklift.giver.deployContract({
        contract: testContract,
        constructorParams: {},
        initParams: {},
        keyPair: contracts.msigWallet.keyPair
    });

    // testContract.setAddress('0:74b82d70ae0913d322a0181c9e87e4a2afa27382c824defeaaeba39044db975f');

    // testContract.setAddress('0:cdfb52eb9ae6d2111ddc3a0cc8ac2d603e67ff1615a2318fce85ce130f029cf4');

    await contracts.locklift.giver.giver.run({
        method: 'sendGrams',
        params: {
            dest: testContract.address,
            amount: contracts.locklift.utils.convertCrystal(1000, 'nano')
        },
        keyPair: contracts.msigWallet.keyPair
    });

    for (let i = 0; i < 10; i++) {
        console.log(await testContract.run({
            method: 'addElements',
            params: {
                iterations: 100
            },
            keyPair: contracts.msigWallet.keyPair
        }));
    }

    console.log(await testContract.run({
        method: 'testIteration',
        params: {},
        keyPair: contracts.msigWallet.keyPair
    }));

    // const p = require('../../../punks.json');

    // console.log(testContract.address);

    // const {
    //     result: [{
    //         boc
    //     }]
    // } = await contracts.locklift.ton.client.net.query_collection({
    //     collection: 'accounts',
    //     filter: {
    //         id: {
    //             eq: testContract.address,
    //         }
    //     },
    //     result: 'boc'
    // });

    // // Decode output
    // const functionAttributes = testContract.abi.functions.find(({ name }) => name === 'createTvmCell');

    // const outputDecoder = new OutputDecoder(
    //     '',
    //     functionAttributes
    // );

    // let id = 0;
    // let totalSum = 0;
    // for (let punk of p) {

    //     params = {
    //         _answer_id: 1,
    //         id: punk.idx,
    //         pType: punk.type == 'Male',
    //         attr: stringToBytesArray(punk.attributes.join('|')),
    //         rank: punk.rank
    //     }

    //     const {
    //         message
    //     } = await contracts.locklift.ton.createRunMessage({
    //         contract: testContract,
    //         method: 'createTvmCell',
    //         params: params,
    //         keyPair: contracts.msigWallet.keyPair,
    //     });

    //     const {
    //         decoded: {
    //             output,
    //         }
    //     } = await contracts.locklift.ton.client.tvm.run_tvm({
    //         abi: {
    //             type: 'Contract',
    //             value: testContract.abi
    //         },
    //         message: message,
    //         account: boc,
    //     });

    //     outputDecoder.output = output;

    //     let payload = await outputDecoder.decode();


    //     let result = await testContract.run({
    //         method: 'test',
    //         params: {
    //             index: id,
    //             upload: payload
    //         },
    //         keyPair: contracts.msigWallet.keyPair
    //     });

    //     totalSum += result.fees.total_account_fees;
    //     console.log(`${id}: ${result.fees.total_account_fees} | total: ${totalSum}`);
    //     id++;
    // }

    // let tp = await contracts.userAccountContract.createPayload({ farm: contracts.farmContract.address });

    // console.log(await contracts.userAccountContract.call({
    //     method: 'test',
    //     params: {
    //         _answer_id: 0,
    //         farm: contracts.farmContract.address,
    //         payload: tp
    //     },
    //     keyPair: contracts.userAccountContract.keyPair
    // }));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)