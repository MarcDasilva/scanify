import SwiftUI

// MARK: - Color Extension

extension Color {
    init(scanifyHex hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Product Category

enum ProductCategory: String, CaseIterable {
    case apparel = "Apparel"
    case food = "Food"
    case pharmacy = "Pharmacy"
    case cosmetics = "Cosmetics"
    case electronics = "Electronics"

    var icon: String {
        switch self {
        case .apparel: return "tshirt.fill"
        case .food: return "carrot.fill"
        case .pharmacy: return "pill.fill"
        case .cosmetics: return "paintbrush.fill"
        case .electronics: return "headphones"
        }
    }

    var accentColor: Color {
        switch self {
        case .apparel: return .blue
        case .food: return .green
        case .pharmacy: return .red
        case .cosmetics: return .pink
        case .electronics: return .purple
        }
    }
}

// MARK: - Scanned Product

struct ScannedProduct: Identifiable {
    let id = UUID()
    let barcode: String
    let name: String
    let brand: String
    let category: ProductCategory
    let price: Double
    let currency: String
    let categoryData: CategoryData
    var imageName: String? = nil
}

// MARK: - Category Data

enum CategoryData {
    case apparel(ApparelData)
    case food(FoodData)
    case pharmacy(PharmacyData)
    case cosmetics(CosmeticsData)
    case electronics(ElectronicsData)
}

// MARK: - Apparel

struct ApparelData {
    let sizes: [SizeInventory]
    let colors: [ColorVariant]
    let fit: String
    let material: String
}

struct SizeInventory: Identifiable {
    let id = UUID()
    let size: String
    let inStock: Int

    var stockStatus: StockStatus {
        if inStock == 0 { return .outOfStock }
        if inStock <= 3 { return .lowStock }
        return .inStock
    }
}

enum StockStatus {
    case inStock, lowStock, outOfStock

    var color: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        }
    }
}

struct ColorVariant: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
}

// MARK: - Food

struct FoodData {
    let calories: Int
    let servingSize: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let sugar: Double
    let fiber: Double
    let allergens: [Allergen]
    let dietaryFlags: [DietaryFlag]
    let ingredients: [String]
    let alternative: AlternativeProduct?
}

struct AlternativeProduct {
    let name: String
    let reason: String
    let aisle: String
    var imageName: String? = nil
}

enum Allergen: String, CaseIterable, Identifiable {
    case gluten = "Gluten"
    case dairy = "Dairy"
    case treeNuts = "Tree Nuts"
    case peanuts = "Peanuts"
    case soy = "Soy"
    case eggs = "Eggs"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case sesame = "Sesame"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gluten: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .treeNuts: return "tree.fill"
        case .peanuts: return "allergens.fill"
        case .soy: return "leaf.arrow.circlepath"
        case .eggs: return "oval.fill"
        case .fish: return "fish.fill"
        case .shellfish: return "tortoise.fill"
        case .sesame: return "circle.grid.3x3.fill"
        }
    }
}

enum DietaryFlag: String, CaseIterable, Identifiable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case keto = "Keto"
    case organic = "Organic"
    case nonGMO = "Non-GMO"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vegan: return "leaf.fill"
        case .vegetarian: return "leaf.fill"
        case .glutenFree: return "xmark.circle.fill"
        case .dairyFree: return "xmark.circle.fill"
        case .keto: return "flame.fill"
        case .organic: return "leaf.circle.fill"
        case .nonGMO: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Pharmacy

struct PharmacyData {
    let treats: [String]
    let doesNotTreat: [String]
    let activeIngredients: [Ingredient]
    let dosage: String
    let warnings: [String]
    let interactions: [DrugInteraction]
    let safeWith: [String]
    let ageRestriction: String?
    let genericEquivalent: GenericEquivalent?
}

struct Ingredient {
    let name: String
    let dose: String
}

