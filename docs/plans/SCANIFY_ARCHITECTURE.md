# Scanify — Architecture & Implementation Plan

## The Big Idea

Every physical product already has a barcode. Today, that barcode only talks to the merchant's POS system. Scanify flips the barcode from a merchant-only tool into a **consumer-facing interaction point** — unlocking a universe of contextual, merchant-customizable experiences through a single scan.

No app install. No login. No onboarding. You scan, you get instant value, you put your phone away. That's the App Clip shape — and barcodes are the most ubiquitous physical trigger on the planet.

---

## Problem Framing

### Touchpoints Targeted
- **On-Site / In-Store Interaction** (primary)
- **Purchase / Conversion** (secondary)
- **Re-engagement** (via 8-hour notification window)

### The Friction We're Solving

1. **Information asymmetry in retail** — Shoppers can't get product details without hunting down an employee. Is this in stock in my size? What are the allergens? What's the warranty? The barcode holds the answer, but consumers can't read it.

2. **Barcodes are merchant-locked** — Every product has a barcode. Every barcode maps to a SKU. But consumers get zero value from scanning it. We're unlocking that data for the consumer, customizable by the merchant.

3. **Employee dependency for simple questions** — "Can you check if you have this in a medium?" requires an employee to walk to the back, check inventory, and return. This takes 3-10 minutes and often results in the shopper leaving.

4. **No bridge from in-store discovery to online purchase** — If a store doesn't have your size, the sale is lost. There's no frictionless path from "I'm holding this product" to "ship it to my house in the right size."

### Why This Is a Clip, Not an App

> Would the user install a full app for this? **No.** Nobody installs a store's app just to check if a shirt comes in medium.
> Would the user still want this? **Absolutely.** Scan, see, decide, done.

This is the textbook App Clip shape: physical-digital bridge, zero commitment, instant value, single focused task.

---

## Post-Barcode Interaction Categories

The power of Scanify is that the barcode is the universal key — what it unlocks is entirely customizable by the merchant. Here are the interaction categories:

### Core Interactions (What We'll Build)

| # | Interaction | Vertical | What the Consumer Gets | 30-Second Moment |
|---|-------------|----------|----------------------|------------------|
| 1 | **Inventory & Size Check → Buy Online** | Apparel / Footwear | Real-time stock levels by size/color at this location. If out of stock, one-tap buy-online-ship-to-home with size pre-selected. | Scan tag → see sizes → M is out → tap "Ship M to me" → done |
| 2 | **Allergen & Nutrition Check** | Grocery / Food | Allergen flags front and center (gluten, nuts, dairy, etc.), full nutritional breakdown, dietary compatibility, and aisle-located alternatives if an allergen is flagged. | Scan item → "CONTAINS TREE NUTS" in red → safe/unsafe in 3 seconds |
| 3 | **Medicine Guide + Interaction Check** | Pharmacy / OTC | What does this treat? What does it NOT treat? Enter current medications for an interaction safety check. Suggests safer alternatives if a conflict is found. | Scan box → "Treats: headache, congestion" → check interactions → safe |
| 4 | **AR Virtual Try-On** | Cosmetics / Eyewear | AR camera overlay to preview makeup shades or accessories on your face. Shade picker carousel, real-time face tracking, one-tap buy. | Scan lipstick → camera opens → swipe shades → "that's my color" → buy |
| 5 | **Full Product Intelligence** | Electronics / Tech | Complete product hub: specs (processor, battery, display), warranty info (coverage, registration), and compatible accessories available in this store with aisle locations. One scan, everything you need. | Scan headphones → specs + warranty + "case in aisle 7" → informed decision |

### Extended Interactions (Ideation — Future Scope)

| # | Interaction | Vertical | What the Consumer Gets |
|---|-------------|----------|----------------------|
| 6 | **Origin & Sustainability** | Fashion / Food / Luxury | Supply chain transparency — where it was made, carbon footprint, Fair Trade certification, authenticity verification |
| 7 | **Pairing & Recipes** | Wine / Spirits / Grocery | Food pairing suggestions, cocktail recipes, cooking instructions, sommelier notes |
| 8 | **Fit Guide & Body Match** | Apparel | AI-powered size recommendation based on a quick body measurement flow (height + weight → recommended size) |
| 9 | **Review Snapshot** | Any Consumer Good | Aggregated ratings, top pros/cons, video reviews — instant social proof at the shelf |
| 10 | **Price Comparison** | Any Retail | Real-time price at this store vs. online vs. competitors — merchant-controlled transparency builds trust |
| 11 | **Bundle Builder** | Any Retail | "Customers who bought this also bought..." — cross-sell suggestions with one-tap add-all |
| 12 | **Care Instructions** | Apparel / Furniture / Plants | How to wash, maintain, or care for the product — more detailed than the tiny label |
| 13 | **Assembly & Setup** | Furniture / Electronics | Quick-start guide, assembly video, AR placement preview ("will this couch fit in my room?") |
| 14 | **Medication Info** | Pharmacy | What it treats, interactions, dosage guidance, generic alternatives — scan the box, get clarity |
| 15 | **Gift Mode** | Any Retail | Scan an item → send a gift link to someone → they choose size/color → ships to them |

