class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dateTime;
  final TransactionType type;
  final TransactionStatus status;
  final String iconPath;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dateTime,
    required this.type,
    required this.status,
    required this.iconPath,
  });
}

enum TransactionType {
  ride,
  parcel,
  rental,
  wallet,
}

enum TransactionStatus {
  completed,
  successful,
  pending,
  cancelled,
}

class TransactionFilter {
  final String label;
  final TransactionType? type;

  const TransactionFilter({
    required this.label,
    this.type,
  });

  static const List<TransactionFilter> filters = [
    TransactionFilter(label: 'All'),
    TransactionFilter(label: 'Rides', type: TransactionType.ride),
    TransactionFilter(label: 'Parcels', type: TransactionType.parcel),
    TransactionFilter(label: 'Rental', type: TransactionType.rental),
  ];
}