struct DrugInteraction: Identifiable {
    let id = UUID()
    let drugName: String
    let severity: InteractionSeverity
    let reason: String
}

enum InteractionSeverity: String {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var color: Color {
        switch self {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct GenericEquivalent {
    let name: String
    let price: Double
    let savings: Double
    let aisle: String
}

// MARK: - Cosmetics

struct CosmeticsData {
    let shades: [Shade]
    let skinTypes: [String]
    let volume: String
}

struct Shade: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
}

// MARK: - Electronics

struct ElectronicsData {
    let specCategories: [SpecCategory]
    let warranty: WarrantyInfo
    let compatibleAccessories: [Accessory]
    let compatibleWith: [String]
    let boxContents: [String]
}

struct SpecCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let specs: [SpecItem]
}

struct SpecItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

struct WarrantyInfo {
    let months: Int
    let type: String
    let covers: [String]
    let excludes: [String]
    let extendedPrice: Double?
    let extendedMonths: Int?
}

struct Accessory: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let aisle: String
    let icon: String
}

// MARK: - Store Branding

struct StoreBranding {
    let storeId: String
    let displayName: String
    let icon: String
    let accentColor: Color
    let category: ProductCategory

    static let stores: [String: StoreBranding] = [
        "sephora": StoreBranding(storeId: "sephora", displayName: "Sephora", icon: "sparkles", accentColor: .pink, category: .cosmetics),
        "nike": StoreBranding(storeId: "nike", displayName: "Nike", icon: "figure.run", accentColor: .orange, category: .apparel),
        "walmart": StoreBranding(storeId: "walmart", displayName: "Walmart", icon: "cart.fill", accentColor: .blue, category: .food),
        "shoppers-drug-mart": StoreBranding(storeId: "shoppers-drug-mart", displayName: "Shoppers Drug Mart", icon: "cross.case.fill", accentColor: .red, category: .pharmacy),
        "best-buy": StoreBranding(storeId: "best-buy", displayName: "Best Buy", icon: "bolt.fill", accentColor: .yellow, category: .electronics),
    ]

    static let `default` = StoreBranding(storeId: "store", displayName: "Store", icon: "storefront.fill", accentColor: .blue, category: .food)

    static func forStoreId(_ id: String) -> StoreBranding {
        stores[id.lowercased()] ?? .default
    }
}

// MARK: - Mock Product Database

enum ScanifyMockData {
    static func lookup(barcode: String) -> ScannedProduct? {
        // Trim whitespace (real barcodes can have trailing/leading space)
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        if let product = products[trimmed] {
            return product
        }
        let lower = trimmed.lowercased()
        return products.first(where: { $0.key.lowercased() == lower })?.value
    }

    static let allProducts: [ScannedProduct] = Array(products.values)

    /// Products valid for a given store (by store's primary category). Used for company-specific clips.
    static func products(for storeId: String) -> [ScannedProduct] {
        let category = StoreBranding.forStoreId(storeId).category
        return allProducts.filter { $0.category == category }
    }

    private static let products: [String: ScannedProduct] = [
        // Word-based barcode keys (for printed demo barcodes)
        "Sephora": cosmeticsProduct,
        "Nike": nikeShoeProduct,
        "NIKE": nikeShoeProduct,
        "nike": nikeShoeProduct,
        "P6000": nikeShoeProduct,
        "Nike P-6000": nikeShoeProduct,
        "Tee": apparelProduct,
        "Walmart": foodProduct,
        "Shoppers": pharmacyProduct,
        "Best Buy": electronicsProduct,

        // Numeric barcode keys
        "4901234567890": nikeShoeProduct,
        "4901234567891": apparelProduct,
        "0012345678905": foodProduct,
        "7891234567890": pharmacyProduct,
        "3456789012345": cosmeticsProduct,
        "5678901234567": electronicsProduct,
    ]

    // MARK: - Product Definitions

