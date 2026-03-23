# WS v3 Payload Inventory

Date: 2026-02-20

Source: backend ws-v3 + `docs/opus_ws_v3_contract.json`

## Scope
- Endpoint: `/ws-v3`
- Protocol: `v3`
- Legacy `README_WEBSOCKET_V2.md` is non-authoritative.

## Envelope Fields
- Required outbound: `type`, `protocolVersion`, `traceId`
- Required gameplay outbound: `clientActionId`, `data.stateVersion`
- Canonical inbound metadata: `eventId`, `traceId`, `serverTime`, `protocolVersion`, `stateVersion`, `clientActionId`

## Request Payload By Type (39)
| Type | Required | Optional | Success Signals |
|---|---|---|---|
| `ACCEPT_FRIEND_REQUEST` | `senderId` | `-` | `FRIEND_REQUEST_ACCEPTED, FRIENDS_LIST` |
| `ACCEPT_GAME_INVITATION` | `invitationId` | `-` | `GAME_INVITATION_ACCEPTED, GAME_INVITATION_RESPONSE` |
| `AUTH` | `token, protocolVersion, appVersion, capabilities` | `deviceId` | `AUTH_SUCCESS` |
| `BLOCK_USER` | `targetUserId` | `-` | `USER_BLOCKED` |
| `CANCEL_GAME_INVITATION` | `invitationId` | `-` | `GAME_INVITATION_CANCELLED, GAME_INVITATION_RESPONSE` |
| `CANCEL_ROOM` | `roomId` | `-` | `CANCEL_ROOM_SUCCESS` |
| `CLIENT_TELEMETRY` | `data` | `data.connect_latency, data.ack_latency, data.reconnect_attempts, data.resync_count, data.action_retry_count, data.action_timeout_count, data.pending_action_count, data.appVersion` | `CLIENT_TELEMETRY_ACK` |
| `CREATE_ROOM` | `gameType, roomType, entryFee` | `maxPlayers, gameScore, diceWinnerType` | `ROOM_CREATED` |
| `GAME_ACTION` | `action, roomId, data` | `clientActionId, matchId, data.stateVersion` | `ACTION_ACK, GAME_ACTION` |
| `GET_FRIENDS` | `-` | `-` | `FRIENDS_LIST` |
| `GET_FRIEND_REQUESTS` | `-` | `-` | `FRIEND_REQUESTS` |
| `GET_GAME_BEST_USER` | `-` | `userId` | `GAME_BEST_USER` |
| `GET_GAME_HISTORY_USER` | `-` | `limit, userId` | `GAME_HISTORY_USER` |
| `GET_GAME_RECENT_USER` | `-` | `limit, userId` | `GAME_RECENT_USER` |
| `GET_GAME_STATE` | `gameStateId` | `-` | `GAME_STATE` |
| `GET_GAME_STATE_BY_ROOM` | `roomId` | `-` | `STATE_SNAPSHOT` |
| `GET_GAME_STATS_USER` | `-` | `userId` | `GAME_STATS_USER` |
| `GET_PROFILE` | `-` | `-` | `USER_PROFILE` |
| `GET_RECEIVED_INVITATIONS` | `-` | `-` | `RECEIVED_INVITATIONS` |
| `GET_ROOM` | `roomId` | `-` | `ROOM_DETAILS` |
| `GET_ROOM_LIST` | `gameType` | `-` | `room_list` |
| `GET_SENT_INVITATIONS` | `-` | `-` | `SENT_INVITATIONS` |
| `GET_TRANSACTIONS` | `-` | `-` | `TRANSACTIONS_LIST` |
| `GET_WITHDRAW_REQUESTS` | `-` | `-` | `WITHDRAW_REQUESTS` |
| `GET_XP_HISTORY` | `-` | `-` | `XP_HISTORY` |
| `HEARTBEAT` | `-` | `-` | `-` |
| `JOIN_ROOM` | `roomId` | `-` | `JOIN_ROOM_SUCCESS` |
| `LEAVE_ROOM` | `roomId` | `data.roomId` | `LEAVE_ROOM_SUCCESS` |
| `REJECT_FRIEND_REQUEST` | `senderId` | `-` | `FRIEND_REQUEST_REJECTED` |
| `REJECT_GAME_INVITATION` | `invitationId` | `-` | `GAME_INVITATION_REJECTED, GAME_INVITATION_RESPONSE` |
| `REMOVE_FRIEND` | `friendId` | `-` | `FRIEND_REMOVED, FRIENDS_LIST` |
| `REQUEST_WITHDRAW` | `amount` | `-` | `WITHDRAW_REQUESTED` |
| `SEARCH_USERS` | `query` | `-` | `SEARCH_RESULTS` |
| `SEND_FRIEND_REQUEST` | `targetUserId` | `-` | `FRIEND_REQUEST_SENT` |
| `SEND_GAME_INVITATION` | `receiverId, gameType, entryFee, maxPlayers` | `-` | `GAME_INVITATION_SENT` |
| `SUBSCRIBE_ROOMS` | `gameType` | `-` | `SUBSCRIBE_ROOMS_SUCCESS, room_list` |
| `UNBLOCK_USER` | `targetUserId` | `-` | `USER_UNBLOCKED` |
| `UNSUBSCRIBE_ROOMS` | `gameType` | `-` | `UNSUBSCRIBE_ROOMS_SUCCESS` |
| `UPDATE_PROFILE` | `-` | `firstName, lastName, phone, bio, gender, country, avatarUrl` | `PROFILE_UPDATED` |

