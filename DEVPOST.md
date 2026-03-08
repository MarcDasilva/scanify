# Scanify

**One scan. Every product. Zero friction.**

A universal barcode interaction platform delivered as an App Clip.

Scanify turns the barcodes already on every product into a consumer-facing interaction layer. Walk into a store, open the Clip, scan any product, and instantly get an experience tailored to that product and that merchant. No app download, no account, no searching. Just point and know.

---

## Inspiration

Every retail store on the planet is covered in barcodes. Billions of them. Stuck on every product, printed on every shelf tag, slapped onto every receipt. They've been there for over 50 years. And in all that time, they've served exactly one audience: the store's inventory system. No customer has ever scanned a barcode on a box of granola and gotten something useful out of it.

We kept asking ourselves: *what if they could?*

Because the friction is everywhere, and it's kind of absurd once you notice it:

- You pick up a pair of shoes at **Nike** and want to know if your size is in the back room. Your options are: find an employee (good luck), or stand there hoping.
- You grab a box of medication at **Shoppers Drug Mart** and need to check for drug interactions. The font on the packaging is roughly 4pt and you're squinting under fluorescent lighting.
- You're holding a pair of headphones at **Best Buy** and want the full specs. You could read the box, or you could Google it, but both feel like you're doing the store's job for them.
- You're at **Walmart** with a granola bar and your kid has a tree nut allergy. The ingredient list is on the back, in a paragraph, in a font designed for ants.
- You found a lipstick at **Sephora** but want to see how the shade looks on you. The tester is either missing, dried out, or you'd rather not share it with the general public.
- You're at **Baskin-Robbins** staring at a birthday cake and have no idea what's actually in it or how to customize it.

In every single one of these cases, the product is literally in your hands, your intent to buy is real, but the infrastructure completely fails you. The answer should be *on the thing you're already holding*. It isn't.

Meanwhile, App Clips were designed for exactly this kind of moment: zero install, zero login, 30 seconds, one task. The match was, honestly, kind of obvious once we saw it. **The barcode is the trigger. The App Clip is the delivery mechanism. The merchant configures the experience.**

The wildest part? We don't need any new infrastructure. No new QR codes on products. No NFC tags. No custom labels. Every product already has a barcode. We just gave it a consumer-facing purpose for the first time.

---

## Problem Statement

Scanify addresses **In-Store Companion Shopping** — but reframes it.

The original prompt asks how a Clip can help shoppers browse and self-checkout in under 30 seconds. That's a good question, but we asked a different one: what if the product itself *is* the entry point?

Every store already has a universal product identifier on every item. They've had them for 50 years. UPC codes, EAN-13s, the little black-and-white lines we've all been trained to ignore. The infrastructure is already there — nobody had pointed it at the consumer before.

So instead of building one companion shopping experience for one store, we built a **platform** that works at any store, for any product, using the barcodes they already print. One Clip, one scanner, infinite experiences. The store determines what you see when you scan.

We also touch on elements of **AI-Powered Personalization** (context-driven recommendations without login or history) and **Ad-to-Clip Commerce** (the 8-hour push notification window turning real intent data into re-engagement). But at its core, Scanify is about companion shopping — just at a platform level instead of a single-store level.

---

## What It Does

Scanify is a scan-first command center for in-store shopping. You open the Clip, point your phone's camera at a real barcode, and get an experience tailored to that product and that merchant — powered by a live `AVCaptureSession` that reads EAN-13, EAN-8, UPC-E, and Code 128 barcodes in real time.

| Store | Product | Experience | What Happens |
|---|---|---|---|
| **Nike** | Nike P-6000 | Full Shopping Flow | Size/stock check, color picker, add-to-bag, favorites, full checkout — a complete Nike.com experience in a Clip |
| **Walmart** | Nature Valley Granola Bar | Nutrition & Allergen Scan | Allergen flags, nutrition visuals, dietary info, aisle-specific alternatives with product images |
| **Sephora** | Rouge Dior Lipstick | AR Virtual Try-On | Live ARKit face tracking with lip mesh overlay; Vision framework fallback; shade picker with 6 colors |
| **Best Buy** | Sony WH-1000XM5 | Product Intelligence | Warranty coverage breakdown, spec sheets, FAQ, "Customers Also Viewed" with real product images |
| **Shoppers Drug Mart** | Advil Cold & Sinus | Drug Info & Interaction Check | Treatment breakdown, active ingredients, live drug interaction checker with severity grading |
| **Baskin-Robbins** | Birthday Cake | 3D AR Cake Preview | SceneKit 3D cake model rendering with confetti particle effects, allergen info |