    private static let apparelProduct = ScannedProduct(
        barcode: "Tee",
        name: "Dri-FIT Running Tee",
        brand: "Nike",
        category: .apparel,
        price: 45.00,
        currency: "CAD",
        categoryData: .apparel(ApparelData(
            sizes: [
                SizeInventory(size: "XS", inStock: 5),
                SizeInventory(size: "S", inStock: 8),
                SizeInventory(size: "M", inStock: 0),
                SizeInventory(size: "L", inStock: 2),
                SizeInventory(size: "XL", inStock: 12),
                SizeInventory(size: "XXL", inStock: 6),
            ],
            colors: [
                ColorVariant(name: "Black", hex: "#1C1C1E"),
                ColorVariant(name: "Navy", hex: "#1A3A5C"),
                ColorVariant(name: "White", hex: "#F5F5F5"),
            ],
            fit: "True to Size",
            material: "Breathable Mesh"
        ))
    )

    /// Nike P-6000 shoe — barcode "Nike" resolves here
    private static let nikeShoeProduct = ScannedProduct(
        barcode: "P6000",
        name: "Nike P-6000",
        brand: "Nike",
        category: .apparel,
        price: 105.00,
        currency: "CAD",
        categoryData: .apparel(ApparelData(
            sizes: [
                SizeInventory(size: "US 1Y", inStock: 2),
                SizeInventory(size: "US 1.5Y", inStock: 0),
                SizeInventory(size: "US 2Y", inStock: 3),
                SizeInventory(size: "US 2.5Y", inStock: 1),
                SizeInventory(size: "US 3Y", inStock: 4),
                SizeInventory(size: "US 7", inStock: 3),
                SizeInventory(size: "US 8.5", inStock: 5),
                SizeInventory(size: "US 9", inStock: 4),
            ],
            colors: [
                ColorVariant(name: "White", hex: "#F5F5F5"),
                ColorVariant(name: "Black", hex: "#1C1C1E"),
                ColorVariant(name: "Navy", hex: "#1A3A5C"),
            ],
            fit: "True to Size",
            material: "Synthetic Leather"
        ))
    )

    private static let foodProduct = ScannedProduct(
        barcode: "Walmart",
        name: "Granola Bar — Oats & Honey",
        brand: "Nature Valley",
        category: .food,
        price: 4.99,
        currency: "CAD",
        categoryData: .food(FoodData(
            calories: 190,
            servingSize: "2 bars (42g)",
            protein: 4,
            carbs: 29,
            fat: 7,
            sugar: 12,
            fiber: 2,
            allergens: [.gluten, .treeNuts],
            dietaryFlags: [.vegetarian],
            ingredients: [
                "Whole Grain Oats", "Sugar", "Canola Oil", "Yellow Corn Flour",
                "Honey", "Soy Lecithin", "Almonds", "Salt",
                "Baking Soda", "Natural Flavor"
            ],
            alternative: AlternativeProduct(
                name: "Enjoy Life Soft Baked Bars (Nut-Free, Gluten-Free)",
                reason: "Free from tree nuts & gluten",
                aisle: "Aisle 7",
                imageName: "walmart_granola_alt"
            )
        )),
        imageName: "walmart_granola_bar"
    )

