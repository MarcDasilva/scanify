## Team Name: Scanify
## Clip Name: ScannerExperience
## Invocation URL Pattern: example.com/scanify/:storeId/scan

---

## What Great Looks Like
Your submission is strong when it is:
- **Specific**: one clear fan moment, one clear problem, one clear outcome
- **Clip-shaped**: value in under 30 seconds, no heavy onboarding
- **Business-aware**: connects to revenue (venue, online, or both)
- **Testable**: prototype actually runs in the simulator with your URL pattern

---

### 1. Problem Framing

Which user moment or touchpoint are you targeting?

- [x] Discovery / first awareness -> the Clip surfaces via Apple Maps when they enter the store
- [x] Intent / consideration  --> scan a product, read specs/allergens/interactions to decide if you want it
- [x] Purchase / conversion -> Potential Apple Pay checkout after scanning 
- [x] In-person / on-site interaction -> the entire scan-and-interact flow
- [x] Post-purchase / re-engagement -> the 8-hour push notification window
- [] Other: ___

What friction or missed opportunity are you solving for?

Every product in every retail store on the planet has a barcode on it. Has had one for over 50 years. And in all that time, those barcodes have done exactly one thing: talk to the store's inventory system. The customer? Completely shut out.

The problem isn't specific to one store or one vertical. It's universal. A parent at Walmart squinting at 4pt allergen text. A shopper at Best Buy Googling the product they're literally standing in front of. Someone at Sephora eyeing a lipstick tester that's been shared with 400 strangers. The product is in their hands, their intent to buy is real, and the infrastructure completely fails them every time. The answer should be on the thing they're already holding. It isn't.

We didn't build one App Clip for one store. We built a **universal barcode interaction platform** delivered as a single Clip, then proved it generalizes by shipping six wildly different experiences across six retail verticals. Same scanner, same router, same architecture. The store determines what you see when you scan. That's the whole idea.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [x] QR Code (printed on physical surface)
- [x] NFC Tag (embedded in object , wristband, poster, etc.)
- [ ] iMessage / SMS Link
- [ ] Safari Smart App Banner
- [x] Apple Maps (location-based)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience** (step by step):
1. Customer walks into any participating store and the Clip surfaces automatically via Apple Maps location registration. Or they see "Scan any product" signage at the entrance and tap a QR code or NFC tag. Either way, the same Clip opens instantly. No download. No account. No onboarding. The store's location (or URL) determines which branding and experience set loads.
2. They point their phone's camera at the barcode on any product. Our live `AVCaptureSession` scanner reads it in real time. The platform routes `(storeId, barcode)` to the right experience automatically. The customer doesn't know or care that Scanify is a platform. They just see a store-branded interaction that gives them exactly what they need for that product.
3. They get the info they need in under 30 seconds. If they want to buy, it's one-tap Apple Pay. If they don't, the 8-hour push notification window kicks in with product-specific (not generic) re-engagement based on what they actually scanned.

**How does the 8-hour notification window factor into your strategy?**

This is honestly the most underrated part of this project. Every barcode scan is an intent signal. Not a vague "they visited the website" signal. A "they physically picked up this specific product in this specific store" signal. That's the strongest purchase intent data retail has ever had, and it's been completely wasted until now.