## GAME_ACTION Input By Action (32)
| Action | Required Data | Optional Data |
|---|---|---|
| `BJ_HIT` | `gameStateId, playerId` | `-` |
| `BJ_STAND` | `gameStateId, playerId` | `-` |
| `BJ_TURN_TIMEOUT` | `gameStateId` | `-` |
| `CASINO_WAR_PICK_CARD` | `cardIndex_or_cardSlotIndex` | `playerId` |
| `CE_CHOOSE_SUIT` | `roomId, suit` | `-` |
| `CE_DRAW_CARD` | `roomId` | `-` |
| `CE_FORFEIT` | `roomId` | `-` |
| `CE_GIVE_CARD` | `roomId, targetPlayerId` | `-` |
| `CE_PLAY_CARD` | `roomId, card` | `-` |
| `CE_TURN_TIMEOUT` | `roomId` | `-` |
| `CHAHAR_BARG_PLAY_CARD` | `gameStateId, playerId, card` | `-` |
| `CHAHAR_BARG_SELECT_CAPTURE` | `gameStateId, playerId, optionIndex` | `-` |
| `CHOOSE_TRUMP` | `gameStateId, trumpSuit` | `trumpMode` |
| `DICE_ROLL` | `gameStateId, playerId` | `-` |
| `DICE_ROUND_TIMEOUT` | `gameStateId` | `-` |
| `HEARTS_PASSING_TIMER_ENDED` | `-` | `-` |
| `HEARTS_PLAY_CARD` | `playerId, card.suit, card.rank` | `-` |
| `PASS_CARDS_SELECTION` | `playerId, cards` | `-` |
| `PLAY_CARD` | `gameStateId, card` | `-` |
| `RIM_ADD_TO_MELD` | `meldId, card, side` | `roomId, playerId` |
| `RIM_DISCARD_CARD` | `card` | `roomId, playerId` |
| `RIM_DRAW_CARD` | `source` | `roomId, playerId` |
| `RIM_LAY_MELD` | `cards` | `roomId, playerId` |
| `RPS_CHOICE` | `gameStateId, playerId, choice` | `-` |
| `RPS_ROUND_TIMEOUT` | `gameStateId` | `-` |
| `SHELEM_EXCHANGE_CARDS` | `gameStateId, cardsToReturn` | `-` |
| `SHELEM_PASS_BID` | `gameStateId` | `-` |
| `SHELEM_PLAY_CARD` | `gameStateId, card` | `-` |
| `SHELEM_SUBMIT_BID` | `gameStateId, bidAmount` | `-` |
| `SHELEM_TURN_TIMEOUT` | `gameStateId` | `-` |
| `START_HEARTS_GAME` | `-` | `-` |
| `TURN_TIMEOUT` | `gameStateId` | `-` |