    private static let pharmacyProduct = ScannedProduct(
        barcode: "Shoppers",
        name: "Cold & Sinus — 10 caplets",
        brand: "Advil",
        category: .pharmacy,
        price: 12.99,
        currency: "CAD",
        categoryData: .pharmacy(PharmacyData(
            treats: ["Headache", "Sinus Pressure", "Nasal Congestion", "Body Aches"],
            doesNotTreat: ["Cough", "Sore Throat", "Fever", "Runny Nose"],
            activeIngredients: [
                Ingredient(name: "Ibuprofen", dose: "200mg"),
                Ingredient(name: "Pseudoephedrine HCl", dose: "30mg"),
            ],
            dosage: "1 tablet every 4-6 hours. Max 6 per day.",
            warnings: ["Do not use with other NSAIDs", "May cause drowsiness"],
            interactions: [
                DrugInteraction(
                    drugName: "Lisinopril",
                    severity: .moderate,
                    reason: "Ibuprofen may reduce the effectiveness of ACE inhibitors (blood pressure medications). Consider acetaminophen-based alternatives."
                ),
                DrugInteraction(
                    drugName: "Warfarin",
                    severity: .severe,
                    reason: "Ibuprofen increases the risk of bleeding when taken with blood thinners. Do not use without consulting your doctor."
                ),
                DrugInteraction(
                    drugName: "Aspirin",
                    severity: .moderate,
                    reason: "Taking ibuprofen with aspirin may reduce aspirin's cardioprotective effects and increase stomach bleeding risk."
                ),
            ],
            safeWith: ["Acetaminophen", "Vitamin D", "Vitamin C", "Melatonin", "Zinc"],
            ageRestriction: "Adults and children 12+ only",
            genericEquivalent: GenericEquivalent(
                name: "Shoppers Brand Sinus Relief",
                price: 5.99,
                savings: 7.00,
                aisle: "Aisle 3"
            )
        ))
    )

    private static let cosmeticsProduct = ScannedProduct(
        barcode: "Sephora",
        name: "Rouge Dior Lipstick",
        brand: "Dior",
        category: .cosmetics,
        price: 52.00,
        currency: "CAD",
        categoryData: .cosmetics(CosmeticsData(
            shades: [
                Shade(name: "Rosewood", hex: "#9E4244"),
                Shade(name: "Berry", hex: "#8B2252"),
                Shade(name: "999 Satin", hex: "#C41E3A"),
                Shade(name: "Nude Look", hex: "#C08081"),
                Shade(name: "Coral", hex: "#E8737A"),
                Shade(name: "Plum", hex: "#6B3A4E"),
            ],
            skinTypes: ["All skin types"],
            volume: "3.5g"
        ))
    )

    // "Also viewed" products for Best Buy
    static let xm6Product = ScannedProduct(
        barcode: "BB-XM6",
        name: "WH-1000XM6 Headphones",
        brand: "Sony",
        category: .electronics,
        price: 549.99,
        currency: "CAD",
        categoryData: .electronics(ElectronicsData(
            specCategories: [
                SpecCategory(name: "Audio", icon: "waveform", specs: [
                    SpecItem(key: "Driver", value: "32mm Carbon Fiber"),
                    SpecItem(key: "Frequency", value: "4Hz - 40kHz"),
                    SpecItem(key: "ANC", value: "Auto NC Optimizer 2.0"),
                    SpecItem(key: "Codec", value: "LDAC, AAC, LC3"),
                ]),
                SpecCategory(name: "Battery", icon: "battery.100", specs: [
                    SpecItem(key: "Playback", value: "40 hours (ANC on)"),
                    SpecItem(key: "Charge Time", value: "3 hours"),
                    SpecItem(key: "Quick Charge", value: "3 min = 6 hours"),
                ]),
            ],
            warranty: WarrantyInfo(months: 12, type: "Manufacturer Limited", covers: ["Defects in materials", "Mechanical failure"], excludes: ["Accidental damage", "Water damage"], extendedPrice: 59.99, extendedMonths: 36),
            compatibleAccessories: [],
            compatibleWith: ["iPhone 16", "iPad Pro", "MacBook Air", "Android devices", "PS5"],
            boxContents: ["WH-1000XM6 Headphones", "USB-C cable", "3.5mm cable", "Carrying case"]
        )),
        imageName: "bestbuy_xm6"
    )

