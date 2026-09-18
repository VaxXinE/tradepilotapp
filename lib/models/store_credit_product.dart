const storeCreditProducts = <String, int>{
  'id.tradepilot.app.credits.20': 20,
  'id.tradepilot.app.credits.40': 40,
  'id.tradepilot.app.credits.60': 60,
  'id.tradepilot.app.credits.80': 80,
};

final storeCreditProductIds = storeCreditProducts.keys.toSet();

int? creditsForStoreProduct(String productId) => storeCreditProducts[productId];
