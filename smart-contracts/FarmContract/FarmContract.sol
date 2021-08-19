pragma ton-solidity >= 0.43.0;

import './interfaces/IFarmContract.sol';

import '../UserAccount/interfaces/IUserAccount.sol';

import '../TIP3Deployer/interfaces/ITIP3Deployer.sol';


contract FarmContract is ITokensReceivedCallback {

    uint256 static uniqueID;

    address owner;

    FarmInfo farmInfo;

    TvmCell userAccountCode;
    TvmCell empty;

    constructor(address ownerAddress) public {
        tvm.accept();
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
        farmInfo.stackingTIP3Root = stackingTIP3Address_;
        farmInfo.rewardTIP3Root = rewardTIP3Address_;
        farmInfo.rewardTIP3Wallet = rewardTIP3Wallet_;

        farmInfo.totalReward = totalReward;
        farmInfo.totalPayout = 0;
        farmInfo.totalStacked = 0;

        farmInfo.startTime = startTime_;
        farmInfo.finishTime = finishTime_;
        farmInfo.duration = finishTime_ - startTime_;
    }

    function tokensDepositedToFarm(address userAccountOwner, uint128 tokensDeposited, uint128 tokensAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner) {
        farmInfo.totalStacked += tokensDeposited;

        payoutReward(
            tokensAmount,
            lastRewardTime,
            rewardWallet,
            userAccountOwner,
            msg.sender,
            uint64(now)
        );
    }

    function withdrawPendingReward(address userAccountOwner, uint128 tokenAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner) {
        payoutReward(
            tokenAmount,
            lastRewardTime,
            rewardWallet,
            userAccountOwner,
            msg.sender,
            uint64(now)
        );
    }

    function withdrawWithPending(address userAccountOwner, uint128 tokensToWithdraw, uint128 originalTokensAmount, uint64 lastRewardTime, address rewardWallet) external onlyValidUserAccount(userAccountOwner)  {
        farmInfo.totalStacked -= tokensToWithdraw;

        payoutReward(
            originalTokensAmount, 
            lastRewardTime, 
            rewardWallet, 
            userAccountOwner, 
            msg.sender,
            tokensToWithdraw == originalTokensAmount ? 0 : uint64(now)
        );
    }

    function payoutReward(
        uint128 rewardTokens, 
        uint64 lastRewardTime, 
        address rewardWallet,
        address userAccountOwner,
        address userAccount,
        uint64 updatedRewardTime
    ) internal {
        IUserAccount(userAccount).updateRewardTime{
            value: 0.1 ton
        }(udpatedRewardTime);

        if (lastRewardTime != 0) {
            uint128 reward = _calculateReward(rewardTokens, lastRewardTime);
            farmInfo.totalPayout += reward;
            ITONTokenWallet(farmInfo.rewardTIP3Wallet).transfer{
                flags: 64
            }(
                rewardWallet,
                reward,
                0,
                userAccountOwner,
                true,
                empty
            )
        } else {
            address(userAccountOwner).transfer({flags: 64});
        }
    }

    function calculateReward(uint128 tokenAmount, uint64 lastRewardTime) external responsible returns(uint128) {
        return _calculateReward(tokenAmount, lastRewardTime);
    }

    function _calculateReward(uint128 tokenAmount, uint64 lastRewardTime) internal returns (uint128) {
        uint128 reward = 
            tokenAmount *                   // User's token amount
            farmInfo.totalReward *          // Tokens for reward
            (math.max(farmInfo.finishTime, uint64(now)) - lastRewardTime) / // dt
            farmInfo.totalStacked /         // Total tokens
            farmInfo.duration;              // To calculate distributed tokens per block
        return reward;
    }

    function calculateAPY(uint128 tokenAmount) external returns (uint128) {
        return 
            tokenAmount *                           // Tokens provided
            farmInfo.totalReward *                  // Tokens for reward
            (farmInfo.finishTime - uint64(now)) /   // Farm time left
            farmInfo.totalStacked /                 // Total stacked
            farmInfo.duration;                      // Farm time duration
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

    modifier activeFarm() {
        require(uint64(now) >= farmInfo.startTime);
        _;
    }

    modifier ifNoActiveFarm() {
        require(finishTime < uint64(now));
        _;
    }
}