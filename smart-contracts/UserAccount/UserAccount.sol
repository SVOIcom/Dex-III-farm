pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './interfaces/IUserAccount.sol';

import './libraries/UserAccountErrorCodes.sol';
import './libraries/UserAccountCostConstants.sol';

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
    TvmCell templateCell;

    constructor() public {
        tvm.accept();
        TvmBuilder tb;
        tb.store(address(this));
        templateCell = tb.toCell();
    }

    /**
     * @param farm Address of farm contract
     * @param stackingTIP3UserWallet User's wallet with stacking tokens
     * @param rewardTIP3Wallet User's wallet for reward payouts
     */
    function enterFarm(
        address farm, 
        address stackingTIP3UserWallet, 
        address rewardTIP3Wallet
    ) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (addrNotZero(farm) && !farmInfo.exists(farm) && addrNotZero(stackingTIP3UserWallet) && addrNotZero(rewardTIP3Wallet)) {
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
        } else {
            address(owner).transfer({value: 0, flag: 64});
        }
    }

    /**
     * @param farmInfo_ Information about farm
     */
    function receiveFarmInfo(FarmInfo farmInfo_) external onlyKnownFarm(msg.sender) {
        tvm.accept();
        address farm = msg.sender;
        farmInfo[farm].stackingTIP3Root = farmInfo_.stackingTIP3Root;
        farmInfo[farm].start = farmInfo_.startTime;
        farmInfo[farm].finish = farmInfo_.finishTime;
        knownTokenRoots[farmInfo_.stackingTIP3Root] = farm;

        IRootTokenContract(farmInfo_.stackingTIP3Root).deployEmptyWallet{
            value: 0.6 ton
        }({
            deploy_grams: UserAccountCostConstants.deployTIP3Wallet,
            wallet_public_key: 0,
            owner_address: address(this),
            gas_back_address: owner
        });

        IRootTokenContract(farmInfo_.stackingTIP3Root).getWalletAddress{
            value: UserAccountCostConstants.getWalletAddress,
            callback: this.receiveTIP3Address
        }({
            wallet_public_key: 0,
            owner_address: address(this)
        });
    }

    /**
     * @param stackingTIP3Wallet Wallet required for receiving user's stacking
     */
    function receiveTIP3Address(address stackingTIP3Wallet) external onlyKnownTokenRoot {
        tvm.accept();
        farmInfo[knownTokenRoots[msg.sender]].stackingTIP3Wallet = stackingTIP3Wallet;
        ITONTokenWallet(stackingTIP3Wallet).setReceiveCallback{
            value: UserAccountCostConstants.setReceiveCallback
        }({
            receive_callback: address(this),
            allow_non_notifiable: false
        });
    }

    function tokensReceivedCallback(
        address, // token_wallet,
        address token_root,
        uint128 amount,
        uint256, // sender_public_key,
        address, // sender_address,
        address sender_wallet,
        address original_gas_to,
        uint128, // updated_balance,
        TvmCell payload
    ) external override {
        tvm.rawReserve(msg.value, 2);
        TvmSlice s = payload.toSlice();
        // TvmSlice t = templateCell.toSlice();
        address farm = s.decode(address);

        bool messageIsCorrect =
            (token_root == farmInfo[farm].stackingTIP3Root) &&
            farmInfo.exists(farm) &&
            farmActive(farm);

        if (!messageIsCorrect) {
            ITONTokenWallet(msg.sender).transfer{
                flag: 64
            }({
                to: sender_wallet,
                tokens: amount,
                grams: 0,
                send_gas_to: original_gas_to,
                notify_receiver: true,
                payload: empty
            });
        } else {
            farmInfo[farm].stackedTokens = farmInfo[farm].stackedTokens + amount;

            IFarmContract(farm).tokensDepositedToFarm{
                flag: 64
            }({
                userAccountOwner: owner, 
                tokensDeposited: amount, 
                tokensAmount: farmInfo[farm].stackedTokens, 
                pendingReward: farmInfo[farm].pendingReward, 
                rewardPerTokenSum: farmInfo[farm].rewardPerTokenSum
            });    
        }
    }

    function farmActive(address farm) private view returns(bool) {
        return farmInfo[farm].start <= uint64(now) &&  uint64(now) < farmInfo[farm].finish;
    }

    /**
     * @param farm Address of farm contract
     */
    function withdrawPendingReward(
        address farm
    ) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        IFarmContract(farm).withdrawPendingReward{
            flag: 64
        }({
            userAccountOwner: owner, 
            tokenAmount: farmInfo[farm].stackedTokens, 
            pendingReward: farmInfo[farm].pendingReward, 
            rewardPerTokenSum: farmInfo[farm].rewardPerTokenSum
        });
    }

    /**
     * @param farm Address of farm contract
     * @param tokensToWithdraw How much tokens will be withdrawed from stack 
     */
    function withdrawPartWithPendingReward(
        address farm, 
        uint128 tokensToWithdraw
    ) external override onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        tvm.rawReserve(msg.value, 2);
        farmInfo[farm].stackedTokens = farmInfo[farm].stackedTokens - tokensToWithdraw;
        
        transferTokensBack(farm, tokensToWithdraw);

        IFarmContract(farm).withdrawWithPendingReward{
            flag: 64
        }({
            userAccountOwner: owner, 
            tokensToWithdraw: tokensToWithdraw, 
            originalTokensAmount: farmInfo[farm].stackedTokens + tokensToWithdraw, 
            pendingReward: farmInfo[farm].pendingReward, 
            rewardPerTokenSum: farmInfo[farm].rewardPerTokenSum
        });
    }

    /**
     * @param farm Address of farm contract
     */
    function withdrawAllWithPendingReward(
        address farm
    ) external override onlyOwner onlyKnownFarm(farm) onlyActiveFarm(farm) {
        require(msg.sender == owner);
        tvm.rawReserve(msg.value - UserAccountCostConstants.transferTokens - 0.05 ton, 2);
        uint128 tokensToWithdraw = farmInfo[farm].stackedTokens;
        farmInfo[farm].stackedTokens = 0;

        transferTokensBack(farm, tokensToWithdraw);

        IFarmContract(farm).withdrawWithPendingReward{
            flag: 64
        }({
            userAccountOwner: owner, 
            tokensToWithdraw: tokensToWithdraw, 
            originalTokensAmount: tokensToWithdraw,
            pendingReward: farmInfo[farm].pendingReward, 
            rewardPerTokenSum: farmInfo[farm].rewardPerTokenSum
        });
    }

    /**
     * @param farm Address of farm contract
     * @param tokenAmount Amount of tokens to transfer back to user
     */
    function transferTokensBack(address farm, uint128 tokenAmount) internal view {
        ITONTokenWallet(farmInfo[farm].stackingTIP3Wallet).transfer{
            value: UserAccountCostConstants.transferTokens
        }({
            to: farmInfo[farm].stackingTIP3UserWallet,
            tokens: tokenAmount,
            grams: 0,
            send_gas_to: owner,
            notify_receiver: true,
            payload: empty
        });
    }

    /**
     * @param farm Address of farm contract
     */
    function updateReward(
        address farm
    ) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        IFarmContract(farm).updateUserReward{
            flag: 64
        }({
            userAccountOwner: owner, 
            tokenAmount: farmInfo[farm].stackedTokens, 
            pendingReward: farmInfo[farm].pendingReward, 
            rewardPerTokenSum: farmInfo[farm].rewardPerTokenSum
        });
    }

    /**
     * @param userReward User current reward after update
     * @param rewardPerTokenSum Last known value of reward per token summed
     * @param tokensToPayout Tokens to payout to user
     */
    function udpateRewardInfo(
        uint128 userReward, 
        uint256 rewardPerTokenSum,
        uint128 tokensToPayout
    ) external override onlyKnownFarm(msg.sender) {
        tvm.rawReserve(msg.value, 2);
        farmInfo[msg.sender].pendingReward = userReward;
        farmInfo[msg.sender].rewardPerTokenSum = rewardPerTokenSum;

        if (tokensToPayout == 0) { 
            address(owner).transfer({flag: 64, value: 0});
        } else {
            IFarmContract(msg.sender).payoutReward{
                flag: 64
            }({
                userAccountOwner: owner,
                rewardTIP3Wallet: farmInfo[msg.sender].rewardTIP3Wallet,
                userReward: tokensToPayout
            });
        }
    }

    /**
     * @param farm Address of farm contract
     */
    function getUserFarmInfo(
        address farm
    ) external override responsible returns (UserFarmInfo) {
        return {flag: 64} farmInfo[farm];
    }

    function getAllUserFarmInfo() external override responsible returns (mapping(address => UserFarmInfo)) {
        return {flag: 64} farmInfo;
    }

    /**
     * @param farm Address of farm contract
     */
    function createPayload(
        address farm
    ) external override responsible returns(TvmCell) {
        TvmBuilder builder;
        builder.store(farm);
        return builder.toCell();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, UserAccountErrorCodes.ERROR_ONLY_OWNER);
        _;
    } 

    /**
     * @param farm Address of farm contract
     */
    modifier onlyKnownFarm(address farm) {
        require(farmInfo.exists(farm), UserAccountErrorCodes.ERROR_ONLY_KNOWN_FARM);
        _;
    }

    /**
     * @param farm Address of farm contract
     */
    modifier onlyUnknownFarm(address farm) {
        require(!farmInfo.exists(farm), UserAccountErrorCodes.ERROR_ONLY_UNKNOWN_FARM);
        _;
    }

    modifier onlyKnownTokenRoot() {
        require(knownTokenRoots.exists(msg.sender), UserAccountErrorCodes.ERROR_ONLY_KNOWN_TOKEN_ROOT);
        _;
    }

    /**
     * @param farm Address of farm contract
     */
    modifier onlyActiveFarm(address farm) {
        require(farmInfo[farm].start <= uint64(now), UserAccountErrorCodes.ERROR_ONLY_ACTIVE_FARM);
        _;
    }

    /**
     * @param addr Address to check
     */
    function addrNotZero(address addr) internal pure returns (bool) {
        return addr.value != 0;
    }
}