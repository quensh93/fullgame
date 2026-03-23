# [OPUS FRONTEND TASK] React Tickets Module (User + Admin)

- Date: 2026-02-26
- Type: FEATURE
- Priority: P1
- Platform: Web (React)

## Prompt آماده کپی برای Opus

You are implementing the **Tickets module** in a React project for both:
1) User panel
2) Admin panel

Use this backend contract as source of truth. Do not invent new endpoints.

## 0) Critical API Notes

- User endpoints base: `/api/tickets`
- Admin endpoints base: `/api/admin/tickets`
- Old endpoints like `/api/support-tickets` are deprecated/not available.
- All requests require `Authorization: Bearer <token>`.
- `/api/admin/**` requires role `ADMIN`.
- Enum values are strict uppercase (`valueOf` on backend). Always send exact enum values from dropdowns, never free text.

---

## 1) Domain Model

### TicketStatus
- `OPEN`
- `IN_PROGRESS`
- `WAITING_FOR_USER`
- `RESOLVED`
- `CLOSED`

### TicketPriority
- `LOW`
- `NORMAL`
- `HIGH`
- `URGENT`

### SupportTicket (response fields used by frontend)
- `id: number`
- `subject: string`
- `status: TicketStatus`
- `priority: TicketPriority`
- `createdAt: string (ISO)`
- `updatedAt?: string`
- `closedAt?: string`
- `user?: { id, email, username, ... }` (present in admin APIs)

### TicketMessage (response fields used by frontend)
- `id: number`
- `body: string`
- `createdAt: string (ISO)`
- sender info in `sender`
- admin flag may be serialized as `adminReply` (and in WS event as `isAdminReply`)  
  -> normalize in frontend to one boolean field.

---

## 2) User Panel Requirements

### 2.1 List My Tickets
- Endpoint: `GET /api/tickets/my?page=0&size=20`
- Response: Spring `Page<SupportTicket>`
- UI:
  - Tickets list/table/cards
  - Columns: subject, status, priority, createdAt
  - Pagination controls (page, size)
  - Empty state + loading + retry

### 2.2 Create Ticket
- Endpoint: `POST /api/tickets`
- Payload:
```json
{
  "subject": "Cannot withdraw",
  "body": "I got an error",
  "priority": "NORMAL"
}
```
- Validation:
  - `subject` required
  - `body` required
  - `priority` optional; default to `NORMAL`
- Success: HTTP `201`, append or refresh list

### 2.3 Ticket Details + Conversation
- Endpoint: `GET /api/tickets/my/{id}`
- Response:
```json
{
  "ticket": { "...": "..." },
  "messages": [
    { "id": 1, "body": "...", "adminReply": false, "createdAt": "..." }
  ]
}
```
- UI:
  - Header with subject/status/priority/date
  - Chat-style thread in ascending time
  - Different bubble style for user vs admin

### 2.4 Reply to Ticket
- Endpoint: `POST /api/tickets/my/{id}/message`
- Payload:
```json
{ "body": "Any update?" }
```
- Success: HTTP `201`, append message
- Backend behavior:
  - if current status is `WAITING_FOR_USER` or `RESOLVED`, backend auto-changes status to `IN_PROGRESS`

### 2.5 Suggested UX Rules for User Panel
- Disable send button while request is pending.
- For `CLOSED`, hide/disable composer (even though backend currently does not hard-block message send).
- Show toast/snackbar on success/failure.

---

## 3) Admin Panel Requirements

### 3.1 List Tickets (with optional status filter)
- Endpoint:
  - `GET /api/admin/tickets?page=0&size=20`
  - `GET /api/admin/tickets?status=OPEN&page=0&size=20`
- UI:
  - Status filter tabs/dropdown
  - Table columns: id, user(email), subject, priority, status, createdAt, actions
  - Pagination controls

### 3.2 Ticket Details
- Endpoint: `GET /api/admin/tickets/{id}`
- Response:
```json
{
  "ticket": { "...": "..." },
  "messages": [ { "...": "..." } ]
}
```
- UI:
  - Drawer/modal with ticket meta
  - Chat thread
  - Reply form
  - Status changer

### 3.3 Admin Reply
- Endpoint: `POST /api/admin/tickets/{id}/reply`
- Payload:
```json
{ "body": "We are checking this issue." }
```
- Success: HTTP `201`
- Backend behavior:
  - status automatically set to `WAITING_FOR_USER`
  - sends real-time WS signal `TICKET_REPLY` to user
  - creates persistent notification for user

