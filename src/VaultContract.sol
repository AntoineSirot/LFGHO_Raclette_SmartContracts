// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @title GHO Staking Vault
 * @dev This contract implements a staking vault for the GHO token.
 * @notice Allows users to participate in games and receive rewards based on their performance.
 * @author LFRaclette
 */

contract GHOStakingVault is ERC4626 {
    /**
     * @dev Structure to represent a game.
     */
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

    ERC20 public immutable GHO;
    Game[] public games;
    address public superAdmin;

    // Event declarations
    event GameCreated(uint gameId);
    event GameFinished(uint gameId);
    event GameStarted(uint gameId);
    event ParticipantEnteredGame(uint gameId, address participant);

    // Error declarations
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

    /**
     * @dev Modifier to restrict functions to the super admin only.
     */
    modifier onlySuperAdmin() {
        if (msg.sender != superAdmin) {
            revert NotSuperAdmin(msg.sender, superAdmin);
        }
        _;
    }

    /**
     * @dev Constructor for the GHOStakingVault contract.
     * @param _GHO Address of the GHO token contract.
     * @param name_ Name of the staking vault token.
     * @param symbol_ Symbol of the staking vault token.
     */
    constructor(
        ERC20 _GHO,
        string memory name_,
        string memory symbol_
    ) ERC4626(_GHO) ERC20(name_, symbol_) {
        superAdmin = msg.sender;
        GHO = _GHO;
    }

    /**
     * @notice Fetches details of a specific game.
     * @param gameId The ID of the game to retrieve.
     * @return Tuple containing game details.
     */
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

    /**
     * @notice Creates a new game with the specified parameters.
     * @dev Emits a GameCreated event on successful creation.
     * @param gameName Name of the game played.
     * @param totalPrice Total prize pool of the game.
     * @param repartition Array representing the prize distribution.
     */
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

    /**
     * @notice Allows a user to enter an existing game.
     * @dev Checks for game validity and participant's eligibility.
     * @param gameId The ID of the game to enter.
     */
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

    /**
     * @notice Distributes the rewards of a game to the participants based on their ranking.
     * @dev In reality, it sould use the superAdmin modifier so only the backend could distribute the rewards results. Ensures the game is started and not finished.
     * @param gameId The ID of the game for which to distribute rewards.
     * @param ranking Array of addresses representing the participants in their finishing order.
     */
    function distributeRewards(uint gameId, address[] memory ranking) public {
        Game memory currentGame = games[gameId];
        if (!currentGame.started) {
            revert NotStartedGame(gameId);
        }
        if (currentGame.finished) {
            revert IsOverGame(gameId);
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
