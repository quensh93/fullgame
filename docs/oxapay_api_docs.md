# OxaPay Crypto Payment API Documentation

> مستند کامل API شارژ کیف پول با رمزارز برای فرانت‌اند ری‌اکت

## Overview

سیستم شارژ کیف پول با استفاده از OxaPay پیاده‌سازی شده. کاربر می‌تواند با **هر رمزارزی** حساب خود را شارژ کند. تمام پرداخت‌ها **به‌صورت خودکار به USDT تبدیل** شده و **هر ۱ USDT = ۱ کوین** به موجودی کاربر اضافه می‌شود.

---

## Flow Diagram

```
کاربر مبلغ وارد می‌کند
    ↓
POST /api/payment/create-invoice  (با JWT Token)
    ↓
سرور فاکتور OxaPay می‌سازد و payLink برمی‌گرداند
    ↓
کاربر به payLink هدایت می‌شود (بازکردن مرورگر)
    ↓
کاربر با رمزارز دلخواه پرداخت می‌کند
    ↓
OxaPay به بکند ما callback می‌زند (خودکار)
    ↓
بکند موجودی کاربر را شارژ می‌کند (خودکار)
    ↓
فرانت با GET /api/payment/status/{trackId} وضعیت را چک می‌کند
```

---

## Authentication

تمام endpoint ها (به‌جز callback) نیاز به **JWT Token** دارند.

```
Authorization: Bearer <JWT_TOKEN>
```

---

## Endpoints

### 1. ساخت فاکتور پرداخت

**`POST /api/payment/create-invoice`**

#### Request

```json
{
  "amount": 50
}
```

| Field    | Type    | Required | Description                                                |
| -------- | ------- | -------- | ---------------------------------------------------------- |
| `amount` | integer | ✅       | مبلغ شارژ به کوین (min: 1, max: 10000). هر ۱ کوین = ۱ USDT |

#### Response (200 OK)

```json
{
  "payLink": "https://pay.oxapay.com/abc123",
  "trackId": "T123456",
  "orderId": "GPA-A1B2C3D4",
  "amount": 50
}
```

| Field     | Type    | Description                                               |
| --------- | ------- | --------------------------------------------------------- |
| `payLink` | string  | لینک صفحه پرداخت OxaPay – کاربر را به این آدرس هدایت کنید |
| `trackId` | string  | شناسه ردیابی فاکتور (برای بررسی وضعیت)                    |
| `orderId` | string  | شناسه سفارش داخلی                                         |
| `amount`  | integer | مبلغ درخواستی                                             |

#### Error Responses

| Status | Body                                             | Description        |
| ------ | ------------------------------------------------ | ------------------ |
| 400    | `{"error": "مبلغ شارژ باید بزرگتر از صفر باشد"}` | مبلغ نامعتبر       |
| 400    | `{"error": "حداکثر مبلغ شارژ ۱۰,۰۰۰ کوین است"}`  | بیش از سقف         |
| 401    | —                                                | توکن نامعتبر       |
| 500    | `{"error": "..."}`                               | خطای سرور / OxaPay |

---

### 2. بررسی وضعیت پرداخت

**`GET /api/payment/status/{trackId}`**

#### Response (200 OK)

```json
{
  "trackId": "T123456",
  "orderId": "GPA-A1B2C3D4",
  "amount": 50,
  "status": "Paid",
  "payCurrency": "BTC",
  "payAmount": "0.00065",
  "createdAt": "2026-02-24T06:30:00Z"
}
```

| Field         | Type    | Description                                                 |
| ------------- | ------- | ----------------------------------------------------------- |
| `trackId`     | string  | شناسه ردیابی OxaPay                                         |
| `orderId`     | string  | شناسه سفارش داخلی                                           |
| `amount`      | integer | مبلغ درخواستی (کوین)                                        |
| `status`      | string  | وضعیت: `WAITING`, `Confirming`, `Paid`, `Failed`, `Expired` |
| `payCurrency` | string  | ارزی که کاربر باهاش پرداخت کرده                             |
| `payAmount`   | string  | مقدار ارز واریز شده                                         |
| `createdAt`   | string  | تاریخ ساخت فاکتور (ISO 8601)                                |

#### Error Responses

| Status | Body                           | Description                         |
| ------ | ------------------------------ | ----------------------------------- |
| 401    | —                              | توکن نامعتبر                        |
| 403    | —                              | این پرداخت متعلق به کاربر دیگری است |
| 404    | `{"error": "پرداخت یافت نشد"}` | trackId نامعتبر                     |

---

## Payment Status Values

| Status       | Description    | Action                                    |
| ------------ | -------------- | ----------------------------------------- |
| `WAITING`    | منتظر پرداخت   | فاکتور ساخته شده، کاربر هنوز پرداخت نکرده |
| `Confirming` | در حال تأیید   | تراکنش بلاکچین ارسال شده، منتظر تأیید     |
| `Paid`       | ✅ پرداخت موفق | کوین‌ها به کیف پول اضافه شده              |
| `Failed`     | ❌ ناموفق      | پرداخت با خطا مواجه شده                   |
| `Expired`    | ⏰ منقضی شده   | فاکتور منقضی شده (بعد از ۶۰ دقیقه)        |