    static let airpodsMaxProduct = ScannedProduct(
        barcode: "BB-APM",
        name: "AirPods Max (USB-C)",
        brand: "Apple",
        category: .electronics,
        price: 779.00,
        currency: "CAD",
        categoryData: .electronics(ElectronicsData(
            specCategories: [
                SpecCategory(name: "Audio", icon: "waveform", specs: [
                    SpecItem(key: "Driver", value: "40mm Apple"),
                    SpecItem(key: "Chip", value: "H2"),
                    SpecItem(key: "ANC", value: "Active Noise Cancellation"),
                    SpecItem(key: "Spatial", value: "Personalized Spatial Audio"),
                ]),
                SpecCategory(name: "Battery", icon: "battery.100", specs: [
                    SpecItem(key: "Playback", value: "20 hours"),
                    SpecItem(key: "Charge", value: "USB-C"),
                ]),
            ],
            warranty: WarrantyInfo(months: 12, type: "Apple Limited", covers: ["Defects in materials", "Battery"], excludes: ["Accidental damage"], extendedPrice: 59.00, extendedMonths: 24),
            compatibleAccessories: [],
            compatibleWith: ["iPhone 16", "iPad Pro", "MacBook Air", "Apple TV", "Apple Watch"],
            boxContents: ["AirPods Max", "Smart Case", "USB-C to Lightning cable"]
        )),
        imageName: "bestbuy_airpods_max"
    )

    private static let electronicsProduct = ScannedProduct(
        barcode: "Best Buy",
        name: "WH-1000XM5 Headphones",
        brand: "Sony",
        category: .electronics,
        price: 449.99,
        currency: "CAD",
        categoryData: .electronics(ElectronicsData(
            specCategories: [
                SpecCategory(name: "Audio", icon: "waveform", specs: [
                    SpecItem(key: "Driver", value: "30mm"),
                    SpecItem(key: "Frequency", value: "4Hz - 40kHz"),
                    SpecItem(key: "ANC", value: "Auto NC Optimizer"),
                    SpecItem(key: "Codec", value: "LDAC, AAC, SBC"),
                ]),
                SpecCategory(name: "Battery", icon: "battery.100", specs: [
                    SpecItem(key: "Playback", value: "30 hours (ANC on)"),
                    SpecItem(key: "Charge Time", value: "3.5 hours"),
                    SpecItem(key: "Quick Charge", value: "3 min = 3 hours"),
                ]),
                SpecCategory(name: "Connectivity", icon: "wifi", specs: [
                    SpecItem(key: "Bluetooth", value: "5.2"),
                    SpecItem(key: "Chip", value: "V1 Integrated Processor"),
                    SpecItem(key: "Multipoint", value: "Yes (2 devices)"),
                ]),
                SpecCategory(name: "Physical", icon: "scalemass", specs: [
                    SpecItem(key: "Weight", value: "250g"),
                    SpecItem(key: "Water Resistance", value: "None"),
                    SpecItem(key: "Foldable", value: "No (flat-swivel)"),
                ]),
            ],
            warranty: WarrantyInfo(
                months: 12,
                type: "Manufacturer Limited",
                covers: ["Defects in materials", "Mechanical failure", "Battery defects"],
                excludes: ["Accidental damage", "Water damage", "Normal wear & tear"],
                extendedPrice: 49.99,
                extendedMonths: 36
            ),
            compatibleAccessories: [
                Accessory(name: "WH-1000XM5 Carrying Case", price: 29.99, aisle: "Aisle 7", icon: "bag.fill"),
                Accessory(name: "Sony USB-C Charging Cable (2m)", price: 14.99, aisle: "Aisle 3", icon: "cable.connector"),
                Accessory(name: "Replacement Ear Pads", price: 24.99, aisle: "Aisle 7", icon: "headphones"),
            ],
            compatibleWith: ["iPhone 16", "iPad Pro", "MacBook Air", "Android devices", "PS5", "Nintendo Switch"],
            boxContents: ["WH-1000XM5 Headphones", "USB-C charging cable", "3.5mm audio cable", "Carrying case", "Airplane adapter"]
        )),
        imageName: "bestbuy_xm5"
    )
}
