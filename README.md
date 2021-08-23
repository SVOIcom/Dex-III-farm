# Dex-III-farm

#Frontend

## Деплой аккаунта (требуется для выполнения операций)

FarmContract -> createUserAccount(address userAccountOnwer)
userAccountOwner - кошелёк с тонами пользователя
Стоимость ~ 1-1.5 ton

## Получение адреса пользователя

FarmContract -> getUserAccountAddress(address userAccountOwner)

## Получение информации о всех фармилках пользователя

UserAccount -> getAllUserFarmInfo() - получение информации о всех фармилках, ключами будут являться те фармилки, в которые пользователь уже вступил
UserAccount -> getUserFarmInfo(address farm) - получение информации о конкретной фармилке

## Добавление фармилки в аккаунт пользователя

UserAccount -> enterFarm(address farm, address stackingTIP3UserWallet, address rewardTIP3Wallet) \
farm - адрес фармилки, которую необходимо добавить \
stackingTIP3UserWallet - адрес кошелька пользователя, который будет использоваться для стейка токенов в данную фармилку \
rewardTIP3Wallet - адрес кошелька пользоватея, куда будет выплачиваться вознаграждение \
стоимость ~1 ton

## Операции с токенами

### Ввод токенов
UserAccount -> через создание payload и отправку TIP-3 токенов ([см тут](./scripts/farm/scripts/deposit-tokens-to-farm.js)) \
стоимость ~0.5 ton

### Вывод только награды
UserAccount -> withdrawPendingReward(address farm) -> вывод награды из фармилки с адресом farm \
стоимость ~0.5 ton

### Вывод части токенов + награды
UserAccount -> withdrawPartWithPendingReward(address farm, uint128 tokensToWithdraw) -> вывод tokensToWithdraw токенов
стоимость ~0.5-1 ton

### Вывод всех токенов + награды
UserAccount -> withdrawAllWithPendingReward(address farm) -> вывод всех токенов пользователя из фармилки
стоимость ~0.5-1 ton

### Обновление текущей награды
UserAccount -> updateReward(address farm) -> обновление информации о награде пользователя (через запрос с аккаунта, для runlocal см ниже)
стоимость ~0.5 ton

### Расчёт награды пользователя (через runLocal)
FarmContract -> calculateReward(uint128 tokenAmount, uint128 pendingReward, uint256 rewardPerTokenSum) \
Парметры получаются при помощи UserAccount -> getUserFarmInfo(address farm) \
tokenAmount -> result.stackedTokens \
pendignReward -> result.pendingReward \
rewardPerTokenSum -> result.rewardPerTokenSum \
Возвращается текущая награда пользователя (требуется время от времени обновлять состояние загруженного boc FarmContract)

## Про стоимость
Большая часть (~90%) вернётся пользователю, иногда - из разных источников + требуется время от времени пополнять баланс UserAccount,\
особенно при частых выводах, рекомендуемый баланс - 0.5 ton (проблема возникает именно при выводе, так как требуется вывести токены сразу из двух мест) \

## Скрипты
Операции в скриптах описаны [здесь](./scripts/farm/scripts)
