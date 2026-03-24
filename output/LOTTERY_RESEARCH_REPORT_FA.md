# گزارش تحقیقاتی ماژول Lottery

تاریخ: 2026-03-24

## خلاصه اجرایی

- مدل موفق iLottery در دنیا معمولا یک بازی واحد نیست؛ یک پورتفوی از چند فرمت است: `jackpot draw` + `instant win` + `raffle` + `subscription` + `loyalty/second-chance`.
- برای کاربر، جذاب‌ترین فرمت‌ها معمولا دو گروه‌اند: `جک‌پات‌های بزرگ و رول‌اور` مثل Powerball / Mega Millions / EuroMillions، و `بازی‌های سریع و پرفرکانس` مثل Instant Win.
- برای کسب‌وکار، فقط جک‌پات کافی نیست. اپراتورهای موفق کنار draw-based حتما ابزارهای retention مثل subscription، favorite purchase، second chance، rewards و group play دارند.
- اگر قرار است «لاتاری واقعی با پول واقعی» اجرا شود، مهم‌ترین ریسک نه فنی بلکه `رگولاتوری` است: لایسنس، KYC، سن قانونی، geolocation، ضدتقلب، محدودیت بازی، claim prize، مالیات و audit.
- اگر وضعیت حقوقی/مجوز روشن نیست، بهتر است به‌جای «real-money lottery» سراغ یک `promotional draw / prize campaign` با ساختار حقوقی درست برویم. طبق راهنمای FTC، sweepstakes واقعی باید رایگان باشد و نباید خرید یا پرداخت شانس را افزایش دهد.

## مدل‌های رایج لاتاری آنلاین

### 1) Draw-Based Jackpot

تعریف:
قرعه‌کشی زمان‌بندی‌شده با بلیت‌های زیاد، prize pool بزرگ، و در بسیاری از موارد `rollover`.

ویژگی‌ها:
- یک یا چند draw در هفته
- `Quick Pick / Lucky Dip`
- prize tiers
- jackpot rollover
- add-on ها مثل multiplier یا secondary draw

نمونه‌های شاخص:
- Powerball
- Mega Millions
- EuroMillions
- Lotto

مزایا:
- برندپذیری بالا
- مناسب کمپین و مارکتینگ
- قابلیت وایرال هنگام بزرگ شدن jackpot

ضعف‌ها:
- engagement روزانه پایین‌تر از instant games
- وابستگی بالا به jackpot size

### 2) Fixed-Prize / Daily-Weekly Draw

تعریف:
قرعه‌کشی‌های منظم با top prize ثابت یا تقریبا ثابت.

نمونه:
- Thunderball
- Fantasy 5 / daily numbers
- HotPicks style games

مزایا:
- فرکانس بیشتر
- تجربه ساده‌تر
- قابل‌پیش‌بینی‌تر برای کاربر

کاربرد:
بهترین مکمل برای jackpot game در فاز اول.

### 3) Lifestyle / Annuity Lottery

تعریف:
به‌جای یک جایزه نقدی بسیار بزرگ، جایزه به‌صورت `درآمد ماهانه/سالانه بلندمدت` ارائه می‌شود.

نمونه:
- Set For Life
- Lucky for Life
- Cash4Life

مزایا:
- برای بخش بزرگی از کاربران از jackpot میلیاردی ملموس‌تر است
- positioning بسیار خوب برای برندسازی
- جذابیت بالا با هزینه رسانه‌ای کمتر از mega jackpot

### 4) Instant Win / eInstant / eScratch

تعریف:
کاربر همان لحظه نتیجه را می‌بیند؛ معادل آنلاین scratch card.

ویژگی‌ها:
- session کوتاه
- تنوع theme بالا
- امکان progressive prize
- suitable for mobile-first behavior

مزایا:
- retention و frequency بسیار بالا
- مناسب personalization و CRM
- تولید محتوای فصلی/کمپینی راحت

ضعف‌ها:
- مسئولیت‌پذیری بازی و کنترل رفتار کاربر حیاتی‌تر می‌شود
- نیاز شدید به limit tools و safer-play controls

### 5) Online Raffle

تعریف:
تعداد بلیت محدود، قیمت ثابت، تعداد جوایز و odds از قبل مشخص.

