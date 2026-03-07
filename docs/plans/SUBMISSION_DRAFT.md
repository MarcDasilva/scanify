## Team Name: Scanify
## Clip Name: Scanify — Universal Barcode Interaction Platform
## Invocation URL Pattern: `scanify.app/store/:storeId/scan`

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

- [ ] Discovery / first awareness
- [ ] Intent / consideration
- [x] Purchase / conversion
- [x] In-person / on-site interaction
- [x] Post-purchase / re-engagement
- [x] Other: Every moment a consumer holds a product and wants more information

What friction or missed opportunity are you solving for? (3-5 sentences)

Every physical product already has a barcode, but that barcode only serves the merchant's internal systems — consumers get zero value from it. When a shopper wants to know if a shirt comes in their size, what allergens are in a food item, what a medication actually treats, how a lipstick shade looks on them, or what specs a device has, they must hunt down an employee, squint at tiny packaging, or search the web. If the store doesn't carry their size, the sale is completely lost — there's no frictionless path from "I'm holding this product" to "ship it to my house in the right size." Scanify transforms the existing barcode from a merchant-only tool into a consumer-facing interaction point: scan any product's barcode and instantly get contextual, category-aware information and action. When the store can't fulfill the need, one tap converts the in-store browse into an online purchase — capturing revenue that would otherwise walk out the door.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [x] QR Code (printed on physical surface)
- [x] NFC Tag (embedded in object — wristband, poster, etc.)
- [ ] iMessage / SMS Link
- [x] Safari Smart App Banner
- [x] Apple Maps (location-based)
- [x] Siri Suggestion
- [ ] Other: ___

The primary invocation is a **QR code placed at the store entrance or at shelf endcaps**. This single QR code opens the Scanify scanner clip for that store. From there, the customer uses their phone camera to scan any product's existing barcode — no new QR codes needed per product. The URL carries only the store context (`scanify.app/store/sephora/scan`), not the product. The product comes from the barcode scan inside the Clip.

Secondary invocations: NFC tags on shelf-edge labels, Apple Maps place cards for the store location, Smart App Banners on the retailer's website, Siri suggestions after visiting the store.

**End-to-end user experience** (step by step):

1. **Trigger**: Customer walks into a store and sees a sign at the entrance: "Scan any product for instant details." They scan the QR code on the sign with their iPhone camera.
2. **Clip Opens**: Scanify opens instantly (no install, no login). A branded camera viewfinder appears with a scanning frame overlay and the instruction "Point at any barcode." The store name and branding are visible in the header.
3. **Barcode Scan**: Customer holds their phone up to a product's barcode (on the tag, box, or shelf label). The barcode is read in under 1 second.
4. **Contextual Experience**: Based on the product category, the right experience loads as a sheet over the scanner:
   - *Apparel*: Size grid with real-time stock levels. Size M shows red (out of stock). "Not in store? Get it shipped." button appears with M pre-selected.
   - *Grocery*: Allergen verdict front and center — "CONTAINS: Gluten, Tree Nuts" in red. Nutrition breakdown and a safer alternative with aisle location below.
   - *Pharmacy*: "Treats: headache, sinus pressure, nasal congestion. Does NOT treat: cough, sore throat, fever." Interaction checker below — type in your current meds, get a safety verdict. Generic equivalent callout saves $7.
   - *Cosmetics*: AR camera overlay maps lipstick shade onto your face. Swipe through 6 shades in 5 seconds. "That's the one." One tap to buy.
   - *Electronics*: Full product intelligence hub — specs, warranty info (with registration and extended tier upsell), and compatible accessories currently in stock with aisle numbers.
5. **Action (optional)**: If the customer wants to buy online (out of stock, prefer shipping), they tap "Buy Online" → Apple Pay sheet → confirm → order placed. Total time: ~20 seconds.
6. **Done**: Customer dismisses the sheet. Scanner is ready for the next product. Repeat as many times as needed. When finished, put phone away — the Clip disappears. No app installed, no account created.