### Example Interactions

```
You: *scan Nike P-6000 barcode*
Scanify: Size US 9 — 4 in store. Low stock on US 2.5Y.
         3 colors available. Add to bag?

You: *scan Nature Valley granola bar at Walmart*
Scanify: CONTAINS ALLERGENS: Tree Nuts, Soy.
         Enjoy Life Bars — nut-free, gluten-free — Aisle 7.

You: *scan Sony WH-1000XM5 at Best Buy*
Scanify: 30mm driver · Bluetooth 5.2 · LDAC · 30hr battery · 250g.
         12-month warranty. Covers: defects, battery, mechanical.
         Extend to 3 years for $49.99?

You: *scan Advil Cold & Sinus at Shoppers*
Scanify: Treats: Headache, Sinus Pressure, Congestion.
         ⚠️ SEVERE interaction with Warfarin — increased bleeding risk.
         Generic equivalent: $5.99 (save $7.00) — Aisle 3.

You: *scan Rouge Dior Lipstick at Sephora*
Scanify: 6 shades available. Tap "Try It On" for live AR preview.
         *opens front camera with lip color overlay*
```

---

## The Scanify Customer Journey

We didn't just design the scan. We designed around the full lifecycle of someone walking into a store — from the moment they see the signage to the push notification they get 8 hours later when they're at home and still thinking about that product.

| Stage | What Happens | Trigger | Notification |
|---|---|---|---|
| **Walk In** | Customer sees "Scan any product" signage at store entrance | QR code or NFC tag on signage | — |
| **First Scan** | Points camera at any barcode; store-branded experience loads in under 2 seconds | Barcode on product | — |
| **Interact** | Gets the info they need — allergens, specs, shade match, stock, drug interactions | In-clip UI | — |
| **Purchase** | One-tap Apple Pay checkout, no account needed | Buy button in-clip | — |
| **+15 min** | In-store nudge while they're still shopping | Push notification | Store-specific: allergen report, size availability, spec comparison saved |
| **+2 hr** | Actionable alternative or cross-sell | Push notification | Product recommendation based on what they scanned |
| **+8 hr** | Re-engagement after they've left the store | Push notification | Habit-building or deal alert tied to their specific scan |

The important thing here is that every notification references the **specific product they scanned**. These aren't generic "come back and shop!" messages. They're based on real intent data — you physically picked up a Nature Valley Granola Bar and scanned it. We know what you were looking at, and we can tell you something useful about it hours later.

Traditional retail has literally zero re-engagement path after a customer walks out without buying. None. The relationship ends at the door. Scanify creates one.

---

## Why These 6 Stores

We didn't pick 6 stores to pad the demo. We picked them because each one has a fundamentally different information need when you scan a barcode, and each one pushes a different technical capability. If the same architecture handles all six, it can handle anything:

| Vertical | Store | Core Need | Technical Capability | Why It Matters |
|---|---|---|---|---|
| Grocery | Walmart | Health & safety — allergens, nutrition | Data visualization, product matching | Parents with kids who have allergies can't afford to squint at packaging |
| Apparel | Nike | Availability — size, stock, fit | Full e-commerce flow with cart management | "Is my size in the back?" is the #1 question in any shoe store |
| Beauty | Sephora | Try-before-buy — shade matching | ARKit face tracking + Vision lip detection | Nobody wants to use a shared tester in 2026 |
| Electronics | Best Buy | Decision support — specs, warranty | Structured data display, FAQ, cross-sell | You shouldn't need to Google the product you're standing in front of |
| Pharmacy | Shoppers Drug Mart | Safety — drug interactions, dosage | Live interaction checker with severity grading | Getting drug interaction info shouldn't require a pharmacist consult for every OTC purchase |
| Food Service | Baskin-Robbins | Customization — preview, allergens | SceneKit 3D rendering, particle effects | Allergen info on custom food items is basically nonexistent in-store |