حالت‌های رایج:
- draw وقتی همه بلیت‌ها فروخته شد
- draw در تاریخ/ساعت از قبل تعیین‌شده

مزایا:
- scarcity قوی
- درک odds برای کاربر ساده‌تر
- مناسب event-based launch

### 6) Keno / Fast Draw / Rapid Draw

تعریف:
drawهای بسیار پرتکرار، کوتاه و سریع.

مزایا:
- engagement بالا
- مناسب کاربران عادت‌محور

ضعف:
- از نظر responsible gaming حساس‌تر است
- برای فاز اول معمولا انتخاب محافظه‌کارانه‌ای نیست

### 7) Syndicate / Group Play

تعریف:
خرید گروهی بلیت و تقسیم برد.

مزایا:
- اجتماعی‌تر شدن محصول
- افزایش average ticket size
- مناسب تیم‌ها، دوستان، خانواده

### 8) Loyalty / Second-Chance / Daily Rewards

تعریف:
لایه وفاداری روی لاتاری، نه خود بازی اصلی.

نمونه‌ها:
- Daily Spin to Win
- second-chance drawings
- rewards for non-winning tickets
- bonus / coupon / entry systems

مزایا:
- retention بالا
- حفظ کاربرهای non-winning
- فرصت عالی برای gamification

## اپراتورهای موفق عملا چه می‌فروشند؟

بر اساس منابع رسمی اپراتورها و WLA، الگوی موفق این است:

- `Draw-based games`
- `Instant-win games`
- `Online account + wallet`
- `Subscriptions`
- `Responsible gaming toolkit`
- `Cross-channel experiences`
- `Rewards / second chance`

این یعنی اگر ما فقط یک «قرعه‌کشی ساده» بسازیم، از الگوی موفق بازار عقب خواهیم بود.

## بهترین و پرطرفدارترین الگوها و برندها

نکته:
واژه «بهترین» در این بازار مطلق نیست. از دید محصولی، بهتر است بر اساس `جذابیت کاربر + موفقیت عملیاتی + قابلیت پیاده‌سازی` قضاوت کنیم.

### 1) Powerball

چرا مهم است:
- یکی از مشهورترین mega-jackpot های دنیا
- پوشش بسیار گسترده در آمریکا
- رکورد jackpot جهانی
- مدل کلاسیک `rollover + annuity/cash option`

برای الهام گرفتن:
- جک‌پات بزرگ
- drawهای زمان‌بندی‌شده
- add-on
- برندینگ رسانه‌ای قوی

### 2) Mega Millions

چرا مهم است:
- mega-jackpot بسیار مشهور
- چندین jackpot بالای 1 میلیارد دلار
- فروش در 45 ایالت + DC + USVI
- خرید آنلاین در بعضی jurisdictionها

برای الهام گرفتن:
- multiplier
- آنلاین‌سازی draw game
- multi-jurisdiction operation

### 3) EuroMillions

چرا مهم است:
- یکی از موفق‌ترین مدل‌های multi-country lottery
- مثال خوب برای `shared prize pool + local companion prize`
- ترکیب jackpot بزرگ با جوایز جانبی متعدد

برای الهام گرفتن:
- ساختار چندلایه جایزه
- localized companion prize
- جذابیت فرامرزی

### 4) Set For Life و معادل‌های آن

چرا مهم است:
- از نظر positioning محصولی بسیار هوشمند است
- برای کاربران «درآمد ماهانه برای سال‌ها» از «عدد نجومی دور از ذهن» قابل‌فهم‌تر است
- برای برندسازی بلندمدت عالی است

برای الهام گرفتن:
- prize narrative قوی
- جذابیت mass-market

### 5) Instant Win portfolios

نمونه‌های الهام‌بخش:
- The National Lottery Instant Win Games
- Michigan iLottery / eInstant ecosystems

چرا مهم است:
- در عمل retention engine اصلی بسیاری از iLottery ها هستند
- به اپراتور اجازه می‌دهند ده‌ها تم، کمپین و بازی کوتاه داشته باشد

### 6) Online Raffles

نمونه:
- Michigan Online Raffles

چرا مهم است:
- ساده، event-driven و قابل‌فهم
- برای launch های مناسبتی بسیار خوب است

