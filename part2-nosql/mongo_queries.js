// =============================================================================
// MongoDB Operations — part2-nosql/mongo_queries.js
// Database: ecommerce_catalog
// Collection: products
// =============================================================================

// OP1: insertMany() — insert all 3 documents from sample_documents.json
// Inserts the Electronics, Clothing, and Groceries sample products in one
// atomic batch. insertMany() returns an InsertManyResult with insertedIds.
db.products.insertMany([
  {
    _id: "P-ELEC-001",
    category: "Electronics",
    product_name: "Sony WH-1000XM5 Headphones",
    brand: "Sony",
    price: 29999,
    currency: "INR",
    stock_quantity: 85,
    ratings: { average: 4.7, total_reviews: 3241 },
    specifications: {
      connectivity: "Bluetooth 5.2",
      battery_life_hours: 30,
      noise_cancellation: true,
      warranty_years: 2,
      voltage: "5V DC",
      weight_grams: 250,
      frequency_response_hz: { min: 4, max: 40000 }
    },
    certifications: ["BIS", "CE", "FCC"],
    compatible_devices: ["Android", "iOS", "Windows", "macOS"],
    tags: ["wireless", "noise-cancelling", "premium", "over-ear"],
    images: [
      { url: "https://cdn.example.com/products/wh1000xm5_front.jpg", alt: "Front view" },
      { url: "https://cdn.example.com/products/wh1000xm5_side.jpg",  alt: "Side view"  }
    ],
    created_at: new Date("2024-01-10T09:30:00Z"),
    updated_at: new Date("2024-03-15T14:22:00Z")
  },
  {
    _id: "P-CLTH-001",
    category: "Clothing",
    product_name: "Men's Slim Fit Chino Trousers",
    brand: "Arrow",
    price: 2499,
    currency: "INR",
    stock_quantity: 320,
    ratings: { average: 4.2, total_reviews: 987 },
    specifications: {
      material: "98% Cotton, 2% Lycra",
      fit_type: "Slim Fit",
      care_instructions: [
        "Machine wash cold",
        "Do not bleach",
        "Tumble dry low",
        "Iron on medium heat"
      ],
      country_of_origin: "India",
      gender: "Men",
      occasion: ["Casual", "Office", "Semi-formal"]
    },
    available_variants: [
      { size: "30W x 32L", color: "Navy Blue", sku: "ARW-CHN-NB-30-32", stock: 45 },
      { size: "32W x 32L", color: "Navy Blue", sku: "ARW-CHN-NB-32-32", stock: 62 },
      { size: "32W x 34L", color: "Beige",     sku: "ARW-CHN-BG-32-34", stock: 38 },
      { size: "34W x 32L", color: "Olive",     sku: "ARW-CHN-OL-34-32", stock: 29 },
      { size: "36W x 34L", color: "Beige",     sku: "ARW-CHN-BG-36-34", stock: 0  }
    ],
    tags: ["slim-fit", "chino", "casual", "office-wear"],
    images: [
      { url: "https://cdn.example.com/products/chino_front.jpg", alt: "Front view" },
      { url: "https://cdn.example.com/products/chino_back.jpg",  alt: "Back view"  }
    ],
    created_at: new Date("2024-02-01T11:00:00Z"),
    updated_at: new Date("2024-03-10T08:45:00Z")
  },
  {
    _id: "P-GROC-001",
    category: "Groceries",
    product_name: "Aashirvaad Atta (Whole Wheat Flour) 10kg",
    brand: "Aashirvaad",
    price: 399,
    currency: "INR",
    stock_quantity: 1200,
    ratings: { average: 4.5, total_reviews: 18432 },
    specifications: {
      weight_kg: 10,
      form: "Powder",
      shelf_life_days: 180,
      manufactured_date: "2024-01-05",
      expiry_date: "2024-07-04",
      storage_instructions: "Store in a cool, dry place away from direct sunlight",
      country_of_origin: "India",
      fssai_license: "10016011002253"
    },
    nutritional_info_per_100g: {
      energy_kcal: 341,
      protein_g: 12.5,
      carbohydrates_g: 69.4,
      of_which_sugars_g: 1.4,
      dietary_fibre_g: 11.4,
      fat_g: 1.7,
      sodium_mg: 1
    },
    allergens: ["Gluten", "Wheat"],
    certifications: ["FSSAI", "ISO 22000", "Non-GMO"],
    tags: ["atta", "whole-wheat", "staple", "baking", "chapati"],
    images: [
      { url: "https://cdn.example.com/products/atta_10kg_front.jpg", alt: "Front of pack" }
    ],
    created_at: new Date("2024-01-08T07:00:00Z"),
    updated_at: new Date("2024-03-20T10:15:00Z")
  }
]);


// OP2: find() — retrieve all Electronics products with price > 20000
// The query filter matches on both category and the price field.
// The projection (second argument) excludes the internal _id and returns only
// the fields relevant for a product listing page.
db.products.find(
  {
    category: "Electronics",
    price: { $gt: 20000 }
  },
  {
    _id: 0,
    product_name: 1,
    brand: 1,
    price: 1,
    "ratings.average": 1,
    stock_quantity: 1
  }
);


// OP3: find() — retrieve all Groceries expiring before 2025-01-01
// The expiry_date is stored as a string in ISO format (YYYY-MM-DD) inside
// the specifications sub-document. String comparison works correctly for
// ISO dates. In a production system you would store it as an ISODate() for
// proper date indexing.
db.products.find(
  {
    category: "Groceries",
    "specifications.expiry_date": { $lt: "2025-01-01" }
  },
  {
    _id: 0,
    product_name: 1,
    brand: 1,
    "specifications.expiry_date": 1,
    "specifications.shelf_life_days": 1
  }
);


// OP4: updateOne() — add a "discount_percent" field to a specific product
// Targets the Electronics product by its _id. $set adds the new field without
// overwriting any existing fields. $currentDate automatically stamps the
// updated_at field so downstream consumers always know when a document changed.
db.products.updateOne(
  { _id: "P-ELEC-001" },
  {
    $set: {
      discount_percent: 15,
      discounted_price: 25499
    },
    $currentDate: { updated_at: true }
  }
);


// OP5: createIndex() — create an index on the category field
// WHY: category is the single most common filter in all e-commerce queries
// (browse by category, filter by category + price, etc.). Without an index,
// MongoDB performs a full collection scan (COLLSCAN) on every such query,
// which degrades linearly as the catalogue grows.
// An ascending index on category turns those scans into fast IXSCAN lookups
// and also supports compound queries where category is the leading prefix
// (e.g. category + price range in OP2 above).
// The background: true option (pre-MongoDB 4.2 behaviour) or the default
// non-blocking build in 4.2+ ensures existing queries are not blocked while
// the index is being built on a live collection.
db.products.createIndex(
  { category: 1 },
  {
    name: "idx_category_asc",
    background: true,
    comment: "Supports category-based browsing and filtering queries"
  }
);

// Bonus: compound index for OP2's pattern (category + price range lookups)
db.products.createIndex(
  { category: 1, price: 1 },
  {
    name: "idx_category_price",
    comment: "Optimises category + price range queries (e.g. Electronics > 20000)"
  }
);
