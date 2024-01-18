pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract GHOStakingVault is ERC4626 {
    struct Game {
        uint id;
        uint totalPrice;
        uint numberOfPlayer;
        uint[] repartition;
        address[] participants;
        bool started;
        bool finished;
    }

    ERC20 public immutable GHO;
    Game[] public games;
    address public superAdmin;

    event GameCreated(uint gameId);
    event GameFinished(uint gameId);
    event GameStarted(uint gameId);
    event ParticipantEnteredGame(uint gameId, address participant);

    error notParticipant(address user);
    error notEnoughFGHO(uint amountRequire);
    error IncorrectId(uint gameId);
    error notStartedGame(uint gameId);
    error inProgressGame(uint gameId);
    error isOverGame(uint gameId);
    error IncorrectRepartition();
    error notSuperAdmin(address caller, address superAdmin);
    error incorrectRanking(uint sendLength, uint wantedLength);

    modifier onlySuperAdmin() {
        if (msg.sender != superAdmin) {
            revert notSuperAdmin(msg.sender, superAdmin);
        }
        _;
    }

    constructor(
        ERC20 _GHO,
        string memory name_,
        string memory symbol_
    ) ERC4626(_GHO) ERC20(name_, symbol_) {
        superAdmin = msg.sender;
        GHO = _GHO;
    }

    function createGame(
        uint totalPrice,
        uint[] memory repartition,
        uint numberOfPlayer
    ) public {
        uint gameId = games.length;
        address[] memory emptyArray;
        uint totalPercentages = 0;
        if (repartition.length != numberOfPlayer) {
            revert IncorrectRepartition();
        }
        for (uint i = 0; i < repartition.length; i++) {
            if (repartition[i] < 0) {
                revert IncorrectRepartition();
            }
            totalPercentages += repartition[i];
        }
        if (totalPercentages != 100) {
            revert IncorrectRepartition();
        }
        games.push(
            Game(
                gameId,
                totalPrice,
                numberOfPlayer,
                repartition,
                emptyArray,
                false,
                false
            )
        );
        emit GameCreated(gameId);
    }

    function enterGame(uint gameId) public {
        if (gameId >= games.length) {
            revert IncorrectId(gameId);
        }

        Game memory currentGame = games[gameId];

        if (currentGame.started) {
            revert inProgressGame(gameId);
        }
        if (currentGame.finished) {
            revert isOverGame(gameId);
        }
        uint minimumAmount = (currentGame.totalPrice /
            currentGame.numberOfPlayer);
        if (!this.transferFrom(msg.sender, address(this), minimumAmount)) {
            revert notEnoughFGHO(minimumAmount);
        }
        games[gameId].participants.push(msg.sender);
        emit ParticipantEnteredGame(gameId, msg.sender);

        if (games[gameId].participants.length == currentGame.numberOfPlayer) {
            games[gameId].started = true;
            emit GameStarted(gameId);
        }
    }

    function distributeRewards(
        uint gameId,
        address[] memory ranking
    ) public onlySuperAdmin {
        Game memory currentGame = games[gameId];
        if (!currentGame.started) {
            revert notStartedGame(gameId);
        }
        if (currentGame.numberOfPlayer != ranking.length) {
            revert incorrectRanking(ranking.length, currentGame.numberOfPlayer);
        }
        for (uint i = 0; i < ranking.length; i++) {
            this.transfer(
                ranking[i],
                (currentGame.totalPrice * currentGame.repartition[i]) / 100
            );
        }
        games[gameId].finished = true;
        emit GameFinished(gameId);
    }
}
