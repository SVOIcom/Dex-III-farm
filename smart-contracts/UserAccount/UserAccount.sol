pragma ton-solidity >= 0.43.0;

import './interfaces/IUserAccount.sol';

import '../FarmContract/interfaces/IFarmContract.sol';

import '../utils/TIP3/interfaces/ITokensReceivedCallback.sol';
import '../utils/TIP3/interfaces/ITONTokenWallet.sol';

contract UserAccount is ITokensReceivedCallback {

    address static owner;

    mapping (address => UserFarmInfo) farmInfo;

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

        require(farmInfo.exists(farm));
        require(sender_wallet == farmInfo[farm].stackingTIP3);

        farmInfo[farm].tokensAmount = farmInfo[farm].tokensAmount + amount;

        IFarmContract(farm).tokensDepositedToFarm{
            flags: 64
        }(owner, tokensAmount, farmInfo[farm].tokens, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);    
    }

    function withdrawPendingReward(address farm) external onlyOwner {
        IFarmContract(farm).withdrawPendingReward(owner, farmInfo[farm].tokensAmount, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    }

    function withdrawPartWithPendingReward(address farm, uint128 tokensToWithdraw) external onlyOwner {
        farmInfo[farm].tokensAmount = farmInfo[farm].tokensAmount - tokensToWithdraw;
        
        ITONTokenWallet(farmInfo[farm].stackingTIP3).transfer{
            value: 0.15 ton
        }();

        IFarmContract(farm).withdrawWithPendingReward{
            flags: 64
        }(owner, tokensToWithdraw, farmInfo[farm].tokensAmount, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    };

    function withdrawAllWithPendingReward(address farm) external onlyOwner {
        require(msg.sender == owner);
        uint128 tokensToWithdraw = farmInfo[farm].tokensAmount;
        farmInfo[farm].tokensAmount = 0;

        ITONTokenWallet(farmInfo[farm].stackingTIP3).transfer{
            value: 0.15 ton
        }();

        IFarmContract(farm).withdrawAllWithPendingReward{
            flags: 64s
        }(owner, tokensToWithdraw, farmInfo[farm].lastRewardTime, farmInfo[farm].rewardTIP3);
    }

    function updateRewardTime(uint64 lastRewardTime) external onlyKnownFarm {
        farmInfo[msg.sender].lastRewardTime = lastRewardTime;
        address(owner).transfer({flags: 64});
    }

    function createPayload(address farm) external responsible onlyKnownFarm returns(TvmCell) {
        TvmBuilder builder;
        builder.store(farm);
        return builder.toCell();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    } 

    modifier onlyKnownFarm() {
        require(farmInfo.exists(msg.sender));
        _;
    }
}