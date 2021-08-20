pragma ton-solidity >= 0.43.0;

import './interfaces/IUserAccount.sol';

import './libraries/UserAccountErrorCodes.sol';

import '../FarmContract/interfaces/IFarmContract.sol';

import '../utils/TIP3/interfaces/ITokensReceivedCallback.sol';
import '../utils/TIP3/interfaces/ITONTokenWallet.sol';
import '../utils/TIP3/interfaces/IRootTokenContract.sol';

/**
 * Процесс деплоя:
 * Создание контракта (constructor)
 */

 /**
  * Процесс входа в фармилку:
  * Запрос информации о фармилке
  * Запись инофрмации о фармилке
  * Деплой пустого кошелька для приёма платежей пользователя
  * Настройка кошелька -> запрет на переводы без notify_receiver
  */

contract UserAccount is ITokensReceivedCallback, IUserAccount {

    address static owner;

    mapping (address => UserFarmInfo) farmInfo;
    mapping (address => address) knownTokenRoots;

    // Service value
    TvmCell empty;

    constructor() public {
        tvm.accept();
    }

    function enterFarm(
        address farm, 
        address stackingTIP3UserWallet, 
        address rewardTIP3Wallet
    ) external override onlyOwner {
        farmInfo[farm] = UserFarmInfo({
            stackedTokens: 0,
            pendingReward: 0,
            rewardPerTokenSum: 0,

            stackingTIP3Wallet: address.makeAddrStd(0, 0),
            stackingTIP3UserWallet: stackingTIP3UserWallet,
            stackingTIP3Root: address.makeAddrStd(0, 0),
            rewardTIP3Wallet: rewardTIP3Wallet,

            start: 0,
            finish: 0
        });

        IFarmContract(farm).fetchInfo{
            flag: 64,
            callback: this.receiveFarmInfo
        }();
    }

    function receiveFarmInfo(FarmInfo farmInfo_) external onlyKnownFarm(msg.sender) {
        address farm = msg.sender;
        farmInfo[farm].stackingTIP3Root = farmInfo_.stackingTIP3Root;
        farmInfo[farm].start = farmInfo_.startTime;
        farmInfo[farm].finish = farmInfo_.finishTime;
        knownTokenRoots[farmInfo_.stackingTIP3Root] = farm;
        IRootTokenContract(farmInfo_.stackingTIP3Root).deployEmptyWallet{
            flag: 64
        }(
            0.4 ton,
            0,
            address(this),
            address(this)
        );
    }

    function receiveTIP3Address(address stackingTIP3Wallet) external onlyKnownTokenRoot {
        tvm.accept();
        farmInfo[knownTokenRoots[msg.sender]].stackingTIP3Wallet = stackingTIP3Wallet;
        ITONTokenWallet(stackingTIP3Wallet).setReceiveCallback{
            value: 0.1 ton,
            flag: 1
        }(
            address(this),
            false
        );

        address(owner).transfer({flag: 64, value: 0});
    }

    function tokensReceivedCallback(
        address token_wallet,
        address token_root,
        uint128 amount,
        uint256 sender_public_key,
        address sender_address,
        address sender_wallet,
        address original_gas_to,
        uint128 updated_balance,
        TvmCell payload
    ) external override {
        TvmSlice s = payload.toSlice();
        address farm = s.decode(address);

        bool messageIsCorrect = 
            msg.sender == farmInfo[farm].stackingTIP3Wallet && 
            sender_wallet == farmInfo[farm].stackingTIP3UserWallet &&
            farmInfo.exists(farm) &&
            farmInfo[farm].start <= uint64(now);

        if (!messageIsCorrect) {
            ITONTokenWallet(msg.sender).transfer {
                value: 64
            }(
                sender_wallet,
                amount,
                0,
                original_gas_to,
                true,
                payload
            );
        } else {
            farmInfo[farm].stackedTokens = farmInfo[farm].stackedTokens + amount;

            IFarmContract(farm).tokensDepositedToFarm{
                flag: 64
            }(owner, amount, farmInfo[farm].stackedTokens - amount, farmInfo[farm].pendingReward, farmInfo[farm].rewardPerTokenSum);    
        }
    }

    function withdrawPendingReward(
        address farm
    ) external override onlyOwner {
        IFarmContract(farm).withdrawPendingReward{
            flag: 64
        }(owner, farmInfo[farm].stackedTokens, farmInfo[farm].pendingReward, farmInfo[farm].rewardPerTokenSum, farmInfo[farm].rewardTIP3Wallet);
    }

    function withdrawPartWithPendingReward(
        address farm, 
        uint128 tokensToWithdraw
    ) external override onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        farmInfo[farm].stackedTokens = farmInfo[farm].stackedTokens - tokensToWithdraw;
        
        ITONTokenWallet(farmInfo[farm].stackingTIP3UserWallet).transfer{
            value: 0.15 ton
        }(
            farmInfo[farm].stackingTIP3UserWallet,
            tokensToWithdraw,
            0,
            owner,
            true,
            empty
        );

        IFarmContract(farm).withdrawWithPendingReward{
            flag: 64
        }(
            owner, 
            tokensToWithdraw, 
            farmInfo[farm].stackedTokens + tokensToWithdraw, 
            farmInfo[farm].pendingReward, 
            farmInfo[farm].rewardPerTokenSum, 
            farmInfo[farm].rewardTIP3Wallet
        );
    }

    function withdrawAllWithPendingReward(
        address farm
    ) external override onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        require(msg.sender == owner);
        uint128 tokensToWithdraw = farmInfo[farm].stackedTokens;
        farmInfo[farm].stackedTokens = 0;

        ITONTokenWallet(farmInfo[farm].stackingTIP3UserWallet).transfer{
            value: 0.15 ton
        }(
            farmInfo[farm].stackingTIP3UserWallet,
            tokensToWithdraw,
            0,
            owner,
            true,
            empty
        );

        IFarmContract(farm).withdrawWithPendingReward{
            flag: 64
        }(
            owner, 
            tokensToWithdraw, 
            tokensToWithdraw,
            farmInfo[farm].pendingReward, 
            farmInfo[farm].rewardPerTokenSum, 
            farmInfo[farm].rewardTIP3Wallet
        );
    }

    function updateReward(
        address farm
    ) external override onlyOwner {
        IFarmContract(farm).updateUserReward{
            flag: 64
        }(
            owner, 
            farmInfo[farm].stackedTokens, 
            farmInfo[farm].rewardPerTokenSum, 
            farmInfo[farm].pendingReward
        );
    }

    function udpateRewardInfo(
        uint128 userReward, 
        uint128 rewardPerTokenSum
    ) external override onlyKnownFarm(msg.sender) {
        farmInfo[msg.sender].pendingReward = userReward;
        farmInfo[msg.sender].rewardPerTokenSum = rewardPerTokenSum;

        address(owner).transfer({flag: 64, value: 0});
    }

    function getUserFarmInfo(
        address farm
    ) external override responsible onlyKnownFarm(farm) returns (UserFarmInfo) {
        return {flag: 64} farmInfo[farm];
    }

    function getAllUserFarmInfo() external override responsible returns (mapping(address => UserFarmInfo)) {
        return {flag: 64} farmInfo;
    }

    function createPayload(
        address farm
    ) external override responsible onlyKnownFarm(farm) returns(TvmCell) {
        TvmBuilder builder;
        builder.store(farm);
        return builder.toCell();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, UserAccountErrorCodes.ERROR_ONLY_OWNER);
        _;
    } 

    modifier onlyKnownFarm(address farm) {
        require(farmInfo.exists(farm), UserAccountErrorCodes.ERROR_ONLY_KNOWN_FARM);
        _;
    }

    modifier onlyKnownTokenRoot() {
        require(knownTokenRoots.exists(msg.sender), UserAccountErrorCodes.ERROR_ONLY_KNOWN_TOKEN_ROOT);
        _;
    }

    modifier onlyActiveFarm(address farm) {
        require(farmInfo[farm].start <= uint64(now), UserAccountErrorCodes.ERROR_ONLY_ACTIVE_FARM);
        _;
    }
}