---

## React Implementation Example

### API Service

```typescript
// services/paymentService.ts
import axios from "axios";

const API_BASE = process.env.REACT_APP_API_BASE_URL;

const api = axios.create({
  baseURL: API_BASE,
});

// اضافه کردن JWT به هدر
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("accessToken");
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export interface CreateInvoiceResponse {
  payLink: string;
  trackId: string;
  orderId: string;
  amount: number;
}

export interface PaymentStatusResponse {
  trackId: string;
  orderId: string;
  amount: number;
  status: string;
  payCurrency: string;
  payAmount: string;
  createdAt: string;
}

// ساخت فاکتور
export const createInvoice = async (
  amount: number,
): Promise<CreateInvoiceResponse> => {
  const { data } = await api.post("/api/payment/create-invoice", { amount });
  return data;
};

// بررسی وضعیت
export const getPaymentStatus = async (
  trackId: string,
): Promise<PaymentStatusResponse> => {
  const { data } = await api.get(`/api/payment/status/${trackId}`);
  return data;
};
```

### Deposit Component

```tsx
// components/DepositPage.tsx
import React, { useState } from "react";
import {
  createInvoice,
  getPaymentStatus,
  CreateInvoiceResponse,
} from "../services/paymentService";

const PRESET_AMOUNTS = [5, 10, 25, 50, 100, 250];

const DepositPage: React.FC = () => {
  const [amount, setAmount] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [invoice, setInvoice] = useState<CreateInvoiceResponse | null>(null);

  const handleCreateInvoice = async () => {
    const parsedAmount = parseInt(amount);
    if (!parsedAmount || parsedAmount <= 0 || parsedAmount > 10000) {
      setError("مبلغ نامعتبر است (۱ تا ۱۰,۰۰۰)");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const result = await createInvoice(parsedAmount);
      setInvoice(result);

      // باز کردن لینک پرداخت در تب جدید
      window.open(result.payLink, "_blank");
    } catch (err: any) {
      setError(err.response?.data?.error || "خطا در ساخت فاکتور");
    } finally {
      setLoading(false);
    }
  };

  // بررسی وضعیت پرداخت (Polling)
  const checkStatus = async (trackId: string) => {
    try {
      const status = await getPaymentStatus(trackId);
      if (status.status === "Paid") {
        alert("✅ پرداخت موفق! کوین‌ها به حسابتان اضافه شد.");
      }
      return status;
    } catch {
      // ...
    }
  };

  return (
    <div>
      <h2>شارژ کیف پول</h2>
      <p>هر ۱ USDT = ۱ کوین</p>

      {/* مبالغ پیشنهادی */}
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        {PRESET_AMOUNTS.map((preset) => (
          <button key={preset} onClick={() => setAmount(String(preset))}>
            {preset} کوین
          </button>
        ))}
      </div>

      {/* ورودی مبلغ */}
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="مبلغ (کوین)"
        min={1}
        max={10000}
      />

      <button onClick={handleCreateInvoice} disabled={loading}>
        {loading ? "..." : "💰 پرداخت با کریپتو"}
      </button>

      {error && <p style={{ color: "red" }}>{error}</p>}

      {invoice && (
        <div>
          <p>✅ فاکتور ساخته شد</p>
          <p>شناسه: {invoice.trackId}</p>
          <a href={invoice.payLink} target="_blank" rel="noreferrer">
            رفتن به صفحه پرداخت
          </a>
          <button onClick={() => checkStatus(invoice.trackId)}>
            بررسی وضعیت پرداخت
          </button>
        </div>
      )}
    </div>
  );
};

export default DepositPage;
```

---

## Polling Strategy (پیشنهادی)

بعد از اینکه کاربر به صفحه پرداخت OxaPay رفت، فرانت باید با **Polling** وضعیت پرداخت را بررسی کند:

```typescript
// هر ۱۰ ثانیه وضعیت پرداخت را چک کن
const pollPaymentStatus = (trackId: string) => {
  const interval = setInterval(async () => {
    const status = await getPaymentStatus(trackId);

    if (status.status === "Paid") {
      clearInterval(interval);
      // نمایش پیام موفقیت + بروزرسانی موجودی
    } else if (status.status === "Failed" || status.status === "Expired") {
      clearInterval(interval);
      // نمایش پیام خطا
    }
  }, 10000); // 10 seconds

  // بعد از ۶۵ دقیقه متوقف شود
  setTimeout(() => clearInterval(interval), 65 * 60 * 1000);
};
```

---

## Notes

- **Auto Convert to USDT**: حتماً در پنل OxaPay گزینه Auto Convert to USDT فعال باشد
- **Callback خودکار**: شارژ کیف پول توسط بکند و از طریق webhook خودکار انجام می‌شود
- **امنیت**: تمام callback ها با HMAC-SHA512 تأیید می‌شوند
- **Sandbox**: برای تست، می‌توانید در OxaPay حالت sandbox فعال کنید