The point: **the barcode is the universal key. What it unlocks is limitless and merchant-defined.**

---

## Architecture Overview

### System Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     REAL WORLD TRIGGER                       │
│  QR code on shelf / NFC tag / Smart Banner / Apple Maps      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   SCANIFY APP CLIP                           │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              ScanifyScannerExperience                  │  │
│  │   (The entry point — camera-based barcode scanner)     │  │
│  │                                                       │  │
│  │   URL: scanify.app/scan/:storeId                      │  │
│  │   Invocation: QR code at store entrance / shelf end    │  │
│  │                                                       │  │
│  │   1. Opens camera with barcode scanning overlay        │  │
│  │   2. Reads barcode (EAN/UPC) from product              │  │
│  │   3. Looks up barcode in mock product database          │  │
│  │   4. Routes to the appropriate experience view         │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      │                                      │
│                      ▼                                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              ExperienceRouter                          │  │
│  │   (Determines which view to show based on product      │  │
│  │    category returned from barcode lookup)               │  │
│  │                                                       │  │
│  │   ProductCategory → Experience View mapping:           │  │
│  │     .apparel    → InventorySizeView                    │  │
│  │     .food       → NutritionAllergenView                │  │
│  │     .pharmacy   → MedicineGuideView                    │  │
│  │     .cosmetics  → ARTryOnView                          │  │
│  │     .electronics→ ProductIntelligenceView              │  │
│  │     (fallback)  → GenericProductInfoView               │  │
│  └───────────────────┬───────────────────────────────────┘  │
│                      │                                      │
│         ┌────────────┼────────────┬──────────┐              │
│         ▼            ▼            ▼          ▼              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐ │
│  │Inventory │ │Nutrition │ │ Medicine │ │AR Try- │ │ Product  │ │
│  │& Size    │ │& Allergen│ │ Guide    │ │  On    │ │ Intel    │ │
│  │  View    │ │  View    │ │  View    │ │  View  │ │  View    │ │
│  └────┬─────┘ └──────────┘ └──────────┘ └────────┘ └───┬────┘  │
│       │                                      │              │
│       ▼                                      ▼              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              CheckoutBridge                          │   │
│  │   (Shared component — any experience can trigger)     │   │
│  │   "Not in stock? Buy online, ship to your house"      │   │
│  │   Apple Pay / Shopify CheckoutSheet Kit               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              NotificationStrategy                     │   │
│  │   (8-hour window engagement)                          │   │
│  │   Post-scan: "Still thinking about that jacket?       │   │
│  │   It's available in M online — free shipping today."  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
Submissions/scanify/
├── ScanifyScannerExperience.swift      # ClipExperience entry — camera scanner
├── Models/
│   ├── ScannedProduct.swift            # Product data model from barcode lookup
│   ├── ProductCategory.swift           # Enum: .apparel, .food, .pharmacy, .cosmetics, .electronics
│   ├── SizeInventory.swift             # Size + stock count model
│   ├── NutritionData.swift             # Nutritional info + allergens model
│   ├── MedicineData.swift              # Indications, contraindications, interaction data
│   ├── ProductSpec.swift               # Technical specifications model
│   ├── WarrantyInfo.swift              # Warranty terms model
│   └── MockProductDatabase.swift       # Barcode → Product lookup (simulated backend)
├── Views/
│   ├── BarcodeScannerView.swift        # AVFoundation camera overlay for barcode reading
│   ├── ScannerOverlayView.swift        # Animated scanning frame + instructions
│   ├── ExperienceRouter.swift          # Routes ProductCategory → correct detail view
│   ├── InventorySizeView.swift         # Size grid, stock levels, buy-online CTA
│   ├── NutritionAllergenView.swift     # Nutrition facts, allergen badges, dietary flags
│   ├── MedicineGuideView.swift         # What it treats, interactions, alternatives
│   ├── ARTryOnView.swift               # AR camera preview for cosmetics/eyewear
│   ├── ProductIntelligenceView.swift   # Specs + warranty + compatible accessories hub
│   ├── CheckoutBridgeView.swift        # Ship-to-home purchase flow
│   └── GenericProductInfoView.swift    # Fallback for uncategorized products
├── Components/
│   ├── ScanifyHeader.swift             # Branded header with store name
│   ├── AllergenBadge.swift             # Individual allergen indicator (icon + label)
│   ├── SizeButton.swift                # Size selector button (in stock / out of stock states)
│   ├── StockIndicator.swift            # Visual stock level (green/yellow/red)
│   ├── SpecRow.swift                   # Key-value spec display row
│   ├── InteractionAlert.swift          # Drug interaction warning badge
│   └── QuickBuyButton.swift            # "Buy Online — Ship to Me" CTA
└── SUBMISSION.md                       # Completed submission document
```

### Data Flow

```
[Physical Barcode on Product]
         │
         ▼
