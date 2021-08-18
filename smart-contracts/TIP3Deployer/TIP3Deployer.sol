pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ITIP3Deployer.sol';
import './interfaces/ITIP3DeployerManageCode.sol';
import './interfaces/ITIP3DeployerServiceInfo.sol';

import './libraries/TIP3DeployerErrorCodes.sol';

import '../utils/libraries/MsgFlag.sol';

import '../utils/interfaces/IUpgradableContract.sol';
import '../utils/TIP3/RootTokenContract.sol';

contract TIP3TokenDeployer is ITIP3Deployer, ITIP3DeployerManageCode, ITIP3DeployerServiceInfo, IUpgradableContract {
    TvmCell rootContractCode;
    TvmCell walletContractCode;
    address ownerAddress;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    /*********************************************************************************************************/
    // Basic functions for deploy and upgrade

    // Contract is deployed using platform
    constructor() public {
        revert();
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
        refs:
            1. platformCode
            2. initialData:
                bits:
                    address ownerAddress
     */
    function onCodeUpgrade(TvmCell upgradeData) private {
        tvm.resetStorage();
        TvmSlice dataSlice = upgradeData.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice ref = dataSlice.loadRefAsSlice();  // Loading initial parameters
        (ownerAddress) = ref.decode(address);
    }

    /** Upgrade contract code from version 0 to 1
      Data:
        bits:
            1. address root
            2. uint8 contractType
            3. uint32 codeVersion
        refs:
            1. TvmCell platform code
            3. ownerInfo:
                bits:
                    1. address ownerAddress
            2. codeInfo:
                refs:
                    1. TvmCell rootContractCode
                    2. TvmCell walletContractCode
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        // Store owner info
        TvmBuilder ownerInfo;
        ownerInfo.store(ownerAddress);

        TvmBuilder codeInfo;
        codeInfo.store(rootContractCode);
        codeInfo.store(walletContractCode);

        builder.store(ownerInfo.toCell());
        builder.store(codeInfo.toCell());

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    /*********************************************************************************************************/
    // Functions for TIP-3 token deploy
    /**
     * @param rootInfo Information required to create TIP-3 token
     * @param deployGrams Amount of tons to transfer to root contract
     * @param pubkeyToInsert Pubker used for contract
     */
    function deployTIP3(IRootTokenContract.IRootTokenContractDetails rootInfo, uint128 deployGrams, uint256 pubkeyToInsert) 
        external
        responsible
        override
        checkMsgValue(deployGrams)
        returns (address) 
    {
        tvm.rawReserve(msg.value, 2);
        address tip3TokenAddress = new RootTokenContract{
            value: deployGrams,
            flag: 0,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        }(rootInfo.root_public_key, rootInfo.root_owner_address);

        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } tip3TokenAddress;
    }

    /**
     * @param rootInfo Information required to create TIP-3 token
     * @param pubkeyToInsert Pubkey used for contract
     */
    function getFutureTIP3Address(IRootTokenContract.IRootTokenContractDetails rootInfo, uint256 pubkeyToInsert) external override responsible returns (address) {
        tvm.accept();
        TvmCell stateInit = tvm.buildStateInit({
            contr: RootTokenContract,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        });

        return address.makeAddrStd(0, tvm.hash(stateInit));
    }

    /*********************************************************************************************************/
    // TIP-3 code update functions
    /**
     * @param rootContractCode_ Code of RootTokenContract
     */
    function setTIP3RootContractCode(TvmCell rootContractCode_) external override onlyOwner {
        tvm.accept();
        rootContractCode = rootContractCode_;
    }

    /**
     * @param walletContractCode_ Code of TONTokenWallet
     */
    function setTIP3WalletContractCode(TvmCell walletContractCode_) external override onlyOwner {
        tvm.accept();
        walletContractCode = walletContractCode_;
    }

    function getServiceInfo() external override responsible view returns (ServiceInfo) {
        return ServiceInfo(rootContractCode, walletContractCode);
    }

    /*********************************************************************************************************/
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, TIP3DeployerErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWNER);
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root, TIP3DeployerErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    modifier checkMsgValue(uint128 gramsRequired) {
        require(msg.value > gramsRequired, TIP3DeployerErrorCodes.ERROR_MSG_VALUE_IS_TOO_LOW);
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, TIP3DeployerErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}