## Signal Payload By Type (48)
| Signal Type | Required | Optional |
|---|---|---|
| `ACTION_ACK` | `type, success, data.action, data.roomId, data.clientActionId` | `data.accepted, data.duplicate, data.stateVersion` |
| `AUTH_SUCCESS` | `type, success, data.user, data.protocolVersion, data.sessionId, data.sessionVersion, data.capabilities, data.serverConfig` | `-` |
| `CANCEL_ROOM_SUCCESS` | `type, success, data.roomId` | `-` |
| `CLIENT_TELEMETRY_ACK` | `type, success, data.accepted` | `-` |
| `ERROR` | `type, success, action, errorCode, error, eventId, traceId, serverTime, protocolVersion` | `roomId, matchId, clientActionId, stateVersion` |
| `FRIENDS_LIST` | `type, data` | `success` |
| `FRIEND_REMOVED` | `type, success, data.friendId` | `-` |
| `FRIEND_REQUESTS` | `type, data` | `success` |
| `FRIEND_REQUEST_ACCEPTED` | `type, success, data.senderId` | `-` |
| `FRIEND_REQUEST_REJECTED` | `type, success, data.senderId` | `-` |
| `FRIEND_REQUEST_SENT` | `type, success, data.targetUserId` | `-` |
| `GAME_ACTION` | `type, action, roomId, data` | `stateVersion` |
| `GAME_BEST_USER` | `type, success, data.sessions` | `-` |
| `GAME_HISTORY_USER` | `type, success, data.sessions` | `-` |
| `GAME_INVITATION_ACCEPTED` | `type, success, data.invitationId` | `-` |
| `GAME_INVITATION_CANCELLED` | `type, success, data.invitationId` | `-` |
| `GAME_INVITATION_REJECTED` | `type, success, data.invitationId` | `-` |
| `GAME_INVITATION_RESPONSE` | `type, data` | `-` |
| `GAME_INVITATION_SENT` | `type, data` | `success` |
| `GAME_RECENT_USER` | `type, success, data.sessions` | `-` |
| `GAME_STARTED` | `type, roomId, gameType` | `-` |
| `GAME_STATE` | `type, success, data` | `stateVersion` |
| `GAME_STATS_USER` | `type, success, data` | `-` |
| `JOIN_ROOM_SUCCESS` | `type, success, data.roomId` | `-` |
| `LEAVE_ROOM_SUCCESS` | `type, success, data.roomId` | `-` |
| `PROFILE_UPDATED` | `type, success` | `data` |
| `RECEIVED_INVITATIONS` | `type, success, data` | `-` |
| `ROOM_CREATED` | `type, success, data` | `-` |
| `ROOM_DETAILS` | `type, success, data` | `-` |
| `SEARCH_RESULTS` | `type, success, data` | `-` |
| `SENT_INVITATIONS` | `type, success, data` | `-` |
| `STATE_SNAPSHOT` | `type, success, roomId, data` | `stateVersion` |
| `SUBSCRIBE_ROOMS_SUCCESS` | `type, success, data.gameType` | `-` |
| `TRANSACTIONS_LIST` | `type, success, data` | `-` |
| `UNSUBSCRIBE_ROOMS_SUCCESS` | `type, success, data.gameType` | `-` |
| `USER_BLOCKED` | `type, success, data.targetUserId` | `-` |
| `USER_PROFILE` | `type, success, data` | `-` |
| `USER_STATUS` | `type, userId, status` | `data` |
| `USER_UNBLOCKED` | `type, success, data.targetUserId` | `-` |
| `WITHDRAW_REQUESTED` | `type, success, data.amount` | `-` |
| `WITHDRAW_REQUESTS` | `type, success, data` | `-` |
| `XP_HISTORY` | `type, success, data` | `-` |
| `ownership_transferred` | `type, roomId, gameType, newOwnerId, newOwnerUsername` | `data` |
| `room_cancelled` | `type, roomId` | `data, gameType` |
| `room_created` | `type, data` | `gameType` |
| `room_list` | `type, data.rooms` | `success, gameType` |
| `room_removed` | `type, roomId` | `gameType` |
| `room_update` | `type, data, roomId` | `gameType` |

