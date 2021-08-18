pragma ton-solidity >= 0.43.0;

import './interfaces/IFarmContract.sol';

import '../UserAccount/interfaces/IUserAccount.sol';

import '../TIP3Deployer/interfaces/ITIP3Deployer.sol';


contract FarmContract is ITokensReceivedCallback {

    uint256 static uniqueID;

    address owner;

    address stackingTIP3Address;
    address rewardTIP3Address;

    address rewardTIP3Wallet;

    TvmCell userAccountCode;

    uint128 totalReward;
    uint128 totalStacked;
    uint64 startTime;
    uint64 finishTime;
    uint64 duration;

    constructor(address ownerAddress) public {
        owner = ownerAddress;
    }

    function setUserAccountCode(TvmCell userAccountCode_) external onlyOwner {
        userAccountCode = userAccountCode_;
    }

    function startFarming(
        address stackingTIP3Address_, 
        address rewardTIP3Address_, 
        address rewardTIP3Wallet_, 
        uint128 totalReward,
        uint64 startTime_,
        uint64 finishTime_
    ) external onlyOwner ifNoFarmIsActive {
        stackingTIP3Address = stackingTIP3Address_;
        rewardTIP3Address = rewardTIP3Address_;
        rewardTIP3Wallet = rewardTIP3Wallet_;
        totalReward = totalReward_;
        startTime = startTime_;
        finishTime = finishTime_;
        duration = finishTime - startTime;

        totalStacked = 0;
    }

    function tokensDepositedToFarm(address userAccountOwner, uint128 tokensDeposited, uint128 tokensAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner) {
        totalStacked += tokensDeposited;

        IUserAccount(msg.sender).updateRewardTime{
            value: 0.1 ton
        }(uint64(now));

        if (lastRewardTime != 0) {
            uint128 reward = _calculateReward(tokensAmount - tokensDeposited, lastRewardTime);
            ITONTokenWallet(rewardWallet).transfer();
        } else {

        }
    }

    function withdrawPendingReward(address userAccountOwner, uint128 tokenAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner) {
        uint128 reward = _calculateReward(tokenAmount, lastRewardTime);
        
        IUserAccount(msg.sender).updateRewardTime(uint64(now));

        ITONTokenWallet(rewardWallet).transfer();
    }

    function withdrawWithPending(address userAccountOwner, uint128 tokensToWithdraw, uint128 originalTokensAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner)  {
        uint128 reward = _calculateReward(originalTokensAmount, lastRewardTime);
        totalStacked -= tokensToWithdraw;

        IUserAccount(msg.sender).updateRewardTime(tokensToWithdraw == originalTokensAmount ? 0 : uint64(now));
    }

    function calculateReward(uint128 tokenAmount, uint64 lastRewardTime) external responsible returns(uint128) {
        return _calculateReward(tokenAmount, lastRewardTime);
    }

    function _calculateReward(uint128 tokenAmount, uint64 lastRewardTime) internal returns (uint128) {
        uint128 reward = tokenAmount * totalReward * (math.max(uint64(now), lastRewardTime) - lastRewardTime) / totalStacked / duration;
        return reward;
    }

    function deployUserAccount(address userAccountOwner) external {
        newContract = new UserAccount{
            stateInit: _buildUserAccount(userAccountOwner),
            code: userAccountCode,
            value: 1 ton
        }();
    }

    function _getUserAccountAddress(address userAccountOwner) internal returns(address) {
        return address.makeAddrStd(0, tvm.hash(_buildUserAccount(userAccountOwner)));
    }

    function getUserAccountAddress(address userAccountOwner) external responsilbe returns(address) {
        return _getUserAccoutnAddress(userAccountOwner);
    }

    function _buildUserAccount(address userAccountOwner) internal returns(TvmCell) {
        return tvm.buildStateInit({
            contr: UserAccount,
            varInit: {
                tonWallet: userAccountOwner
            },
            pubkey: 0,
            code: userAccountCode
        });
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyValidUserAccount(address userAccountOwner) {
        require(msg.sender == _getUserAccountAddress(userAccountOwner));
        _;
    }

    modifier ifNoActiveFarm() {
        require(finishTime < uint64(now));
        _;
    }
}