### 3.4 Update Ticket Status
- Endpoint: `PUT /api/admin/tickets/{id}/status`
- Payload:
```json
{ "status": "RESOLVED" }
```
- Success: HTTP `200`
- Backend behavior:
  - if status is `RESOLVED` or `CLOSED`, backend sets `closedAt`
  - sends WS signal `TICKET_STATUS_CHANGED` to user
  - creates persistent notification for user

---

## 4) WebSocket Integration (User-facing realtime)

### 4.1 `TICKET_REPLY`
Incoming shape:
```json
{
  "type": "TICKET_REPLY",
  "success": true,
  "data": {
    "ticketId": 12,
    "subject": "Cannot withdraw",
    "message": {
      "body": "Please try again now.",
      "isAdminReply": true
    }
  }
}
```

Frontend action:
- If current ticket is open in UI, append message immediately.
- Otherwise increment badge/unread marker and show toast.

### 4.2 `TICKET_STATUS_CHANGED`
Incoming shape:
```json
{
  "type": "TICKET_STATUS_CHANGED",
  "success": true,
  "data": {
    "ticketId": 12,
    "subject": "Cannot withdraw",
    "newStatus": "RESOLVED"
  }
}
```

Frontend action:
- Update ticket status in list/detail cache.
- Show toast/badge update.

### 4.3 Optional: `USER_NOTIFICATION`
- You may also refresh notification counter via this signal if app already has a notification center.

---

## 5) Error Handling Contract

- `401 Unauthorized`: token missing/expired -> redirect to login or refresh flow
- `403 Forbidden`: non-admin on admin endpoints -> show permission page
- `404 Not Found`: ticket not found or not owned by user -> show not-found state
- `400 Bad Request`: empty subject/body/status missing
- For invalid enum values backend may throw server error; frontend must prevent this by strict enum dropdowns.

---

## 6) UI/UX Design Rules

- No blocking full-page spinner after first load; use table/list skeletons.
- Keep chat scroll pinned to latest message on new send/reply.
- Color mapping:
  - Status: `OPEN` blue, `IN_PROGRESS` yellow, `WAITING_FOR_USER` orange, `RESOLVED` green, `CLOSED` gray
  - Priority: `URGENT` red, `HIGH` orange, `NORMAL` blue, `LOW` gray
- Mobile responsive:
  - list collapses to cards
  - detail panel full-screen on small devices

---

## 7) Suggested React Implementation

- API layer:
  - `tickets.api.ts`
  - `adminTickets.api.ts`
- Query/cache layer:
  - React Query keys:
    - `tickets.my.list`
    - `tickets.my.detail`
    - `tickets.admin.list`
    - `tickets.admin.detail`
- Pages:
  - User:
    - `UserTicketsPage`
    - `UserTicketDetailPage`
  - Admin:
    - `AdminTicketsPage`
    - `AdminTicketDrawer` (or modal)
- Shared components:
  - `TicketStatusBadge`
  - `TicketPriorityBadge`
  - `TicketMessageList`
  - `TicketReplyComposer`
  - `CreateTicketModal`

---

## 8) Acceptance Criteria

1. User can list, create, open detail, and reply to own tickets.
2. Admin can list (with status filter), open detail, reply, and change status.
3. Realtime updates for `TICKET_REPLY` and `TICKET_STATUS_CHANGED` are reflected in UI.
4. Enum-safe forms prevent invalid status/priority submissions.
5. Proper handling for loading/empty/error states and auth/permission failures.
6. Responsive behavior works on desktop + mobile.

---

## 9) QA Scenarios (Must pass)

1. Create ticket with `NORMAL` priority, verify appears in user list.
2. Admin opens same ticket, sends reply, user receives realtime update.
3. Admin sets status `RESOLVED`, user sees status update in list/detail.
4. User sends message after `RESOLVED`, status becomes `IN_PROGRESS` automatically.
5. Non-admin token on `/api/admin/tickets` receives forbidden handling in UI.
6. Invalid form submit (empty subject/body) blocked client-side.

Deliver code changes with concise notes per file and manual verification steps.

## Notes برای تیم

- این مستند مستقیم از قرارداد فعلی بک‌اند (`UserSupportTicketController` و `AdminSupportTicketController`) استخراج شده.
- برای فرانت React باید endpointهای جدید تیکت را استفاده کنید و endpointهای قدیمی `/api/support-tickets` را کامل کنار بگذارید.