So the 8-hour window becomes three touches: at +15 minutes (while they're still in the store) we surface something immediately useful like an allergen report or a stock update. At +2 hours we suggest a cross-sell or alternative based on what they scanned. At +8 hours, right before the window closes, we send a re-engagement nudge that references the exact product. "The Sony WH-1000XM5 you looked at is $15 less online." Not "hey come back and shop!", that's what everyone else does and everyone ignores it.

Industry average push conversion is 3-5%. We think we can hit 8-12% because these aren't spray-and-pray notifications. They're based on someone physically holding the product. That's a fundamentally different intent level.

---

### 3. Platform Extensions (if applicable)

Yeah, we're proposing one, and we think it's a big deal for Reactiv specifically.

Right now, Reactiv Clips are URL-invoked. The URL determines the experience. That works great for single-purpose Clips, but it breaks down when you want one Clip to handle thousands of products. You'd need thousands of URLs.

We're proposing a **Barcode Routing Layer**: a post-invocation routing system where the URL gets you into the Clip, and the barcode determines what you see inside it. One URL per store, infinite product experiences.

The implementation on Reactiv's side would be a dashboard where merchants map barcode prefixes to experience templates (e.g., "all barcodes starting with `001600` route to the Nutrition & Allergen template"). Product data auto-pulls from their Shopify catalog via the existing Reactiv-Shopify integration. We built the entire client-side routing in our prototype,the `(storeId, barcode) -> experience` pure function that powers all six stores. What's missing is the merchant-facing dashboard, and that's a natural extension of what Reactiv already has.

Why this matters for Reactiv's business: it moves them from "merchants who want a mobile app" to "any retailer with products on shelves." That's not an incremental TAM expansion. That's a categorically different market.

---

### 4. Prototype Description

Scanify is **one App Clip**,one scanner, one router, one architecture. To prove that a generalized barcode interaction platform actually works, we built six completely different experiences across six retail verticals. Each one has a fundamentally different information need when you scan a barcode, and each one pushes a different technical capability. If the same Clip handles all six, it can handle anything.

**The Platform (shared across all experiences):**

- A real `AVCaptureSession` barcode scanner with live camera preview, animated scan line, composited overlay with corner brackets, haptic feedback on detection, and duplicate scan prevention. On simulator it gracefully degrades to tappable demo product buttons. On a phone, you're pointing the camera at a real barcode and it just works.
- A pure-function router: input `(storeId, barcode)`, output the correct SwiftUI view and product data. No side effects, no state.
- A `StoreBranding` system that applies each merchant's full visual identity (colors, logos, loading screens) automatically from the URL.
- Adding a new store means writing the view, conforming to `ClipExperience`, and registering it. Scanner, routing, branding, notifications all work automatically.


The point isn't that we built six apps. The point is that we built **one platform** and then showed it can produce an allergen scanner, an AR try-on, a drug interaction checker, a 3D product preview, a full e-commerce flow, and a product intelligence sheet,all from the same scanner, the same router, the same `ClipExperience` protocol. That's what makes this a platform and not a feature.

All screens and flows are functional. Zero external dependencies,no SPM, no CocoaPods, no nothing.

---

### 5. Impact Hypothesis

Here's what we think happens if this ships:

**In-store (primary channel):** Shoppers who physically pick up a product are already 70%+ of the way to buying it. That's not our number, that's basic retail psychology,tactile engagement correlates directly with purchase intent. Scanify catches them at the exact peak of that intent and removes every remaining friction point. No app download, no account creation, no line to wait in, no employee to track down. Scan, get info, tap Buy, done. We think this converts at meaningfully higher rates than any existing in-store digital touchpoint because we're not asking the customer to do anything new. They're already holding the product. We just gave them a reason to scan what's already on it.

**Online recovery (secondary channel):** The 8-hour push window turns abandoned in-store interest into online conversions. This is the part that doesn't exist at all in traditional retail. Right now, when a customer walks out without buying, the relationship is over. There is literally zero re-engagement path. Scanify creates one, and it's based on the strongest possible intent signal,they physically held the product. We estimate 8-12% push notification conversion (vs. 3-5% industry average) because these notifications reference specific products, not generic retargeting.

**For Reactiv specifically:** The Barcode Routing Layer expands Reactiv's addressable market from "merchants who want a mobile app" to "any retailer with products on shelves." That's... basically everyone. A corner store with 500 products and zero interest in building an app could still use Scanify through the Reactiv dashboard. Per-scan pricing or monthly SaaS per merchant. Each scan is a measurable, attributable event, which means the ROI story practically writes itself.

**Why this touchpoint:** Because the barcode is already there. We didn't have to convince anyone to install new infrastructure. We didn't have to print new labels or deploy NFC tags or redesign packaging. The barcodes have been on every product for 50 years. We just pointed them at the customer for the first time. That's the whole insight, and honestly we're still a little surprised nobody did it before us.

---

Side note: when we talked to the Reactiv team during the hackathon and heard you guys are developing something for Indigo that does exactly this,scan a book's barcode and surface a quick analysis or App Clip experience tied to it,it made us more confident in our idea. We'd been building Scanify in parallel without knowing that, and hearing that the barcode-as-entry-point idea independently aligned with where Reactiv is already heading was genuinely validating. Thanks!

### Demo Video

Link: https://www.youtube.com/watch?v=l2OojdVe8BU

### Screenshot(s)

#### Walmart
![Walmart Barcode Scan](public/images/submission%20images/walmart_barcode.png)
![Walmart Loader](public/images/submission%20images/walmart_loader.png)
![Walmart App Clip 1](public/images/submission%20images/walmart_appclip1.png)
![Walmart App Clip 2](public/images/submission%20images/walmart_appclip2.png)

#### Nike
![Nike Barcode Scan](public/images/submission%20images/nike_barcode.png)
![Nike Loader](public/images/submission%20images/nike_loader.png)
![Nike App Clip 1](public/images/submission%20images/nike_appclip1.png)
![Nike App Clip 2](public/images/submission%20images/nike_appclip2.png)
![Nike App Clip 3](public/images/submission%20images/nike_appclip3.png)
![Nike App Clip 4](public/images/submission%20images/nike_appclip4.png)

#### Sephora
![Sephora Barcode Scan](public/images/submission%20images/sephora_barcode.png)
![Sephora App Clip 1](public/images/submission%20images/sephora_appclip1.png)
![Sephora App Clip 2](public/images/submission%20images/sephora_appclip2.png)
![Sephora App Clip 3](public/images/submission%20images/sephora_appclip3.png)
![Sephora App Clip 4](public/images/submission%20images/sephora_appclip4.png)

#### Best Buy
![Best Buy Barcode Scan](public/images/submission%20images/bestbuy_barcode.png)
![Best Buy App Clip 1](public/images/submission%20images/bestbuy_appclip1.png)
![Best Buy App Clip 2](public/images/submission%20images/bestbuy_appclip2.png)
![Best Buy App Clip 3](public/images/submission%20images/bestbuy_appclip3.png)
![Best Buy App Clip 4](public/images/submission%20images/bestbuy_appclip4.png)

#### Shoppers Drug Mart
![Shoppers App Clip 1](public/images/submission%20images/shoppers_appclip1.png)
![Shoppers App Clip 2](public/images/submission%20images/shoppers_appclip2.png)

#### Baskin-Robbins
![Baskin-Robbins Barcode Scan](public/images/submission%20images/baskin_robins_barcode.png)
![Baskin-Robbins App Clip](public/images/submission%20images/baskin_robins_appclip.png)

#### Scannable Barcodes (for live demo)
![Walmart Barcode](public/images/submission%20images/walmart_scannable_barcode.png)
![Nike Barcode](public/images/submission%20images/nike_scannable_barcode.png)
![Sephora Barcode](public/images/submission%20images/sephora_scannable_barcode.png)
![Best Buy Barcode](public/images/submission%20images/best_buy_scannable_barcode.png)
![Shoppers Barcode](public/images/submission%20images/shoppers_scannable_barcode.png)
![Baskin-Robbins Barcode](public/images/submission%20images/baskin_robbins_scannable_barcode.png)

#### Push Notifications (8-Hour Window)

**Walmart**
![Walmart +15min](public/notifications/walmart/walmart%2015%20min.png)
![Walmart +2hr](public/notifications/walmart/walmart%202%20hour.png)
![Walmart +8hr](public/notifications/walmart/walmart%208%20hour.png)

**Nike**
![Nike +15min](public/notifications/nike/nike%2015%20min.png)
![Nike +2hr](public/notifications/nike/nike%202%20hour.png)
![Nike +8hr](public/notifications/nike/nike%208%20hour.png)

**Sephora**
![Sephora +15min](public/notifications/sephora/sephora%2015%20min.png)
![Sephora +2hr](public/notifications/sephora/sephora%202%20hour.png)
![Sephora +8hr](public/notifications/sephora/sephora%208%20hour.png)

**Best Buy**
![Best Buy +15min](public/notifications/best%20buy/best%20buy%2015%20min.png)
![Best Buy +2hr](public/notifications/best%20buy/best%20buy%202%20hour.png)
![Best Buy +8hr](public/notifications/best%20buy/best%20buy%208%20hour.png)

**Shoppers Drug Mart**
![Shoppers +15min](public/notifications/shoppers/shoppers%2015%20min.png)
![Shoppers +2hr](public/notifications/shoppers/shoppers%202%20hour.png)
![Shoppers +8hr](public/notifications/shoppers/shoppers%208%20hour.png)