class StockEntry {
  final int id;
  final String? name;
  final String? size;
  final int stockIn;
  final int stockOut;
  final String barcode;
  final String category;
  final String subcategory;

  StockEntry({
    required this.id,
    this.name,
    this.size,
    required this.stockIn,
    required this.stockOut,
    required this.barcode,
    required this.category,
    required this.subcategory,
  });

  factory StockEntry.fromMap(Map<String, dynamic> map) => StockEntry(
        id: map['id'],
        name: map['name'],
        size: map['size'],
        stockIn: map['stockIn'],
        stockOut: map['stockOut'],
        barcode: map['barcode'],
        category: map['category'],
        subcategory: map['subcategory'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'size': size,
        'stockIn': stockIn,
        'stockOut': stockOut,
        'barcode': barcode,
        'category': category,
        'subcategory': subcategory,
      };
}