## اگر بخواهیم برای سیستم خودمان تصمیم بگیریم، چه گزینه‌هایی داریم؟

### گزینه A: Real-Money Licensed Lottery

مناسب وقتی:
- بازار هدف و مجوز روشن باشد
- تیم آمادگی compliance و عملیات مالی داشته باشد

حداقل نیازمندی‌ها:
- account + wallet
- KYC / identity verification
- age gate
- geolocation یا کنترل jurisdiction
- game configuration engine
- ticket ledger
- draw engine یا certified RNG / audited draw process
- prize claim flow
- payment verification
- anti-fraud
- safer play tools
- audit log و dispute handling

این گزینه از نظر تجاری قوی است، ولی سنگین‌ترین گزینه از نظر حقوقی و عملیاتی هم هست.

### گزینه B: Promotional Draw / Prize Campaign

مناسب وقتی:
- هنوز وضعیت مجوز real-money روشن نیست
- می‌خواهیم engagement و marketing را تست کنیم

ویژگی:
- prize pool ممکن است sponsor-funded باشد
- ممکن است free entry داشته باشد
- بیشتر برای retention / campaign / user acquisition مناسب است

هشدار:
اگر ساختار حقوقی درست نباشد، خیلی راحت چیزی که «کمپین» نامیده شده عملا از نظر حقوقی lottery تلقی می‌شود. طبق FTC، sweepstakes واقعی باید free entry داشته باشد و نباید خرید شرط ورود یا افزایش شانس باشد.

### گزینه C: Virtual / Points-Based Lottery

مناسب وقتی:
- می‌خواهیم فقط تجربه محصولی و UX را تست کنیم
- فعلا cash-out نمی‌خواهیم

مزایا:
- سریع‌ترین مسیر برای تست تقاضا
- ریسک حقوقی کمتر از real-money

ضعف:
- appeal کمتر از نسخه پول واقعی

## پیشنهاد محصولی من برای فازبندی

### پیشنهاد اصلی

اگر بخواهید ماژول Lottery را به شکل «واقعی و قابل رشد» اضافه کنید، بهترین نقطه شروع این ترکیب است:

1. یک `jackpot draw` هفتگی یا دو بار در هفته
2. یک `fixed-prize draw` روزانه/چندبار در هفته
3. یک `lifestyle prize` مدل Set For Life
4. یک `limited-ticket raffle` مناسبتی
5. از همان روز اول: `subscription + favorite purchase + notifications + responsible gaming`

چرا:
- فقط jackpot، retention کافی نمی‌سازد
- فقط instant win، perception برند لاتاری را ضعیف می‌کند
- raffle و lifestyle game تنوع سالم و قابل‌فهم ایجاد می‌کنند

### چیزی که برای فاز اول توصیه نمی‌کنم

- شروع فقط با یک mega-jackpot
- شروع مستقیم با fast-draw/keno
- شروع بدون wallet / claim / audit / safer-play
- استفاده از واژه sweepstake در حالی که ورودی پولی می‌گیریم ولی ساختار حقوقی شفاف نداریم

## الزامات حیاتی برای طراحی سیستم

### 1) Compliance

- jurisdiction rules
- age verification
- identity verification
- sanctions / AML checks در صورت نیاز
- terms / procedures / dispute rules

### 2) Responsible Gaming

- deposit limits
- loss limits
- time-out / self exclusion
- reminders
- activity history

### 3) Payments and Claims

- deposit methods
- withdrawals
- prize wallet
- tax-reported claims
- document upload for verification

### 4) Trust and Fairness

- certified randomness or audited draw procedures
- immutable draw history
- transaction history
- receipt / ticket proof
- transparent odds

### 5) Product Retention

- favorite purchases
- subscriptions
- jackpot-threshold subscriptions
- second chance
- rewards and daily spin
- group play

## نتیجه‌گیری تصمیم‌گیری

اگر هدف شما ساخت یک ماژول `Lottery` جدی و رقابتی است، تصمیم درست این نیست که «یک قرعه‌کشی اضافه کنیم». تصمیم درست این است که یکی از این دو مسیر را انتخاب کنیم:

### مسیر پیشنهادی 1

اگر مجوز و بازار هدف روشن است:
`Licensed iLottery portfolio`