This is what makes Scanify a platform and not a feature. If it only worked at Walmart, it would be a nutrition app. If it only worked at Nike, it would be a stock checker. The fact that one Clip handles all of them — with the same scanner, the same router, the same architecture — is the point.

---

## Deep Dive: What We Actually Built

### Live Barcode Scanner (AVCaptureSession)

This isn't a mockup. We built a real barcode scanner using `AVCaptureSession` and `AVCaptureMetadataOutput` that reads EAN-13, EAN-8, UPC-E, and Code 128 barcodes from the device camera in real time. The scanner includes:

- Live camera preview layer
- Animated scan line (blue gradient, bouncing vertically)
- Composited overlay with dimmed edges and a clear scan window
- Corner brackets drawn with custom `Path` geometry
- Haptic feedback on successful scan (`UIImpactFeedbackGenerator`)
- Duplicate scan prevention with a `hasScanned` flag
- Graceful degradation on simulator (falls back to demo product buttons)

When you scan a real barcode at the demo, what you're seeing is a phone reading an actual physical barcode and routing to the correct experience in under a second.

### ARKit + Vision (Sephora Virtual Try-On)

The Sephora experience includes two separate computer vision implementations for the lip shade try-on:

1. **ARKit Face Tracking** (on devices with TrueDepth camera): Renders a lip mesh overlay using the face anchor's geometry. We use a 62nd-percentile Z-depth algorithm to isolate just the lip surface from the full face mesh, then apply the selected shade color with proper blending.

2. **Vision Framework Fallback** (on devices without face tracking): Uses `VNDetectFaceLandmarksRequest` to detect outer and inner lip landmarks, then draws colored shape overlays mapped to the lip contour in real time.

Both implementations run on the front camera and update live as the user moves. The shade picker offers 6 colors (Rosewood, Berry, 999 Satin, Nude Look, Coral, Plum) with instant switching.

### SceneKit 3D Rendering (Baskin-Robbins)

The Baskin-Robbins experience loads a `.glb` 3D cake model and renders it using SceneKit with:
- Confetti particle effects on reveal
- Celebration text overlay
- Brand-specific pink/blue/brown gradients

### Nike Full E-Commerce Flow (1,997 lines)

The Nike experience isn't just a product card — it's a complete shopping experience:
- **Splash screen** with animated Nike swoosh
- **4-tab navigation**: Shop, Favorites, Bag, Profile
- **Product page**: 4 real product images, size grid with live inventory (in stock / low stock / out of stock), color variants, fit info
- **Bag management**: Add/remove items, quantity adjustment, running total, size and color tracking
- **Favorites**: Heart toggle, persisted within session
- **Checkout flow**: Full order summary with Apple Pay

This is the most complex single experience at nearly 2,000 lines of SwiftUI — and it all loads from a single barcode scan.

### Drug Interaction Checker (Shoppers Drug Mart)

The Shoppers experience includes a live drug interaction checker where users can:
- Type any medication name or tap pre-suggested common drugs (Lisinopril, Vitamin D, Warfarin)
- See interaction severity graded as Mild (yellow), Moderate (orange), or Severe (red)
- Read specific interaction reasons (e.g., "Ibuprofen increases the risk of bleeding when taken with blood thinners")
- View a "safe to take with" list for peace of mind
- Find generic equivalents with price savings and aisle location

---

## Push Notification Strategy (8-Hour Window)

Every time the Clip opens, the 8-hour push notification window activates. Each barcode scan becomes an intent signal. Here's the full notification map:

### Walmart

| Time | Notification |
|---|---|
| **+15 min** | Heads up — Nature Valley Granola Bar contains 2 allergens flagged in your scan. View your full report. |
| **+2 hr** | Enjoy Life Crunchy Bars — allergen-free, same aisle, $1.00 less. Tap to see nutrition breakdown. |
| **+8 hr** | You scanned 1 item today. Build a full allergen-safe grocery list with Scanify at Walmart. |

### Nike

