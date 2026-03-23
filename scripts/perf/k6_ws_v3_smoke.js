import ws from 'k6/ws';
import { check } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const actionLatencyMs = new Trend('action_latency_ms');
const actionRejected = new Counter('action_rejected_count');
const authFailed = new Counter('auth_failed_count');
const sentActions = new Counter('actions_sent_count');

const wsUrl = __ENV.WS_URL || 'ws://localhost:8080/ws-v3';
const token = __ENV.WS_TOKEN || '';
const roomId = Number(__ENV.ROOM_ID || 1);
const actionName = __ENV.GAME_ACTION || 'PING';
const actionIntervalMs = Number(__ENV.ACTION_INTERVAL_MS || 800);
const maxActionsPerConnection = Number(__ENV.MAX_ACTIONS_PER_CONN || 20);
const initialStateVersion = Number(__ENV.STATE_VERSION || 0);

export const options = {
  vus: Number(__ENV.K6_VUS || 25),
  duration: __ENV.K6_DURATION || '30s',
  thresholds: {
    action_latency_ms: ['p(95)<150', 'p(99)<250'],
    checks: ['rate>0.99'],
  },
};

function buildEnvelope(type, payload) {
  return JSON.stringify({
    type,
    protocolVersion: 'v3',
    traceId: `k6-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    ...payload,
  });
}

export default function () {
  const pendingActions = {};
  const response = ws.connect(wsUrl, { tags: { scenario: 'ws-v3-smoke' } }, function (socket) {
    let actionsSent = 0;

    socket.on('open', function () {
      if (!token) {
        authFailed.add(1);
        socket.close();
        return;
      }

      socket.send(
        buildEnvelope('AUTH', {
          token,
          appVersion: __ENV.APP_VERSION || '3.0.0',
          capabilities: ['STATE_RESYNC', 'ACTION_ACK'],
          deviceId: __ENV.DEVICE_ID || 'k6-smoke-device',
        }),
      );
    });

    socket.on('message', function (raw) {
      let msg;
      try {
        msg = JSON.parse(raw);
      } catch (_) {
        return;
      }

      if (msg.type === 'AUTH_FAILED') {
        authFailed.add(1);
        socket.close();
        return;
      }

      if (msg.type === 'AUTH_SUCCESS') {
        socket.setInterval(function () {
          if (actionsSent >= maxActionsPerConnection) {
            socket.close();
            return;
          }

          const clientActionId = `k6-${__VU}-${Date.now()}-${actionsSent}`;
          pendingActions[clientActionId] = Date.now();
          sentActions.add(1);
          actionsSent += 1;

          socket.send(
            buildEnvelope('GAME_ACTION', {
              action: actionName,
              roomId,
              clientActionId,
              data: {
                roomId,
                stateVersion: initialStateVersion,
                pingTs: Date.now(),
              },
            }),
          );
        }, actionIntervalMs);
        return;
      }

      if (msg.type === 'ACTION_ACK') {
        const actionId = msg?.data?.clientActionId || msg.clientActionId;
        if (actionId && pendingActions[actionId]) {
          actionLatencyMs.add(Date.now() - pendingActions[actionId]);
          delete pendingActions[actionId];
        }
        return;
      }

      if (msg.type === 'ERROR') {
        const errorCode = msg.errorCode || msg?.data?.errorCode;
        if (errorCode === 'ACTION_REJECTED') {
          actionRejected.add(1);
        }
      }
    });

    socket.on('error', function () {
      authFailed.add(1);
    });

    socket.setTimeout(function () {
      socket.close();
    }, Number(__ENV.SOCKET_TIMEOUT_MS || 35000));
  });

  check(response, {
    'ws upgraded (101)': (r) => r && r.status === 101,
  });
}
