pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/IFarmContract.sol';

import './libraries/FarmContractCostConstants.sol';
import './libraries/FarmContractErrorCodes.sol';

import '../UserAccount/UserAccount.sol';
import '../UserAccount/interfaces/IUserAccount.sol';

import '../utils/TIP3/interfaces/ITONTokenWallet.sol';
import '../utils/TIP3/interfaces/IRootTokenContract.sol';

/**
 * Initialization process:
 * Deploy farm
 * Set user account code
 * Set farm parameters (startFarming)
 * Contract deploys reward wallet for itself
 * Await deploying reward wallet
 * Transfer tokens to reward wallet
 * Await start of farming
 * After the end of farming + some time -> withdraw remaining tokens and destroy farm (1-2 weeks)
 */

contract FarmContract is IFarmContract {

    uint256 static uniqueID;

    address owner;

    FarmInfo farmInfo;

    uint128 constant public improvedPrecision = 1e18;

    TvmCell userAccountCode;
    TvmCell empty;

    /**
     * @param ownerAddress Address of owner's ton wallet 
     */
    constructor(address ownerAddress) public {
        tvm.accept();
        owner = ownerAddress;
    }

    function fetchInfo() external override responsible returns (FarmInfo) {
        return {flag: 64} farmInfo;
    } 

    /**
     * @param userAccountCode_ Code of user's account. Used for deploy and address calculation
     */
    function setUserAccountCode(TvmCell userAccountCode_) external override onlyOwner {
        userAccountCode = userAccountCode_;
    }

    /**
     * @param stackingTIP3Address Root address of token that will be stacked
     * @param rewardTIP3Address Root address of reward token
     * @param totalReward Total distributed reward
     * @param startTime Start of farming
     * @param finishTime Finish of farming
     */
    function startFarming(
        address stackingTIP3Address, 
        address rewardTIP3Address, 
        uint128 totalReward,
        uint64 startTime,
        uint64 finishTime
    ) external override onlyOwner farmInactive {
        farmInfo.stackingTIP3Root = stackingTIP3Address;
        farmInfo.rewardTIP3Root = rewardTIP3Address;
        farmInfo.rewardTIP3Wallet = address.makeAddrStd(0, 0);

        farmInfo.rewardPerTokenSum = 0;
        farmInfo.totalReward = totalReward;
        farmInfo.totalPayout = 0;
        farmInfo.totalStacked = 0;

        farmInfo.startTime = startTime;
        farmInfo.finishTime = finishTime;
        farmInfo.duration = finishTime - startTime;
        deployRewardTIP3Wallet();
    }

    function deployRewardTIP3Wallet() internal view {
        IRootTokenContract(farmInfo.rewardTIP3Root).deployEmptyWallet{
            value: FarmContractCostConstants.sendToDeployTIP3Wallet
        }({
            deploy_grams: FarmContractCostConstants.deployTIP3Wallet,
            wallet_public_key: 0,
            owner_address: address(this),
            gas_back_address: owner
        });

        IRootTokenContract(farmInfo.rewardTIP3Root).getWalletAddress{
            value: FarmContractCostConstants.sendToGetAddress,
            callback: this.receiveTIP3RewardWalletAddress
        }({
            wallet_public_key: 0,
            owner_address: address(this)
        });
    }

    /**
     * @param rewardTIP3Wallet Address of wallet used for reward payouts, requires transferring tokens to it
     */
    function receiveTIP3RewardWalletAddress(address rewardTIP3Wallet) external onlyRewardTIP3Root {
        tvm.accept();
        farmInfo.rewardTIP3Wallet = rewardTIP3Wallet;
        address(owner).transfer({value: 0, flag: 64});
    }

    /**
     * @param userAccountOwner Address of user account owner, used for address calculation
     * @param tokensDeposited How much tokens were provided
     * @param tokensAmount How much tokens were stacked before providing
     * @param pendingReward Reward already obtained by user
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     */
    function tokensDepositedToFarm(
        address userAccountOwner, 
        uint128 tokensDeposited, 
        uint128 tokensAmount, 
        uint128 pendingReward,
        uint128 rewardPerTokenSum
    ) external override onlyValidUserAccount(userAccountOwner) {
        
        (uint128 userRewardDelta) = updateReward(tokensAmount - tokensDeposited, rewardPerTokenSum);
        
        farmInfo.totalStacked += tokensDeposited;

        updateUserInfo(msg.sender, userRewardDelta + pendingReward);

    }

    /**
     * @param userAccountOwner Address of user account owner, used for address calculation
     * @param tokenAmount How much tokens were stacked before providing
     * @param pendingReward Reward already obtained by user
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     * @param rewardWallet User's reward wallet
     */
    function withdrawPendingReward(
        address userAccountOwner, 
        uint128 tokenAmount, 
        uint128 pendingReward,
        uint128 rewardPerTokenSum, 
        address rewardWallet
    ) external override onlyValidUserAccount(userAccountOwner) {
        (uint128 userRewardDelta) = updateReward(tokenAmount, rewardPerTokenSum);

        updateUserInfo(msg.sender, 0);

        payoutReward(userAccountOwner, rewardWallet, pendingReward + userRewardDelta);
    }

    /**
     * @param userAccountOwner Address of user account owner, used for address calculation
     * @param tokensToWithdraw How much tokens user want to withdraw from stacking
     * @param originalTokensAmount How much tokens were stacked before withdrawing
     * @param pendingReward Reward already obtained by user
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     * @param rewardWallet User's reward wallet
     */
    function withdrawWithPendingReward(
        address userAccountOwner, 
        uint128 tokensToWithdraw, 
        uint128 originalTokensAmount, 
        uint128 pendingReward, 
        uint128 rewardPerTokenSum, 
        address rewardWallet
    ) external override onlyValidUserAccount(userAccountOwner)  {
        (uint128 userRewardDelta) = updateReward(originalTokensAmount, rewardPerTokenSum);
        
        farmInfo.totalStacked -= tokensToWithdraw;

        updateUserInfo(msg.sender, 0);

        payoutReward(userAccountOwner, rewardWallet, pendingReward + userRewardDelta);
    }

    /**
     * @param userAccountOwner Address of user account owner, used for address calculation
     * @param tokenAmount How much tokens were stacked before providing
     * @param pendingReward Reward already obtained by user
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     */
    function updateUserReward(
        address userAccountOwner,
        uint128 tokenAmount,
        uint128 pendingReward,
        uint128 rewardPerTokenSum
    ) external override onlyValidUserAccount(userAccountOwner) {
        (uint128 userRewardDelta) = updateReward(tokenAmount, rewardPerTokenSum);

        updateUserInfo(msg.sender, pendingReward + userRewardDelta);

        address(userAccountOwner).transfer({value: 0, flag: 64});
    }

    /**
     * @param stackedAmount How much tokens did user stack
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     */
    function updateReward(
        uint128 stackedAmount, 
        uint128 rewardPerTokenSum
    ) internal returns (uint128) {
        uint64 currentTime = uint64(now);
        uint64 dt = currentTime - farmInfo.lastRPTSupdate;

        if (dt == 0) {
            uint128 rewardPerToken = improvedPrecision * dt * farmInfo.totalReward / farmInfo.duration / farmInfo.totalStacked;

            farmInfo.rewardPerTokenSum += rewardPerToken;
            farmInfo.lastRPTSupdate = currentTime;
        }

        uint128 userRewardDelta = (farmInfo.rewardPerTokenSum - rewardPerTokenSum) * stackedAmount / improvedPrecision;
        return userRewardDelta;
    }

    /**
     * @param userToUpdate Which user account to udpate
     * @param totalUserReward User's total current reward
     */
    function updateUserInfo(
        address userToUpdate,
        uint128 totalUserReward
    ) internal view {
        IUserAccount(userToUpdate).udpateRewardInfo{
            value: FarmContractCostConstants.updateUserInfo
        }(
            totalUserReward, farmInfo.rewardPerTokenSum
        );
    }

    /**
     * @param userAccountOwner Address of user account owner
     * @param rewardWallet User's reward wallet
     * @param userReward Reward that will be sent to user
     */
    function payoutReward(
        address userAccountOwner, 
        address rewardWallet,
        uint128 userReward
    ) internal {
        if (userReward != 0) {
            farmInfo.totalPayout += userReward;
            ITONTokenWallet(farmInfo.rewardTIP3Wallet).transfer{
                flag: 64
            }({
                to: rewardWallet,
                tokens: userReward,
                grams: 0,
                send_gas_to: userAccountOwner,
                notify_receiver: true,
                payload: empty
            });
        } else {
            address(userAccountOwner).transfer({flag: 64, value: 0});
        }
    }

    /**
     * @param tokenAmount How much tokens did user stack
     * @param pendingReward Reward already obtained by user
     * @param rewardPerTokenSum Last value of reward per one stacked token summed known by user
     */
    function calculateReward(
        uint128 tokenAmount,
        uint128 pendingReward, 
        uint128 rewardPerTokenSum
    ) external override responsible returns(uint128) {
        return {flag: 64} pendingReward + (farmInfo.rewardPerTokenSum - rewardPerTokenSum) * tokenAmount / improvedPrecision;
    }

    /**
     * @param userAccountOwner Address of user account owner
     */
    function deployUserAccount(address userAccountOwner) external override {
        new UserAccount{
            stateInit: _buildUserAccount(userAccountOwner),
            code: userAccountCode,
            value: 0,
            flag: 64
        }();
    }

    /**
     * @param userAccountOwner Address of user account owner
     */
    function _getUserAccountAddress(address userAccountOwner) internal view returns(address) {
        return address.makeAddrStd(0, tvm.hash(_buildUserAccount(userAccountOwner)));
    }

    /**
     * @param userAccountOwner Address of user account owner
     */
    function getUserAccountAddress(address userAccountOwner) external override responsible returns(address) {
        return _getUserAccountAddress(userAccountOwner);
    }

    /**
     * @param userAccountOwner Address of user account owner
     */
    function _buildUserAccount(address userAccountOwner) internal view returns(TvmCell) {
        return tvm.buildStateInit({
            contr: UserAccount,
            varInit: {
                owner: userAccountOwner
            },
            pubkey: 0,
            code: userAccountCode
        });
    }

    /**
     * @param sendTokensTo Wallet to send remaining tokens to
     * @param tokenAmount Amount of tokens remaining on contract balance
     */
    function endFarming(
        address sendTokensTo,
        uint128 tokenAmount
    ) external override onlyOwner farmEnded {
        tvm.accept();

        ITONTokenWallet(farmInfo.rewardTIP3Wallet).transfer{
            value: 0.15 ton
        }({
            to: sendTokensTo,
            tokens: tokenAmount,
            grams: 0,
            send_gas_to: owner,
            notify_receiver: true,
            payload: empty
        });

        address(owner).transfer({value: 0, flag: 128 + 32});
    }

    modifier onlyOwner() {
        require(msg.sender == owner, FarmContractErrorCodes.ERROR_ONLY_OWNER);
        _;
    }

    modifier onlyRewardTIP3Root() {
        require(msg.sender == farmInfo.rewardTIP3Root, FarmContractErrorCodes.ERROR_ONLY_REWARD_TIP3_ROOT);
        _;
    }

    /**
     * @param userAccountOwner Address of user account owner
     */
    modifier onlyValidUserAccount(address userAccountOwner) {
        require(msg.sender == _getUserAccountAddress(userAccountOwner), FarmContractErrorCodes.ERROR_INVALID_USER_ACCOUNT);
        _;
    }

    modifier activeFarm() {
        require(uint64(now) >= farmInfo.startTime && uint64(now) <= farmInfo.finishTime, FarmContractErrorCodes.ERROR_ONLY_ACTIVE_FARM);
        _;
    }

    modifier farmInactive() {
        require(farmInfo.startTime == 0, FarmContractErrorCodes.ERROR_ONLY_INACTIVE_FARM);
        _;
    }

    modifier farmEnded() {
        require(uint64(now) > farmInfo.finishTime);
        _;
    }
}