| Time | Notification |
|---|---|
| **+15 min** | Your size is still in stock. Complete your purchase before it sells out. |
| **+2 hr** | Shoppers who scanned this also loved the Pegasus 41. Check it out in-store. |
| **+8 hr** | Your scanned item is now available for same-day delivery. Tap to order from home. |

### Sephora

| Time | Notification |
|---|---|
| **+15 min** | Your shade match is saved. Tap to see how it looks in different lighting. |
| **+2 hr** | 2 complementary products to your shade just went on sale. Build your full look. |
| **+8 hr** | Your scanned item has 4.8 stars from 2,300+ reviews. See what Beauty Insiders are saying. |

### Best Buy

| Time | Notification |
|---|---|
| **+15 min** | Your spec comparison is saved. Tap to review before you leave the store. |
| **+2 hr** | A compatible accessory for your scanned product is 20% off today only. |
| **+8 hr** | Price drop alert: The item you scanned is now $15 less online. Tap to grab it. |

### Shoppers Drug Mart

| Time | Notification |
|---|---|
| **+15 min** | Your medication interaction report is ready. Tap to review potential conflicts. |
| **+2 hr** | A generic alternative costs 40% less. Ask your pharmacist about switching. |
| **+8 hr** | Refill reminder: Based on typical usage, you may need to restock in 28 days. |

### Baskin-Robbins

| Time | Notification |
|---|---|
| **+15 min** | Your cake preview is saved. Tap to customize and order for pickup. |
| **+2 hr** | Add a message or extra toppings to your cake — order in 2 taps. |
| **+8 hr** | Planning another celebration? Your last cake config is saved. Reorder anytime. |

Each set follows a deliberate arc: **immediate value** (15 min, while they're still in-store), **cross-sell or actionable alternative** (2 hr, nudge toward conversion), **re-engagement** (8 hr, bring them back after they've left). None of these are generic. Every single one references the specific product they scanned.

Industry average push notification conversion is 3-5%. But those are usually generic retargeting ("Hey, come back!"). Scanify's notifications are based on *real intent data* — you physically held the product. We estimate 8-12% conversion, conservatively.

---

## How We Built It

We built Scanify on the **Reactiv ClipKit Lab**, a SwiftUI App Clip simulator that runs inside Xcode without needing real App Clip entitlements, Associated Domains, or an Apple Developer account. This let us focus entirely on UX and the platform architecture instead of wrestling with App Clip provisioning profiles.

But we didn't stop at the simulator. We deployed to physical iPhones and built a real `AVCaptureSession` barcode scanner that reads actual barcodes off actual products. The demo isn't simulated — it's a phone pointed at a real barcode.

### Architecture

```
  User opens Clip (QR / NFC / Push notification)
        |
        v
  URL Invocation (scanify.app/:store/scan)
        |
        v
  ClipExperience (protocol conformance)
        |
     Parses storeId, applies merchant branding
        |
        v
  AVCaptureSession Barcode Scanner
  (EAN-13 / EAN-8 / UPC-E / Code 128)
        |
     storeId + barcode
        |
        v
  Experience Router (pure function)
        |
   +----------+----------+-----------+----------+-----------+-----------+
   v          v          v           v          v           v           v
 Shopping   Allergen   AR Try-On   Product   Drug Info   3D Cake    Warranty
  Flow      Scan       (ARKit +   Intel      Checker    (SceneKit)  Register
 (Nike)   (Walmart)   Vision)     (BB)       (SDM)       (BR)        (BB)
                      (Sephora)
```

| Layer | Technology | What It Does |
|---|---|---|
| Entry Point | `ClipExperience` protocol (SwiftUI) | Each store conforms to protocol; parses URL, applies merchant branding |
| Scanner | `AVCaptureSession` + `AVCaptureMetadataOutput` | Live camera barcode reading on device; demo product buttons in simulator |
| Router | Pure function | Maps `(storeId, barcode)` to the correct SwiftUI view and product data |
| AR/Vision | ARKit + Vision + SceneKit | Face tracking lip overlay (Sephora), 3D model rendering (Baskin-Robbins) |
| Experience Views | 6 self-contained SwiftUI experiences | Each manages its own state, presents one interaction, then dismisses back to scanner |
| Shared Components | `ScanifyCheckoutView`, `ScanifyShareSheet` | Reusable checkout flow and share sheet across all experiences |