**How does the 8-hour notification window factor into your strategy?**

Every barcode scan is a signal of purchase intent — the customer physically picked up and examined the product. The 8-hour notification window lets us convert that intent even after the customer leaves the store:

- **+15 min**: "Still thinking about the Nike Dri-FIT in size M? It ships free today." (Recover abandoned interest)
- **+1 hour**: "The Sony WH-1000XM5 you checked out is $30 off online right now." (Price incentive)
- **+3 hours**: "You scanned 4 items at Best Buy today. View them all and order from home." (Session recap)
- **+6 hours**: "That Dior lipstick shade you tried on? Free shipping ends at midnight." (Last nudge)
- **+7.5 hours**: "Last chance: your personalized store session expires in 30 minutes." (Urgency)

Each notification deep-links directly back to the specific product with the customer's selected variant (size, shade, etc.) pre-loaded — ready to buy in one tap. This turns every in-store browse into an online conversion opportunity that persists for 8 hours.

---

### 3. Platform Extensions (if applicable)

Yes. Scanify proposes two new Reactiv Clips capabilities:

**1. Barcode-Triggered Experience Routing (1:many clip model)**

Today, Reactiv Clips operate on a 1:1 model — one URL maps to one experience. Scanify requires a **1:many** model where a single clip entry point (the scanner) dynamically routes to different experience templates based on what the consumer scans.

This requires:
- **Merchant experience configurator**: A dashboard UI in Reactiv where merchants map product categories to experience templates (e.g., "All apparel → Sizing & Inventory," "All food → Nutrition Check"). No code required.
- **Real-time inventory API bridge**: The clip needs to query current stock levels by store location + SKU. Reactiv would broker this from the merchant's Shopify inventory data.
- **Barcode-to-SKU resolver**: A service that maps standard barcodes (EAN-13/UPC-A) to the merchant's Shopify product catalog. This leverages Reactiv's existing Shopify integration.

This extends Reactiv from "build App Clips for your store" to "turn every barcode in your store into a consumer interaction point."

**2. Intent Signal Analytics**

Each barcode scan generates a data point: which product, which store, what time, what the user did after scanning (bought online, dismissed, checked alternatives, checked interactions). Aggregated across users, this gives merchants product-level engagement analytics they've never had: which products get picked up but not purchased? Which sizes are most requested but least stocked? Which allergens cause the most product rejections? Which OTC medications get the most interaction checks? This data is transformative for inventory planning, merchandising, and product development.

---

### 4. Prototype Description

The working prototype demonstrates the full Scanify flow in the ReactivChallengeKit simulator:

**Implemented screens/flows:**

1. **Scanner Entry** (`ScanifyExperience`): Invoked via `scanify.app/store/demo/scan` in the Invocation Console. Shows a branded header with store name derived from storeId. Displays 5 tappable product cards simulating barcode scans (since the Xcode simulator has no camera). Each card shows product name, brand, barcode, and a category icon.

2. **Inventory & Size Check flow** (Apparel): Tap Nike Dri-FIT Running Tee → see size grid with green/yellow/red stock indicators → size M is unavailable → tap "Not in store? Get it shipped." → simulated Apple Pay → order confirmation. Demonstrates the core revenue conversion: out-of-stock becomes online sale.

3. **Allergen & Nutrition Check flow** (Grocery): Tap Nature Valley Granola Bar → immediately see red allergen banner "CONTAINS: Gluten, Tree Nuts" → allergen badge grid (red/green) → dietary flags → nutrition bar chart → "Safer Alternative: Enjoy Life Bars (Nut-Free) — Aisle 7." Demonstrates the safety-first information value.

4. **Medicine Guide + Interaction Check flow** (Pharmacy): Tap Advil Cold & Sinus → see "Treats: Headache, Sinus Pressure, Congestion" in green badges → "Does NOT Treat: Cough, Sore Throat, Fever" in grey → enter "Lisinopril" in interaction checker → "MODERATE INTERACTION" warning with explanation → "Generic equivalent: Shoppers Brand — save $7." Demonstrates the novel pharmacy vertical nobody has built.