[AVFoundation Camera Session]
         │ reads EAN-13 / UPC-A code
         ▼
[MockProductDatabase.lookup(barcode:)]
         │ returns ScannedProduct?
         ▼
[ExperienceRouter]
         │ matches product.category
         ▼
[Category-Specific View]
         │ displays contextual info
         │ optionally triggers:
         ▼
[CheckoutBridgeView]  OR  [Notification scheduled]
```

---

## Data Models

### ScannedProduct
```
ScannedProduct
├── barcode: String              # EAN-13 or UPC-A
├── name: String                 # "Nike Air Max 90"
├── brand: String                # "Nike"
├── category: ProductCategory    # .apparel
├── imageURL: String?            # Product image (optional, keep size budget)
├── price: Decimal               # 149.99
├── currency: String             # "CAD"
├── storeId: String              # Which store context
└── categoryData: CategoryData   # Union of category-specific data
```

### CategoryData (enum with associated values)
```
CategoryData
├── .apparel(ApparelData)
│   ├── sizes: [SizeInventory]        # [{size: "S", inStock: 3}, {size: "M", inStock: 0}, ...]
│   ├── colors: [ColorVariant]        # Available colors
│   ├── fit: String                   # "Regular Fit" / "Slim Fit"
│   ├── material: String              # "100% Cotton"
│   └── careInstructions: [String]    # ["Machine wash cold", "Tumble dry low"]
│
├── .food(FoodData)
│   ├── calories: Int
│   ├── servingSize: String
│   ├── macros: Macros                # protein, carbs, fat, fiber
│   ├── allergens: [Allergen]         # [.gluten, .dairy, .treeNuts, ...]
│   ├── dietaryFlags: [DietaryFlag]   # [.vegan, .glutenFree, .kosher, ...]
│   ├── ingredients: [String]
│   └── countryOfOrigin: String?
│
├── .pharmacy(PharmacyData)
│   ├── treats: [String]              # ["Headache", "Sinus pressure", "Nasal congestion"]
│   ├── doesNotTreat: [String]        # ["Cough", "Sore throat", "Fever"]
│   ├── activeIngredients: [Ingredient] # [{name: "Pseudoephedrine", dose: "30mg"}]
│   ├── dosage: String                # "1 tablet every 4-6 hours, max 6/day"
│   ├── warnings: [String]            # ["Do not use with MAOIs", "May cause drowsiness"]
│   ├── interactsWith: [DrugInteraction] # [{drug: "Ibuprofen", severity: .moderate, reason: "..."}]
│   ├── safeWith: [String]            # ["Acetaminophen", "Vitamin D"]
│   ├── ageRestriction: String?       # "Adults and children 12+"
│   └── genericEquivalent: String?    # "Store brand Sinus Relief — $4.99 (save $7)"
│
├── .cosmetics(CosmeticsData)
│   ├── shadeRange: [Shade]           # Color swatches for AR try-on
│   ├── skinType: [String]            # ["Oily", "Combination"]
│   ├── ingredients: [String]         # Full ingredient list
│   ├── arModelAvailable: Bool
│   └── volume: String                # "30ml"
│
└── .electronics(ElectronicsData)
    ├── specs: [SpecItem]             # [{key: "Display", value: "6.7\" OLED"}, ...]
    ├── warranty: WarrantyInfo        # Bundled warranty data (months, type, covers, excludes)
    ├── compatibleAccessories: [Accessory] # [{name: "Case", price: 29.99, aisle: "7"}]
    ├── compatibleWith: [String]      # ["iPhone 16", "iPad Pro"]
    ├── releaseDate: Date?
    └── boxContents: [String]