ترکیب پیشنهادی:
- Jackpot draw
- Fixed-prize draw
- Set-for-life style game
- Raffle
- Subscription + responsible gaming + rewards

### مسیر پیشنهادی 2

اگر مجوز هنوز روشن نیست:
`Promotional / points-based lottery-like module`

ترکیب پیشنهادی:
- Free-entry campaigns
- points-based draws
- sponsored prizes
- loyalty rewards
- second chance

## جمع‌بندی نهایی من

بهترین الگو برای شما به احتمال زیاد این است:

- از نظر محصول: `hybrid portfolio`
- از نظر بازار: `draw-based + instant-like retention mechanics`
- از نظر ریسک: اول تکلیف `jurisdiction و مجوز` روشن شود

اگر بخواهم یک تصمیم خیلی عملی بدهم:

`برای فاز تصمیم‌گیری، Lottery را به‌عنوان یک Product Line ببینید نه یک Game Type.`

یعنی در طراحی اولیه از همین حالا برای این بلوک‌ها جا باز کنید:
- Game definitions
- Draw schedules
- Ticket ledger
- Prize rules
- Wallet / claims
- Limits / responsible gaming
- Rewards / promotions
- Syndicates / subscriptions

## منابع

- WLA Responsible Gaming FAQ
  - https://world-lotteries.org/services/industry-standards/responsible-gaming/rgf-faq
- Allwyn Annual Report 2024
  - https://cdn.allwyn.com/Allwyn_Annual_Report_2024_Hyperlink_250425_2_ea0f81ce81.pdf
- The National Lottery home / games / healthy play
  - https://www.national-lottery.co.uk/?vm=r
- The National Lottery Service Guide
  - https://www.lb.national-lottery.co.uk/service-guide
- Michigan Lottery FAQ: online draw games
  - https://faq.michiganlottery.com/account-information-d9a19100/online-draw-games-79ab91b7/how-to-purchase-a-draw-game-online-e09e9f12
- Michigan Lottery FAQ: online raffles
  - https://faq.michiganlottery.com/online-games-information-286703b2/online-raffles-faq-c254e42f/online-raffles-overview-189c4315
- Michigan Lottery FAQ: subscriptions
  - https://faq.michiganlottery.com/online-games-information-286703b2/subscriptions-draw-games-aed5db36/online-draw-game-subscriptions-faq-651f24be
- Michigan Lottery FAQ: location verification
  - https://faq.michiganlottery.com/account-information-d9a19100/location-verification-7ad08396/location-services-verification-faqs-4dad10fa
- Michigan Lottery FAQ: online prize claims
  - https://faq.michiganlottery.com/prize-claim-information-e6e95589/claiming-a-prize-f8aa4e6c/how-do-i-claim-an-online-prize-e47a2f74
- Michigan Lottery FAQ: payment verification
  - https://faq.michiganlottery.com/account-information-d9a191/withdrawing-funds-winnings-33916d/verify-payment-methods-to-collect-winnings-e0c90a
- Michigan Lottery FAQ: daily loss limit
  - https://faq.michiganlottery.com/general-online-faq-3ae10e2a/how-to-set-a-daily-loss-limit-1b33ff60
- Michigan Lottery FAQ: Daily Spin to Win
  - https://faq.michiganlottery.com/promotions-information-62f7cc/daily-spin-to-win-c6e5ee/daily-spin-to-win-information-c6418a
- Powerball official article / FAQs
  - https://www.powerball.com/powerballr-jackpot-670-million-8th-largest-us-lottery-history
  - https://www.powerball.com/faqs
- Mega Millions official FAQs / news
  - https://www.megamillions.com/FAQs.aspx
  - https://www.megamillions.com/News/2025/Enhanced-Mega-Millions-Produces-Three-Multi-Millio.aspx
- FTC consumer guidance on sweepstakes / lottery scams and free-entry principle
  - https://consumer.ftc.gov/articles/fake-prize-sweepstakes-and-lottery-scams

## نکته پایانی

این گزارش مشاوره حقوقی نیست. برای هر مدل پول‌واقعی، قبل از طراحی نهایی باید jurisdiction هدف مشخص شود و بررسی حقوقی محلی انجام شود.
