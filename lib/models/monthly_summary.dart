class MonthlySummary {
  final int month;
  final int year;
  final double totalAmount;
  final int userCount;
  final double perHeadAmount;
  final Map<dynamic, double> userExpenses; // User IDs can be String or int

  MonthlySummary({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.userCount,
    required this.perHeadAmount,
    required this.userExpenses,
  });

  // Create a copy of MonthlySummary with some changes
  MonthlySummary copyWith({
    int? month,
    int? year,
    double? totalAmount,
    int? userCount,
    double? perHeadAmount,
    Map<dynamic, double>? userExpenses,
  }) {
    return MonthlySummary(
      month: month ?? this.month,
      year: year ?? this.year,
      totalAmount: totalAmount ?? this.totalAmount,
      userCount: userCount ?? this.userCount,
      perHeadAmount: perHeadAmount ?? this.perHeadAmount,
      userExpenses: userExpenses ?? this.userExpenses,
    );
  }
}