```

### WarrantyInfo (embedded in ElectronicsData)
```
WarrantyInfo
├── months: Int                       # 12, 24, 36
├── type: String                      # "Manufacturer Limited"
├── covers: [String]                  # ["Defects in materials", "Mechanical failure"]
├── excludes: [String]                # ["Accidental damage", "Normal wear"]
├── extendedTiers: [WarrantyTier]?    # [{name: "Extended", months: 36, price: 49.99}]
└── registrationURL: String?
```

### DrugInteraction
```
DrugInteraction
├── drugName: String                  # "Ibuprofen"
├── severity: Severity                # .mild, .moderate, .severe
└── reason: String                    # "May increase risk of bleeding"
```

### Allergen Enum
```
Allergen (cases)
├── .gluten
├── .dairy
├── .treeNuts
├── .peanuts
├── .soy
├── .eggs
├── .fish
├── .shellfish
├── .sesame
├── .mustard
├── .sulfites
└── .celery

Each has: icon (SF Symbol), label, severity color
```

### DietaryFlag Enum
```
DietaryFlag (cases)
├── .vegan
├── .vegetarian
├── .glutenFree
├── .dairyFree
├── .keto
├── .halal
├── .kosher
├── .organic
└── .nonGMO
```

---

## Mock Product Database

The mock database simulates what would be a real-time API in production. It maps barcodes to `ScannedProduct` objects. We'll create **sample QR codes** that encode these barcodes for demo purposes.

### Sample Products (5 demo items, one per category)

| Barcode | Product | Category | Key Experience |
|---------|---------|----------|----------------|
| `4901234567890` | Nike Dri-FIT Running Tee — Black | Apparel | Size M out of stock → buy online flow |
| `0012345678905` | Nature Valley Granola Bar — Oats & Honey | Food | Contains gluten + tree nuts → allergen alert + alternatives |
| `7891234567890` | Advil Cold & Sinus — 20 tablets | Pharmacy | Treats headache/congestion, NOT cough/fever → interaction check |
| `3456789012345` | Dior Rouge Lipstick — 999 Satin | Cosmetics | AR try-on with shade picker across 6 shades |
| `5678901234567` | Sony WH-1000XM5 Headphones | Electronics | Specs + 1-year warranty + compatible case in aisle 7 |

### QR Code Strategy for Demo

Since we're in the simulator (no real camera), we use two approaches:

1. **Simulator mode**: Tap-to-select from a list of sample barcodes (bypasses camera)
2. **Device mode**: Actual camera scanning of printed/on-screen barcodes

The QR codes we create for demo encode URLs like:
- `scanify.app/scan/demo-store?barcode=4901234567890`

But the *real-world* flow is: QR code at store entrance opens scanner → customer scans product barcodes with camera. The URL only carries the **store context**, not the product. The product comes from the barcode scan.

---

## View-by-View Design

### 1. ScanifyScannerExperience (Entry Point)

**URL Pattern**: `scanify.app/scan/:storeId`

**What it does**:
- Opens a full-screen camera viewfinder with a scanning frame overlay
- In simulator: shows a product picker grid (since there's no camera)
- On device: uses AVFoundation to read EAN/UPC barcodes
- On successful scan, looks up barcode in MockProductDatabase
- Routes to the category-specific experience view

**UI Elements**:
- Scanning frame animation (pulsing border)
- "Point camera at any barcode" instruction text
- Store branding header (from storeId)
- Recent scans quick-access (session only, not persisted)

**Timing**: User should be in a category view within 5 seconds of opening the clip.

### 2. InventorySizeView (Apparel)

**The problem it solves**: "Do you have this in a medium?" is the #1 question in clothing retail. It requires an employee to physically walk to the back room, check stock, and return — a 3-10 minute process. If the answer is "no," the sale is completely lost. There is no bridge from "I'm holding this shirt in-store" to "ship me the right size."

**Why someone would use this**: You're holding a shirt you love. You need a medium. Instead of hunting down a staff member and waiting, you scan the tag and know in 1 second. If they don't have your size, you buy it online right there — same shirt, right size, shipped to your door. The sale is never lost.

**What the user sees after scanning**:
- Product name, brand, and price at the top
- Size grid (XS through XXL) with color-coded stock indicators:
  - Green = on the floor (available now)
  - Yellow = low stock (3 or fewer remaining)
  - Red/grey = unavailable at this location
- Color variant selector (horizontal scroll of color circles)
- Fit info ("Slim Fit") and material ("100% Recycled Polyester")
- **Key CTA when desired size is unavailable**: "Not in store? Get it shipped." → transitions to CheckoutBridgeView with size pre-selected → Apple Pay → done
- Nearby store availability (expandable): "Available in M at Yorkdale — 4.2 km"

**30-second flow**: Scan tag → see size grid → M is red (unavailable) → tap "Ship M to Me" → Apple Pay → "Ships in 2-3 days" → done

### 3. NutritionAllergenView (Food)

**The problem it solves**: 32 million Americans have food allergies. Reading ingredient labels on tiny packaging in a grocery aisle is slow, error-prone, and anxiety-inducing. Allergen labeling varies by brand and country. One missed ingredient can mean an ER visit.

**Why someone would use this**: You're buying a snack for your kid who has a tree nut allergy. Instead of squinting at the back of every package, you scan the barcode and get an instant, unmissable red/green verdict. If the product is unsafe, the Clip suggests an alternative in the same aisle that IS safe.

**What the user sees after scanning**:
- Product name and brand at the top
- **Allergen verdict banner** — large, impossible to miss:
  - Red: "CONTAINS: Gluten, Tree Nuts" with warning icon
  - Green: "No Common Allergens Detected" with checkmark
- Allergen badge grid — each major allergen as a colored capsule (red = present, green = absent): gluten, dairy, tree nuts, peanuts, soy, eggs, fish, shellfish, sesame
- Dietary flag row — small badges for vegan, keto, gluten-free, organic, etc.
- Expandable nutrition facts panel — visual bar chart for calories, protein, carbs, fat, sugar, fiber scaled to daily recommended values
- **"Safer Alternative" section** (shown when allergens flagged) — 1-2 similar products without the flagged allergens, with aisle location: "Try: Enjoy Life Soft Baked Bars (Nut-Free) — Aisle 7"
- Full ingredient list with flagged allergens highlighted in bold red

**30-second flow**: Scan bar → "CONTAINS TREE NUTS" in red → see nut-free alternative in Aisle 7 → put this one back, grab the safe one

### 4. MedicineGuideView (Pharmacy)

**The problem it solves**: The OTC medication aisle is overwhelming. There are 15 different cold medicines and they all look the same. Consumers don't know which one treats their specific symptoms, whether it's safe with their current medications, or whether a $4 generic works the same as the $12 brand name. The pharmacist is a bottleneck — you wait 10 minutes for a 30-second answer.

**Why someone would use this**: You're standing in the pharmacy aisle with a stuffy nose and a headache. You grab Advil Cold & Sinus. Before buying, you scan it. Immediately: "Treats: headache, sinus pressure, nasal congestion. Does NOT treat: cough, sore throat, fever." Now you know this is the right product. You also take blood pressure medication — the Clip checks and says "No known interactions. Safe to take." You buy with confidence. Total time: 10 seconds.

**What the user sees after scanning**:
- Product name, brand, dosage form at the top
- **"What This Treats" section** — green badges listing each symptom: Headache, Sinus Pressure, Nasal Congestion
- **"What This Does NOT Treat" section** — grey badges with strikethrough: ~~Cough~~, ~~Sore Throat~~, ~~Fever~~
- Active ingredients with dosage: "Pseudoephedrine HCl 30mg, Ibuprofen 200mg"
- Dosage instructions: "1 tablet every 4-6 hours. Max 6 per day."
- **Interaction Checker** — text field: "Taking other medications? Enter them to check."
  - User types "Lisinopril" → Clip shows: "MODERATE INTERACTION: Ibuprofen may reduce the effectiveness of blood pressure medications. Consider acetaminophen-based alternatives."
  - Or: user types "Vitamin D" → Clip shows: "No interactions found. Safe to take together." (green checkmark)
- **Generic equivalent callout**: "Same active ingredients for less: Shoppers Brand Sinus Relief — $4.99 (save $7.00)" with aisle location
- Age restriction notice if applicable: "Adults and children 12+ only"

**30-second flow**: Scan box → see "Treats: headache, congestion" → check interaction with my medication → "Safe" → see generic saves $7 → grab generic instead

### 5. ARTryOnView (Cosmetics / Eyewear)

**The problem it solves**: Buying cosmetics is a guessing game. Shade names like "Ruby Woo" or "Velvet Teddy" tell you nothing. Testers are unsanitary or missing. You buy, try at home, and return 40% of the time. Returns cost retailers billions annually and the customer wastes a trip.

**Why someone would use this**: You're at Sephora looking at a Dior lipstick. Instead of guessing which shade works, you scan the barcode and your front camera activates with an AR overlay mapping the exact shade onto your lips. You swipe through 6 shades in 5 seconds. "That's the one." One tap to buy.

**What the user sees after scanning**:
- Product name, shade name ("999 Satin"), and price at the top
- **AR preview area** — large, taking up most of the screen:
  - On real device: front camera with ARKit face tracking, shade mapped onto lip region in real-time
  - In simulator: static mockup image showing a model face with the shade applied, with a "Live on device" badge
- **Shade picker carousel** at the bottom — horizontal scroll of color circles with shade names underneath. Tapping a shade switches the AR overlay (or the mockup image) instantly.
- Product details expandable: skin type compatibility, ingredients, volume
- **"Buy Now" CTA** — transitions to CheckoutBridgeView with selected shade pre-loaded

**30-second flow**: Scan lipstick → camera shows shade on your face → swipe to "Rosewood" → "that's it" → tap Buy Now → Apple Pay → done

### 6. ProductIntelligenceView (Electronics)

**The problem it solves**: Buying electronics in-store means juggling three separate concerns: "What are the specs?", "What's the warranty?", and "What accessories do I need?" Today, each requires a different action — reading a spec sheet, asking staff about warranty, walking to the accessories aisle to find compatible items. This is three trips and three conversations for one purchase decision.

**Why someone would use this**: You're holding a pair of Sony headphones at Best Buy. One scan gives you everything: full specs (driver size, battery life, noise cancellation type, Bluetooth version), warranty info (1-year standard, option to register or extend), and compatible accessories currently in stock at this store with aisle numbers ("Sony carrying case — $29.99, Aisle 7"). One scan, complete picture, confident purchase.

**What the user sees after scanning**:
- Product name, brand, model, price at the top
- **Specs section** — categorized spec rows with SF Symbol icons:
  - Audio: Driver size, Frequency response, ANC type
  - Battery: Playback time, Charge time, Quick charge
  - Connectivity: Bluetooth version, Chip, Supported codecs
  - Physical: Weight, Water resistance, Colors
- **Warranty section** — collapsible card:
  - "1-Year Manufacturer Limited Warranty"
  - Covers / Does Not Cover in two columns
  - "Register Warranty" CTA → email field + Apple Pay for extended tiers
  - Extended tier option: "Extend to 3 years — $49"
- **Compatible Accessories section** — scrollable cards:
  - "Sony WH-1000XM5 Carrying Case — $29.99 — Aisle 7"
  - "Sony USB-C Charging Cable — $14.99 — Aisle 3"
  - Each card has an "Add to list" indicator (no cart — just a visual reminder of what to grab)
- **"What's in the Box"** expandable: Headphones, USB-C cable, 3.5mm audio cable, Carrying pouch

**30-second flow**: Scan headphones → scroll specs → see "1-year warranty, extend to 3 for $49" → note "case in Aisle 7" → grab case on the way to checkout

### 7. CheckoutBridgeView (Shared)

**What it does**:
- Triggered from any experience when user wants to buy online
- Shows product with selected variant (size, color, shade)
- Shipping address via Apple Pay (no manual entry)
- Order confirmation with estimated delivery
- This is where the sale converts from in-store browse to online purchase (higher margin for merchant)

**30-second flow**: "Ship M to my address" → Apple Pay sheet → confirm → "Ships in 2-3 days" → done

---

## 8-Hour Notification Strategy

The notification window is our bridge from in-store browsing to online conversion.

### Notification Timeline

| Timing | Trigger | Message | Goal |
|--------|---------|---------|------|
| +15 min | Scanned apparel but didn't buy | "Still thinking about the Nike Dri-FIT in size M? It ships free today." | Recover abandoned interest |
| +1 hour | Scanned electronics but didn't buy | "The Sony WH-1000XM5 you checked out is $30 off online right now." | Price incentive |
| +3 hours | Scanned multiple items | "You scanned 4 items at Best Buy today. View them all and order from home." | Session recap |
| +6 hours | Evening wind-down | "That Dior lipstick shade you tried on? Free shipping ends at midnight." | Last gentle nudge |
| +7.5 hours | Final window | "Last chance: your personalized store session expires in 30 min." | Urgency + FOMO |

### Key Principle
Every notification deep-links back to the specific product the user scanned, with their selected variant pre-loaded. The re-opened clip shows the product ready to buy, not the scanner again.

---

## How This Maps to App Clip Constraints

| Constraint | How Scanify Respects It |
|---|---|
| **URL invocation** | QR code at store entrance/shelf triggers `scanify.app/scan/:storeId`. The store provides the physical trigger — no new infrastructure needed since stores already have shelf labels and signage. |
| **15 MB size limit** | No bundled product images — loaded from URL or use SF Symbols. No ML models bundled — AR uses on-device ARKit. Minimal asset footprint. |
| **Ephemeral lifecycle** | Zero persistent storage. Product data comes from barcode scan + API lookup every time. No accounts, no saved preferences, no history across sessions. |
| **30-second moment** | Scan → see info → decide. Each experience is designed for a 5-15 second interaction. The checkout bridge adds 10-15 seconds only if the user actively wants to buy. |
| **Single focused task** | One barcode, one product, one piece of information. Not a shopping app. Not a product catalog. Scan this thing, learn about this thing. |
| **8-hour notifications** | Post-scan re-engagement drives online conversions. Every scan is a signal of purchase intent — notifications convert that intent within the window. |
| **No onboarding** | Camera opens immediately. The QR code on the shelf IS the onboarding — it tells you what to do. "Scan any product for instant details." |

---

## Platform Extension Proposal for Reactiv

### New Capability: Barcode-Triggered Experience Routing

**What it is**: A Reactiv platform feature that lets merchants configure barcode-to-experience mappings through the Reactiv dashboard. Instead of each barcode needing its own QR code or URL, merchants connect their existing product catalog (via Shopify sync) and define which experience type each product category gets.

**How it works**:
1. Merchant installs Reactiv on Shopify
2. Product catalog syncs automatically (SKUs, barcodes, inventory, etc.)
3. Merchant configures: "Apparel products → show Sizing & Inventory experience"
4. Merchant places ONE QR code at the store entrance (or per aisle)
5. Customers scan the QR → open scanner → scan any product → get the right experience

**Why this is new**: Today, Reactiv Clips are 1:1 (one URL = one experience). This proposes a **1:many** model where one clip entry point fans out into merchant-defined experiences based on what the consumer scans. The barcode becomes a dynamic router.

**Additional platform features needed**:
- **Real-time inventory API**: Clip queries current stock by store + SKU
- **Merchant experience configurator**: Dashboard UI to map categories → experience templates
- **Analytics**: Which products get scanned most, scan-to-purchase conversion, which experiences drive the most online orders

---

## Implementation Plan (Step-by-Step)

### Phase 1: Foundation (Scanner + Data Layer)

**Step 1: Create submission directory and entry point**
- Run `bash scripts/create-submission.sh "Scanify"`
- Rename the generated experience to `ScanifyScannerExperience`
- Set URL pattern: `scanify.app/scan/:storeId`
- Set touchpoint: `.onSite`
- Set invocationSource: `.qrCode`

**Step 2: Build data models**
- Create `ProductCategory` enum (`.apparel`, `.food`, `.pharmacy`, `.cosmetics`, `.electronics`)
- Create `ScannedProduct` struct with all fields
- Create category-specific data structs (`ApparelData`, `FoodData`, `PharmacyData`, `CosmeticsData`, `ElectronicsData`)
- Create `Allergen`, `DietaryFlag`, and `DrugInteraction` types with display properties
- Create `SizeInventory`, `ColorVariant`, `Shade`, `SpecItem`, `WarrantyInfo`, `Accessory` supporting models

**Step 3: Build MockProductDatabase**
- Static dictionary mapping barcode strings to `ScannedProduct` instances
- Populate with 5 sample products (one per category)
- Include realistic data (real nutritional values, real spec sheets, real size runs)
- Add a `lookup(barcode:)` function that returns `ScannedProduct?`

**Step 4: Build BarcodeScannerView**
- AVFoundation `AVCaptureSession` with `AVMetadataObjectTypeEAN13Code` and `AVMetadataObjectTypeUPCACode`
- `UIViewRepresentable` wrapper for the camera preview
- Scanning frame overlay animation
- **Simulator fallback**: Grid of tappable sample product cards (since simulator has no camera)
- On scan success → call `MockProductDatabase.lookup(barcode:)` → pass result to ExperienceRouter

**Step 5: Build ExperienceRouter**
- Switch on `product.category`
- Route to the appropriate detail view
- Pass the full `ScannedProduct` as a binding
- Handle unknown/missing products with a "Product not found" state

### Phase 2: Experience Views

**Step 6: Build SizingInventoryView**
- Product header (name, brand, price, image placeholder)
- Size grid using `LazyVGrid` — each size button shows stock count
- Color variant horizontal scroll
- Out-of-stock CTA: "Buy Online — Ships to You" button
- Nearby stores expandable section (mock data)

**Step 7: Build NutritionAllergenView**
- Allergen alert banner at top (red/green)
- Allergen badge grid (each allergen as a colored capsule)
- Dietary flag row (vegan, keto, etc.)
- Nutrition facts card (mimicking the standard label format)
- Ingredient list with allergen terms highlighted

**Step 8: Build MedicineGuideView**
- "What This Treats" / "What This Does NOT Treat" badge sections
- Active ingredients and dosage info
- Interaction checker text field with mock validation logic
- Generic equivalent callout with price savings
- Age restriction notice

**Step 9: Build ARTryOnView**
- Shade carousel at bottom
- Camera preview area (ARKit on device, static mockup in simulator)
- Selected shade overlay indicator
- "Buy Now" CTA with shade name

**Step 10: Build ProductIntelligenceView**
- Categorized spec list using `SpecRow` components
- Warranty section (collapsible): coverage, registration, extended tier upsell
- Compatible accessories cards with aisle locations
- "What's in the box" expandable

### Phase 3: Checkout Bridge + Polish

**Step 11: Build CheckoutBridgeView**
- Product summary with selected variant
- Simulated Apple Pay button
- Order confirmation state with animation
- Uses existing `ClipSuccessOverlay` component

**Step 12: Build shared components**
- `ScanifyHeader` — branded top bar with store name from storeId
- `AllergenBadge` — reusable allergen display capsule
- `SizeButton` — size selector with stock state styling
- `StockIndicator` — green/yellow/red dot with count
- `SpecRow` — key-value pair display
- `QuickBuyButton` — "Buy Online" CTA styling

**Step 13: Notification strategy visualization**
- Use `NotificationPreview` component to show sample push notifications
- Display notification timeline on a "what happens after you scan" info sheet
- Accessible from a small info button on the scanner screen

### Phase 4: Demo Flow + Submission

**Step 14: Create demo QR codes**
- Generate QR codes that encode `scanify.app/scan/demo-store?barcode=XXXX` for each sample product
- Include these as images in the submission for judges to scan / reference
- Create a demo script: "Scan this QR → scanner opens → tap Nike Air Max → see sizing → tap Ship to Me → done"

**Step 15: Record demo video**
- Walk through each of the 5 product categories
- Show the scanner → product info → checkout bridge flow
- Show notification previews
- Keep it under 2 minutes

**Step 16: Complete SUBMISSION.md**
- Fill in all 5 required sections
- Include demo video link
- Include architecture diagram reference

---

## Impact Hypothesis

### Which Channel Benefits
**Both in-person and online, with emphasis on online conversion.**

- **In-store**: Scanify eliminates the need for employee assistance for common questions (sizing, stock, specs). This improves the shopping experience and reduces friction that causes walk-aways.
- **Online (primary revenue impact)**: Every out-of-stock moment is currently a lost sale. Scanify converts "we don't have your size" into "we'll ship your size to your house" — right there, right then. This is pure incremental revenue that didn't exist before.

### Conversion Estimates
- **In-store**: ~15-20% of shoppers who ask about size/stock walk away when the answer is "we don't have it." Scanify captures a portion of these as online orders.
- **Online from notification**: Industry average for abandoned cart push notifications is 5-10% conversion. Scanify's notifications are hyper-contextual (specific product the user physically held) — estimated 8-15% conversion.
- **Employee time saved**: Each "can you check the back?" interaction takes 3-10 minutes of employee time. Each "which cold medicine should I get?" question takes pharmacist time. At scale, this is significant labor cost savings.
- **Cosmetics returns reduced**: 40% of cosmetics purchases are returned due to wrong shade. AR try-on lets customers see the shade before buying, significantly cutting return rates.
- **Warranty attach rate**: Warranty registration is painful (forms, cards, websites). Making it a 10-second barcode scan dramatically increases attach rates — high-margin revenue for electronics retailers.

### Why This Touchpoint
The in-store moment is the highest-intent, highest-friction point. The customer is physically holding the product. They've already decided they're interested. The only thing stopping the sale is an information gap (size? stock? ingredients? specs?) or a logistics gap (don't have my size). Scanify closes both gaps instantly.

### Scalability
- **Zero new hardware**: Every product already has a barcode. Stores already have signage. One QR code per store entrance is all that's needed.
- **Merchant self-serve**: Through the Reactiv dashboard, any Shopify merchant can configure their barcode experiences without writing code.
- **Category-agnostic**: The same scanner works for apparel, grocery, electronics, cosmetics, and any future vertical. The barcode is the universal key.
- **Network effects**: As more merchants adopt Scanify, consumers learn the behavior ("I can scan anything"). This drives adoption across verticals.

---

## Competitive Advantage

**Why hasn't this been done?**

1. **App barrier**: Until App Clips, scanning a barcode required installing an app. Nobody downloads "Walmart's barcode scanner app." App Clips remove the install barrier entirely.
2. **Merchant-locked data**: Barcode databases (like GS1) are B2B. Scanify, through Reactiv's Shopify integration, already has access to the merchant's product catalog — including real-time inventory.
3. **No incentive alignment**: Retailers haven't built this because it exposes stock gaps. But Scanify turns stock gaps into online sales — so the incentive flips. Out-of-stock becomes revenue, not embarrassment.

**The pitch to merchants**: "Every barcode in your store is now a buy button. Every out-of-stock is now an online order. One QR code at your entrance. Zero employee training. Revenue from day one."