### Key Design Decisions

**1. Intentionally Stateless**

Scanify has no `UserDefaults`, no files, no accumulated cart. Each barcode scan is an independent, atomic interaction. (Nike's bag is session-scoped — it exists only while the Clip is open, which is by design.)

We considered adding persistent state early on. We rejected it. Persistent state makes this an app, not a clip. The whole point of App Clips is that they don't linger. Every scan is its own 30-second moment.

The Clip Value equation is simple:

```
Clip Value = Intent Signal x Friction Removed
```

We maximized both sides: the intent signal is real (you physically picked up the product), and the friction removed is total (no app, no account, no search).

**2. Real Camera, Real Barcodes**

We didn't fake the scanner. `ScanifyBarcodeScannerView` wraps a real `AVCaptureSession` with `AVCaptureMetadataOutput` that detects EAN-13, EAN-8, UPC-E, and Code 128 barcodes from the rear camera. On simulator, it gracefully falls back to tappable demo product buttons — but on a physical iPhone, you're pointing the camera at a real barcode and getting the experience in under a second. The scanner includes a custom overlay with animated scan line, corner brackets, dimmed edges with a composited clear cutout, and haptic feedback on successful detection.

**3. Store-Specific UI Branding**

Each store gets its own visual identity, and it matters more than you'd think. Walmart gets a blue gradient with the spark logo and a branded loading screen. Nike gets a clean black-on-white layout with an animated swoosh splash. Best Buy gets a dark blue header with their yellow tag accent. Sephora gets an elegant product page inspired by sephora.com. The Clip figures out which branding to apply from the URL — `scanify.app/walmart/scan` gives you Walmart's full visual identity.

This is what makes each experience feel native rather than generic. A customer at Walmart should feel like they're using a Walmart tool, not some third-party app that happens to have Walmart data. The platform disappears and the merchant's brand takes over.

**4. Pure-Function Routing**

The router is a pure function. Input: `storeId` + barcode string. Output: which SwiftUI view to present and which product data to populate it with. No side effects, no state, no dependencies. This means adding a new store or experience type is trivial — you write the view, conform to `ClipExperience`, register it in `SubmissionRegistry`, and everything else (scanner, branding, routing) works automatically.

**5. Dual AR Implementation**

For Sephora's try-on, we didn't just pick one approach. We built two: ARKit face tracking for devices with TrueDepth cameras, and a Vision framework fallback using `VNDetectFaceLandmarksRequest` for everything else. This means the try-on works on every iPhone, not just the ones with Face ID hardware.

---

## What Makes Scanify Different

| Traditional In-Store Experience | Scanify |
|---|---|
| Hunt for a staff member who may or may not exist | Scan the barcode yourself, get instant info |
| Squint at tiny packaging text under fluorescent lights | Clean, visual breakdowns of allergens, specs, ingredients |
| Google the product on your phone (while standing in front of it) | Everything loads in under 2 seconds, no app, no search |
| Use a shared makeup tester (or don't) | AR try-on with your own face, your own phone |
| Hope the pharmacist is free to answer your question | Drug interaction checker with severity grading, instant |
| Store has zero way to re-engage after you walk out | 8-hour push notification window from real intent data |
| Every store needs its own app (that nobody downloads) | One universal Clip works at any participating retailer |

The core insight, and we keep coming back to it because it's genuinely wild to us: **we required zero new infrastructure.** Not a single new thing on the product. Every barcode already exists. We just gave it a purpose it's never had before.

---

## Proposed Platform Extension: Barcode Routing Layer

This is where we go from "hackathon project" to "actual Reactiv product enhancement."

Right now, Reactiv Clips are URL-invoked and URL-determined. The URL tells the Clip what to do. We're proposing a new capability: a **Barcode Routing Layer** that adds post-invocation barcode routing to the platform.

Here's how it would work:

1. **Merchant opens the Reactiv dashboard** and configures barcode prefix mappings to experience templates. For example: "all barcodes starting with `001600` route to the Nutrition & Allergen template."
2. **Product data auto-pulls from their Shopify catalog** via the existing Reactiv-Shopify integration. No manual data entry.
3. **One Clip URL per store, infinite product experiences.** The URL gets you into the Clip. The barcode determines what you see.

This is significant for Reactiv because it expands their addressable market. Right now, Reactiv serves merchants who want a mobile app. With the Barcode Routing Layer, Reactiv serves *any retailer with products on shelves* — which is basically everyone, from Walmart to your local corner store. You don't need to want an app. You just need products with barcodes. (Which, again, is everyone.)

The technical implementation would extend the existing `ClipExperience` protocol with a `barcodeRouter` property that maps barcode prefixes to experience templates, and the Reactiv dashboard would expose a visual mapping editor. We built the client-side routing in our prototype — the dashboard integration is what would make it a real Reactiv feature.

---

## Impact Hypothesis

We think about impact across three dimensions:

**For the consumer:**
Shoppers who physically pick up a product have significantly higher purchase intent than passive browsers. That's not a guess — it's basic retail psychology. If you're holding the product, you're already most of the way to buying it. Scanify captures that intent at the exact moment of decision and removes every friction point between "I'm interested" and "I bought it." No app to download, no account to create, no line to wait in.

**For the merchant:**
- **Primary channel: in-store.** Immediate purchase via Apple Pay, no checkout line, no staff needed. The customer scans, gets info, taps Buy, and it's done.
- **Secondary channel: online recovery.** The 8-hour push notification window turns abandoned in-store interest into online conversions. Someone who scanned but didn't buy at the store gets a targeted, product-specific push notification that links directly to checkout.
- **Revenue shift:** In-venue sales typically require revenue splits with the venue or retailer. Online conversions captured through Scanify's notification window are direct-to-merchant, which means better margins.

**For Reactiv:**
- **Revenue model:** Per-Clip-invocation or monthly SaaS per merchant. Each scan is a measurable event.
- **TAM expansion:** The Barcode Routing Layer moves Reactiv from "merchants who want a mobile app" to "any retailer with products on shelves." That's a fundamentally larger market.
- **Network effects:** More stores with Scanify means more consumers who recognize the pattern — "oh, I can scan this." Adoption compounds.

---

## Challenges We Ran Into

**Building a Real Barcode Scanner During a Hackathon.** We didn't want to fake the core interaction. We built a real `AVCaptureSession` pipeline with `AVCaptureMetadataOutput` that reads EAN-13, EAN-8, UPC-E, and Code 128 barcodes from the device camera. We deployed to physical iPhones and tested with real products. Getting the camera pipeline, barcode detection, overlay compositing, haptic feedback, and experience routing all working end-to-end on a physical device was its own adventure — but it meant the demo is real. When you see the phone scan a barcode, it's actually scanning a barcode.

**Two Separate AR Implementations for Sephora.** ARKit face tracking only works on devices with a TrueDepth camera. We needed the try-on to work everywhere. So we built two implementations: ARKit with face mesh lip isolation (using a 62nd-percentile Z-depth algorithm) for supported devices, and a Vision framework fallback using `VNDetectFaceLandmarksRequest` for everything else. Getting both to feel smooth and natural — with live shade switching across 6 colors — was a significant engineering effort for a hackathon.

**30-Second Constraint Across Six Very Different Experiences.** App Clips need to deliver value in 30 seconds. But our six experience types have wildly different information densities. A Best Buy headphones spec sheet has way more content than a Nike shoe size grid. Solution: we designed each experience around a *completion state*, not a content quantity. The interaction is done when the user has what they need. The 30-second clock is for the critical path, not the total content.

**Nike's 2,000-Line E-Commerce Flow.** We could have shipped a simple product card for Nike. Instead, we built a complete shopping experience with 4-tab navigation, bag management, favorites, size/color selection, and checkout — all within a single Clip. Making it feel like Nike.com in under 15 MB and without any persistent state was the hardest UX challenge. The bag is session-scoped by design.

**Proving a Platform, Not Just a Feature.** AR lip try-on for Sephora and drug interaction checking for Shoppers Drug Mart and 3D cake rendering for Baskin-Robbins have almost nothing in common as user interactions. They look different, they behave differently, they have completely different data shapes and technical requirements. Getting all six to feel native and polished while sharing the same scanner entry point and routing infrastructure was genuinely the hardest part. Disciplined component separation from day one was the only reason it worked.

**Store-Specific Branding That Actually Looks Good.** It's one thing to slap a different color on each store. It's another to make the Walmart Clip actually feel like the Walmart app, with the real logo, the real blue, and a loading animation with the rotating spark. Nike gets an animated swoosh splash screen. Best Buy gets their dark blue and yellow tag branding. We spent a non-trivial amount of time on this because we think it matters — if the Clip feels generic, merchants won't want it. If it feels like theirs, they will.

---

## What We Learned

**The strongest App Clip ideas don't build new infrastructure.** They activate infrastructure that already exists everywhere and give it a consumer-facing purpose for the first time. Barcodes are that infrastructure. They've been on every product for 50 years and nobody had ever thought to point them at the customer. Wild.

**The 30-second constraint is not a limitation — it's the design brief.** Every decision that felt like a tradeoff (no persistent state, session-scoped cart, no account) actually made the product better. When you can't add complexity, you're forced to make every interaction self-contained and complete on its own. That turned out to be the right design anyway.

**Build the real thing, not the mockup.** We could have faked the barcode scanner with tappable cards and called it a day. Building the real `AVCaptureSession` pipeline was harder, but it meant the demo is undeniable. When you see the phone scan a barcode, there's nothing to explain or qualify. It just works.

**Component separation pays off immediately.** Not eventually. Not at scale. Immediately. Six very different experience types sharing one scanner and one router only works if you're disciplined about isolation from the start. We were, and it meant adding a new store was trivial every time.

**Store-specific branding matters more than you'd think.** We almost shipped with a generic blue theme for every store. The Walmart Clip feeling like Walmart and the Nike Clip feeling like Nike is a huge part of why each experience feels native. Merchants won't adopt a tool that makes their brand disappear.

**Barcodes are the most underutilized infrastructure in retail.** 50 years of universal adoption. Every product on every shelf in every store on the planet. And nobody thought to point them at the customer. We still find this genuinely surprising.

---

## What's Next for Scanify

| Feature | Status | Description |
|---|---|---|
| Live `AVCaptureSession` scanner | **Built** | Real-time camera barcode reading on physical devices (EAN-13, EAN-8, UPC-E, Code 128) |
| ARKit + Vision try-on | **Built** | Dual implementation: face tracking lip mesh + Vision landmark fallback |
| SceneKit 3D rendering | **Built** | 3D cake model with particle effects (Baskin-Robbins) |
| Full e-commerce flow | **Built** | 4-tab Nike shopping experience with bag, favorites, checkout |
| Drug interaction checker | **Built** | Live severity-graded interaction lookup (Shoppers Drug Mart) |
| Shopify catalog integration | Planned | Auto-pull product data from a merchant's Shopify store via existing Reactiv integration |
| Barcode Routing Layer for Reactiv | Planned | Merchants configure barcode prefix-to-template mappings in the Reactiv dashboard |
| Real Apple Pay integration | Planned | PassKit integration for one-tap purchase inside any experience sheet |
| Merchant analytics dashboard | Concept | Which products get scanned, drop-off rates, conversion from push notifications |
| Additional retail verticals | Concept | Furniture (AR room placement), automotive (part compatibility), bookstores (reviews and recommendations) |

**The vision:** Any retailer with products on shelves can give their customers a scan-and-interact experience in under a day. No app to build. No custom labels to print. No new infrastructure to install. Just the barcodes they already have, connected to experiences they configure in a dashboard.

---
## Built With

- Swift / SwiftUI 6
- Xcode 26
- AVFoundation (`AVCaptureSession` + `AVCaptureMetadataOutput` for live barcode scanning)
- ARKit (face tracking for Sephora virtual try-on)
- Vision (`VNDetectFaceLandmarksRequest` for lip detection fallback)
- SceneKit (3D cake model rendering for Baskin-Robbins)
- Reactiv ClipKit Lab (App Clip simulator framework)
- No external dependencies (zero SPM packages, zero CocoaPods, zero Carthage)

---
