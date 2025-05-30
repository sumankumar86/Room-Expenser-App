class Expense {
  final dynamic id; // Can be String (MongoDB) or int (SQLite)
  final dynamic userId; // Can be String (MongoDB) or int (SQLite)
  final String description;
  final double amount;
  final DateTime date;
  final dynamic createdBy; // ID of the user who created this expense

  Expense({
    this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    this.createdBy,
  });

  // Convert an Expense into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Create an Expense from a Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? map['_id'],
      userId:
          map['userId'] ??
          (map['user'] is Map ? map['user']['_id'] : map['user']),
      description: map['description'],
      amount:
          map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : map['amount'],
      date: DateTime.parse(map['date']),
      createdBy: map['createdBy'],
    );
  }

  // Create a copy of Expense with some changes
  Expense copyWith({
    dynamic id,
    dynamic userId,
    String? description,
    double? amount,
    DateTime? date,
    dynamic createdBy,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
