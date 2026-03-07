import 'package:grocery_app/models/product_model.dart';

void main() {
  final shops = DummyData.shopsWithinRange(2);
  final products = DummyData.productsWithinRange(2);
  print('shops2=${shops.map((e) => e.name).toList()}');
  print('products2_count=${products.length}');
  print(products.map((p) => '${p.name} @ ${p.seller}').toList());
  print('all_count=${DummyData.products.length}');
}
