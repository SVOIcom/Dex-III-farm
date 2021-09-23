const configuration = require("../scripts.conf");
const initializeLocklift = require("./initializeLocklift");
const { writeContractData } = require("./migration/manageContractData");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    let giverContract = await locklift.factory.getContract('Giver');

    const {
        address,
    } = await locklift.ton.createDeployMessage({
        contract: giverContract,
        constructorParams: {},
        initParams: {},
        keyPair: {
            "public": "1d0bafcaa5a39a39f7567bcd5ddaa556eaa12a4eecc87ea142bd0a991e9cf749",
            "secret": "e682829f060325cdb06dedb59636f62f11234c0cbe53511580a388b38b4970bd"
        },
    });

    console.log(address);

    const message = await locklift.ton.createDeployMessage({
        contract: giverContract,
        constructorParams: {},
        initParams: {},
        keyPair: {
            "public": "1d0bafcaa5a39a39f7567bcd5ddaa556eaa12a4eecc87ea142bd0a991e9cf749",
            "secret": "e682829f060325cdb06dedb59636f62f11234c0cbe53511580a388b38b4970bd"
        }
    });

    await locklift.ton.waitForRunTransaction({message, abi: giverContract.abi});

    giverContract.setAddress(address);

    await writeContractData(giverContract, `${configuration.network}_GiverContract.json`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)