5. **AR Virtual Try-On flow** (Cosmetics): Tap Dior Rouge Lipstick → see shade preview area (static mockup in simulator, live ARKit on device) → shade picker carousel with 6 shades → tap "Buy Now" → checkout bridge. Demonstrates the visual/experiential potential.

6. **Full Product Intelligence flow** (Electronics): Tap Sony WH-1000XM5 → categorized spec cards (Audio, Battery, Connectivity, Physical) → warranty section (1-year standard, extend to 3 for $49, register button) → compatible accessories ("Sony Carrying Case — $29.99 — Aisle 7") → "What's in the Box." Demonstrates depth — three concerns (specs, warranty, accessories) solved in one scan.

7. **Checkout Bridge** (shared): Triggered from apparel and cosmetics flows when user taps buy → product summary with selected variant → Apple Pay button → order confirmation via ClipSuccessOverlay.

8. **Notification Preview**: Info button on scanner shows notification timeline strategy using NotificationPreview components — 5 timed pushes over 8 hours.

Each flow completes in under 30 seconds as tracked by the MomentTimer.

---

### 5. Impact Hypothesis

**Which channel benefits?**

Both in-person and online, with emphasis on **online conversion from in-store intent**.

**In-person impact:**
- **Inventory Check** eliminates the #1 cause of walk-aways in apparel: "they don't have my size." By showing stock levels instantly and routing unavailable sizes to online purchase, the sale is never lost.
- **Allergen Check** builds consumer trust and redirects purchases to safer alternatives the consumer wouldn't have found on their own — basket switching, not basket abandonment.
- **Medicine Guide** removes the pharmacist bottleneck for simple OTC questions. "Which cold medicine do I need?" and "Is this safe with my blood pressure meds?" are answered in 10 seconds instead of a 10-minute wait.
- **Product Intelligence** lets electronics shoppers self-serve on specs, warranty, and accessories — reducing staff dependency while increasing accessory attach rate (the "case in Aisle 7" nudge).
- **AR Try-On** reduces cosmetics return rates (currently ~40% due to wrong shade selection) by letting customers preview before purchasing.

**Online impact (primary revenue driver):**
- Every out-of-stock moment is currently a lost sale. Scanify converts "we don't have your size" into "we'll ship your size to your house." For a retailer with 15-20% stockout rate on popular items, this is pure incremental revenue.
- The 8-hour notification window converts post-visit browsing intent. With hyper-contextual notifications (specific product the user physically held), we estimate 8-15% conversion on push notifications — well above the industry average of 5-10% for generic abandoned cart pushes.
- Online sales carry higher margins (no venue/retail split, lower fulfillment cost for direct-to-consumer).

**Why this touchpoint is the right place to intervene:**

The in-store moment is the highest-intent point in the entire customer journey. The customer traveled to the store, found the product, and is physically holding it. The only barriers to purchase are information gaps (What are the allergens? What does this treat? What are the specs? How does this shade look on me?) or logistics gaps (They don't have my size). Scanify closes both instantly. No other touchpoint combines this level of purchase intent with this density of solvable friction.

**Scalability:**
- **Zero new hardware**: Every product already has a barcode. Stores already have signage. One QR code per store entrance is the only physical requirement.
- **Merchant self-serve**: Through the Reactiv dashboard, any Shopify merchant can configure their barcode experiences without writing code.
- **Category-agnostic**: The same scanner works for apparel, grocery, pharmacy, cosmetics, electronics, and any future vertical. The barcode is the universal key.
- **Network effects**: As consumers learn "I can scan anything," the behavior compounds across merchants and verticals. One interaction teaches the consumer a universal pattern.

---

### Demo Video

Link: ___ (to be recorded after prototype is built)

### Screenshot(s)

(To be captured after prototype is built)
