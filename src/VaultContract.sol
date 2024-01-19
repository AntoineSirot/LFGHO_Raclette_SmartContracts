// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract GHOStakingVault is ERC4626 {
    ERC20 public immutable GHO;

    struct Game {
        uint id;
        string gameName;
        uint totalPrice;
        uint numberOfPlayer;
        uint[] repartition;
        address[] participants;
        bool started;
        bool finished;
    }

    Game[] public games;
    address public superAdmin;

    event GameCreated(uint gameId);
    event GameFinished(uint gameId);
    event GameStarted(uint gameId);
    event ParticipantEnteredGame(uint gameId, address participant);

    error NotEnoughFGHO(uint amountRequire);
    error IncorrectId(uint gameId);
    error NotStartedGame(uint gameId);
    error InProgressGame(uint gameId);
    error IsOverGame(uint gameId);
    error IncorrectRepartition();
    error NotSuperAdmin(address caller, address superAdmin);
    error NoApproval();
    error IncorrectRanking(uint sendLength, uint wantedLength);
    error AlreadyPlaying(address userAddress);

    modifier onlySuperAdmin() {
        if (msg.sender != superAdmin) {
            revert NotSuperAdmin(msg.sender, superAdmin);
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

    function getGame(
        uint gameId
    )
        public
        view
        returns (
            uint,
            string memory,
            uint,
            uint,
            uint[] memory,
            address[] memory,
            bool,
            bool
        )
    {
        Game memory currentGame = games[gameId];
        return (
            currentGame.id,
            currentGame.gameName,
            currentGame.totalPrice,
            currentGame.numberOfPlayer,
            currentGame.repartition,
            currentGame.participants,
            currentGame.started,
            currentGame.finished
        );
    }

    function createGame(
        string memory gameName,
        uint totalPrice,
        uint[] memory repartition
    ) public {
        uint gameId = games.length;
        address[] memory emptyArray;
        uint totalPercentages = 0;
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
                gameName,
                totalPrice,
                repartition.length,
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
            revert InProgressGame(gameId);
        }
        if (currentGame.finished) {
            revert IsOverGame(gameId);
        }
        for (uint i = 0; i < currentGame.participants.length; i++) {
            if (msg.sender == currentGame.participants[i]) {
                revert AlreadyPlaying(msg.sender);
            }
        }
        uint minimumAmount = (currentGame.totalPrice /
            currentGame.numberOfPlayer);
        if (!approve(address(this), minimumAmount)) {
            revert NoApproval();
        }
        if (!this.transferFrom(msg.sender, address(this), minimumAmount)) {
            revert NotEnoughFGHO(minimumAmount);
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
            revert NotStartedGame(gameId);
        }
        if (currentGame.numberOfPlayer != ranking.length) {
            revert IncorrectRanking(ranking.length, currentGame.numberOfPlayer);
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
