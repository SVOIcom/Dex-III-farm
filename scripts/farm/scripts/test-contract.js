const configuration = require("../../scripts.conf");
const { loadDefaultContaracts } = require("../../utils/loadDefaultContract");

async function main() {
    let contracts = await loadDefaultContaracts();

    let testContract = await contracts.locklift.factory.getContract('test', configuration.buildDirectory);

    // await contracts.locklift.giver.deployContract({
    //     contract: testContract,
    //     constructorParams: {},
    //     initParams: {},
    //     keyPair: contracts.msigWallet.keyPair
    // });

    testContract.setAddress('0:cdfb52eb9ae6d2111ddc3a0cc8ac2d603e67ff1615a2318fce85ce130f029cf4');

    console.log(testContract.address);

    console.log(await testContract.call({
        method: 'test',
        params: {},
        keyPair: contracts.msigWallet.keyPair
    }));

    let tp = await contracts.userAccountContract.createPayload({ farm: contracts.farmContract.address });

    console.log(await contracts.userAccountContract.call({
        method: 'test',
        params: {
            _answer_id: 0,
            farm: contracts.farmContract.address,
            payload: tp
        },
        keyPair: contracts.userAccountContract.keyPair
    }));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)