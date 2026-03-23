# P04 - Friends + Invitations (Paste to Opus)

```md
Phase 04 only: wire social flows (friends + game invitations).

Friends requests/signals:
- `GET_FRIENDS` -> `FRIENDS_LIST`
- `GET_FRIEND_REQUESTS` -> `FRIEND_REQUESTS`
- `SEND_FRIEND_REQUEST` -> `FRIEND_REQUEST_SENT`
- `ACCEPT_FRIEND_REQUEST` -> `FRIEND_REQUEST_ACCEPTED`
- `REJECT_FRIEND_REQUEST` -> `FRIEND_REQUEST_REJECTED`
- `REMOVE_FRIEND` -> `FRIEND_REMOVED`
- `BLOCK_USER` -> `USER_BLOCKED`
- `UNBLOCK_USER` -> `USER_UNBLOCKED`
- `SEARCH_USERS` -> `SEARCH_RESULTS`

Invitation requests/signals:
- `SEND_GAME_INVITATION` -> `GAME_INVITATION_SENT`
- `ACCEPT_GAME_INVITATION` -> `GAME_INVITATION_ACCEPTED`
- `REJECT_GAME_INVITATION` -> `GAME_INVITATION_REJECTED`
- `CANCEL_GAME_INVITATION` -> `GAME_INVITATION_CANCELLED`
- `GET_RECEIVED_INVITATIONS` -> `RECEIVED_INVITATIONS`
- `GET_SENT_INVITATIONS` -> `SENT_INVITATIONS`
- async: `GAME_INVITATION_RESPONSE`, `GAME_INVITATION_SENT`

Important compatibility rule:
- `GAME_INVITATION_SENT` may appear in two shapes:
  1) direct success response (`success=true`)
  2) async push payload (may omit `success`)
- parse by `type` and payload keys, not by `success` flag alone.

Done criteria:
- social pages are fully socket-driven for list/updates/actions
- both invitation signal shapes are handled safely

Output format:
1. changed files
2. mapping (action -> sender -> UI update target)
3. any unresolved edge cases
```