## GAME_ACTION Event Payload By Action (54)
| Action | Observed Data Keys |
|---|---|
| `BID_PASSED` | `playerId` |
| `BID_SUBMITTED` | `bidAmount, playerId` |
| `BID_WINNER` | `hakemPlayerId, middleCards, winningBid` |
| `BJ_CARD_DRAWN` | `currentPlayerId, currentRound, drawnCard, gameStateId, nextTurnPlayerId, playerId, players, roomId, scores, targetScore, viewerPlayerId` |
| `BJ_GAME_FINISHED` | `coinRewards, finalScores, gameId, leavingPlayer, reason, targetScore, winnerId, winnerUsername, xpRewards` |
| `BJ_PLAYER_BUSTED` | `currentPlayerId, currentRound, drawnCard, gameStateId, nextTurnPlayerId, playerId, players, reason, roomId, roundEnded, scores, targetScore, viewerPlayerId, winnerId, winnerUsername` |
| `BJ_PLAYER_STOOD` | `autoStand, currentPlayerId, currentRound, gameStateId, nextTurnPlayerId, playerId, players, roomId, scores, targetScore, viewerPlayerId` |
| `BJ_ROUND_RESULT` | `currentPlayerId, currentRound, gameStateId, handValues, isTie, players, roomId, scores, targetScore, viewerPlayerId, winnerId` |
| `BJ_ROUND_STARTED` | `currentPlayerId, currentRound, gameStateId, players, roomId, scores, targetScore, viewerPlayerId` |
| `CARD_PLAYED` | `currentTurnPlayerId, gameStateId, heartsBroken, playedCard, playerId, roomId` |
| `CASINO_WAR_CARD_PICKED` | `cardIndex, currentRound, gameStateId, isAutoPick, nextTurnPlayerId, pickedCount, playerId, roomId, totalPlayers, turnTimeoutSeconds` |
| `CASINO_WAR_GAME_FINISHED` | `coinRewards, finalScores, forfeitedPlayerIds, gameId, leavingPlayer, playerScores, reason, winnerId, winnerUsername, xpRewards` |
| `CASINO_WAR_PLAYER_FORFEITED` | `activePlayerIds, gameStateId, playerId, playerScores, playerUsername, roomId, scores` |
| `CASINO_WAR_REVEAL_COUNTDOWN` | `gameStateId, revealAtEpochMs, roomId, seconds` |
| `CASINO_WAR_ROUND_RESULT` | `currentRound, gameStateId, picks, playerScores, revealedCards, roomId, scores, targetScore, winnerId, winnerUsername, winningRank` |
| `CASINO_WAR_ROUND_STARTED` | `activePlayerIds, availableCardIndices, cardsCount, currentRound, currentTurnPlayerId, gameStateId, playerScores, revealDelaySeconds, roomId, scores, starterPlayerId, targetScore, turnOrder, turnTimeoutSeconds` |
| `CE_CARD_DRAWN` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CE_CARD_GIVEN` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CE_CARD_PLAYED` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CE_GAME_FINISHED` | `gameId, players, roomId, winnerCoins, winnerId` |
| `CE_GAME_STARTED` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CE_PLAYER_LEFT` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CE_PLAY_ERROR` | `error, message` |
| `CE_SUIT_CHANGED` | `currentPlayerId, currentRank, currentSuit, deckRemaining, direction, gameId, hasDrawnThisTurn, lastPlayedSpecial, pendingDrawCount, players, roomId, topCard, topCardRank, topCardSuit, waitingForGiveCard, waitingForSuitChoice` |
| `CHAHAR_BARG_CAPTURE_OPTIONS` | `(dynamic/engine-specific)` |
| `CHAHAR_BARG_GAME_FINISHED` | `coinRewards, finalScores, gameId, leavingPlayer, reason, roomId, winnerId, winnerUsername, xpRewards` |
| `CHAHAR_BARG_GAME_STARTED` | `capturedCardsCount, cumulativePointsByPlayer, currentPlayerId, currentPlayerIndex, gameStateId, handNumber, isFinalDeal, pendingCapturePlayerId, players, roomId, surByPlayer, tableCards, targetScore, turnTimeoutSeconds, waitingForCaptureSelection` |
| `CHAHAR_BARG_HAND_FINISHED` | `capturedCardsCount, cumulativePoints, cumulativePointsByUsername, gameStateId, handNumber, handPoints, handPointsByPlayer, roomId, surByPlayer, targetScore` |
| `CHAHAR_BARG_STATE_UPDATED` | `capturedCardsCount, cumulativePointsByPlayer, currentPlayerId, currentPlayerIndex, gameStateId, handNumber, isFinalDeal, pendingCapturePlayerId, players, roomId, surByPlayer, tableCards, targetScore, turnTimeoutSeconds, waitingForCaptureSelection` |
| `DICE_GAME_FINISHED` | `coinRewards, finalScores, finalScoresByUserId, gameId, leavingPlayer, reason, winnerId, winnerType, winnerUsername, xpRewards` |
| `DICE_ROLL_MADE` | `currentRound, gameStateId, playerId, roll, rolledPlayers, roomId, totalPlayers` |
| `DICE_ROUND_RESULT` | `currentRound, gameStateId, isTie, rolls, roomId, scores, scoresByUserId, winnerId, winnerType, winningRoll` |
| `DICE_ROUND_STARTED` | `currentRound, gameStateId, phase, roomId, scores, scoresByUserId, targetScore, winnerType` |
| `DICE_ROUND_TIMEOUT` | `gameStateId, rolls, roomId` |
| `GAME_FINISHED` | `coinRewards, finalScores, gameRoom, gameState, gameStateId, phase, players, roomId, teamAScore, teamBScore, winnerId, xpRewards` |
| `GAME_STATE_UPDATED` | `bidWinnerId, currentBid, currentBidderId, currentPlayerId, currentRound, currentTrick, currentTurnPlayerId, deck, gameId, gameStateId, hakemPlayerId, heartsBroken, leadSuit, middleCards, passedPlayerIds, passingDirection, phase, playedCards, playedCardsWithSeats, players, roomId, scores, teamARoundWins, teamAScore, teamATrickScore, teamBRoundWins, teamBScore, teamBTrickScore, trumpMode, trumpSuit, winningBid` |
| `HAND_WON` | `playedCards, teamAScore, teamATrickScore, teamBScore, teamBTrickScore, teamId, trickPoints, winnerId, winnerUsername, winningCard` |
| `HEARTS_PLAYING_STARTED` | `currentRound, currentTrick, currentTurnPlayerId, gameStateId, heartsBroken, phase, playedCards, playedCardsWithSeats, players, roomId, scores` |
| `HEARTS_ROUND_STARTED` | `currentRound, gameStateId, passingDirection, phase, roomId, scores` |
| `HEARTS_TRICK_FINISHED` | `currentTrick, gameStateId, roomId, roundScores, totalScores, trickScore, winnerPlayerId` |
| `NEW_ROUND_STARTED` | `currentRound, currentTurnPlayerId, gameId, hakemPlayerId, leadSuit, phase, playedCards, playedCardsWithSeats, players, scores, teamARoundWins, teamAScore, teamBRoundWins, teamBScore, trumpSuit` |
| `RIM_ERROR` | `error` |
| `RIM_GAME_FINISHED` | `coinRewards, finalScores, gameId, leavingPlayer, reason, roomId, winnerId, winnerUsername, xpRewards` |
| `RIM_GAME_STARTED` | `currentPlayerId, discardTopCard, gameStateId, handNumber, myHandCards, players, roomId, scores, stockCount, tableMelds, targetScore, turnPhase` |
| `RIM_HAND_FINISHED` | `gameStateId, handDeadwood, handNumber, handPoints, reason, roomId, scores, scoresByUsername, winnerId, winnerUsername` |
| `RIM_STATE_UPDATED` | `currentPlayerId, discardTopCard, gameStateId, handNumber, myHandCards, players, roomId, scores, stockCount, tableMelds, targetScore, turnPhase` |
| `ROUND_ENDED` | `hakemPointsAdded, hakemTeamId, hakemTeamScore, hakemWon, isShelemBid, otherPointsAdded, otherTeamScore, roundNumber, teamAPointsAdded, teamAScore, teamBPointsAdded, teamBScore, totalTeamAWins, totalTeamBWins, winningBid` |
| `RPS_CHOICE_MADE` | `allChoicesMade, choice, gameId, playerId` |
| `RPS_GAME_FINISHED` | `coinRewards, finalScores, gameId, leavingPlayer, reason, winnerId, winnerUsername, xpRewards` |
| `RPS_ROUND_RESULT` | `choices, currentRound, gameStateId, isTie, roomId, scores, winnerId` |
| `RPS_ROUND_STARTED` | `currentRound, gameStateId, isTieReplay, phase, roomId, scores` |
| `RPS_ROUND_TIMEOUT` | `choices, gameStateId, roomId` |
| `TRUMP_SET` | `trumpSuit` |
| `TURN_TIMER_STARTED` | `gameStateId, timeoutSeconds` |

## Error Policy
| Code | Mandatory Client Behavior |
|---|---|
| `AUTH_REQUIRED` | clear restricted flow and authenticate |
| `AUTH_EXPIRED` | clear auth state, disconnect, force login |
| `TOKEN_REVOKED` | clear auth state, disconnect, force login |
| `INVALID_TOKEN` | clear auth state and login again |
| `ACTION_REJECTED` | surface error, drop pending action if correlated |
| `STATE_RESYNC_REQUIRED` | send GET_GAME_STATE_BY_ROOM and replace local state |
| `APP_VERSION_UNSUPPORTED` | stop realtime and force update UX |
| `RATE_LIMITED` | backoff and retry later |

## Normalization Notes
- `GAME_INVITATION_SENT` can arrive as direct response (`success=true`) or async push (often without `success`).
- `room_list`, `room_created`, `room_update`, `room_cancelled`, `room_removed` are lowercase stream types.
- `STATE_SNAPSHOT` should feed gameplay resync and can be routed as `GAME_STATE` alias for consumers.
