pragma ton-solidity >= 0.43.0;

import './interfaces/IFarmContract.sol';

import './libraries/FarmContractErrorCodes.sol';

import '../UserAccount/UserAccount.sol';
import '../UserAccount/interfaces/IUserAccount.sol';

import '../utils/TIP3/interfaces/ITONTokenWallet.sol';


contract FarmContract is IFarmContract {

    uint256 static uniqueID;

    address owner;

    FarmInfo farmInfo;

    uint128 constant public improvedPrecision = 1e18;

    TvmCell userAccountCode;
    TvmCell empty;

    constructor(address ownerAddress) public {
        tvm.accept();
        owner = ownerAddress;
    }

    function fetchInfo() external override responsible returns (FarmInfo) {
        return {flag: 64} farmInfo;
    } 

    function setUserAccountCode(TvmCell userAccountCode_) external override onlyOwner {
        userAccountCode = userAccountCode_;
    }

    function startFarming(
        address stackingTIP3Address_, 
        address rewardTIP3Address_, 
        address rewardTIP3Wallet_, 
        uint128 totalReward,
        uint64 startTime_,
        uint64 finishTime_
    ) external override onlyOwner farmInactive {
        farmInfo.stackingTIP3Root = stackingTIP3Address_;
        farmInfo.rewardTIP3Root = rewardTIP3Address_;
        farmInfo.rewardTIP3Wallet = rewardTIP3Wallet_;

        farmInfo.rewardPerTokenSum = 0;
        farmInfo.totalReward = totalReward;
        farmInfo.totalPayout = 0;
        farmInfo.totalStacked = 0;

        farmInfo.startTime = startTime_;
        farmInfo.finishTime = finishTime_;
        farmInfo.duration = finishTime_ - startTime_;
    }

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

    function updateUserReward(
        address userAccountOwner,
        uint128 tokenAmount,
        uint128 pendingReward,
        uint128 rewardPerTokenSum
    ) external override onlyValidUserAccount(userAccountOwner) {
        (uint128 userRewardDelta) = updateReward(tokenAmount, rewardPerTokenSum);

        updateUserInfo(msg.sender, pendingReward + userRewardDelta);

        address(userAccountOwner).transfer({value: 64});
    }

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

    function updateUserInfo(
        address userToUpdate,
        uint128 totalUserReward
    ) internal view {
        IUserAccount(userToUpdate).udpateRewardInfo{
            value: 0.1 ton
        }(
            totalUserReward, farmInfo.rewardPerTokenSum
        );
    }

    function payoutReward(
        address userAccountOwner, 
        address rewardWallet,
        uint128 userReward
    ) internal {
        if (userReward != 0) {
            farmInfo.totalPayout += userReward;
            ITONTokenWallet(farmInfo.rewardTIP3Wallet).transfer{
                flag: 64
            }(
                rewardWallet,
                userReward,
                0,
                userAccountOwner,
                true,
                empty
            );
        } else {
            address(userAccountOwner).transfer({flag: 64, value: 0});
        }
    }

    function calculateReward(
        uint128 tokenAmount,
        uint128 pendingReward, 
        uint128 rewardPerTokenSum
    ) external override responsible returns(uint128) {
        return {flag: 64} pendingReward + (farmInfo.rewardPerTokenSum - rewardPerTokenSum) * tokenAmount / improvedPrecision;
    }

    function deployUserAccount(address userAccountOwner) external override {
        new UserAccount{
            stateInit: _buildUserAccount(userAccountOwner),
            code: userAccountCode,
            value: 1 ton,
            flag: 64
        }();
    }

    function _getUserAccountAddress(address userAccountOwner) internal view returns(address) {
        return address.makeAddrStd(0, tvm.hash(_buildUserAccount(userAccountOwner)));
    }

    function getUserAccountAddress(address userAccountOwner) external override responsible returns(address) {
        return _getUserAccountAddress(userAccountOwner);
    }

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

    modifier onlyOwner() {
        require(msg.sender == owner, FarmContractErrorCodes.ERROR_ONLY_OWNER);
        _;
    }

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
}