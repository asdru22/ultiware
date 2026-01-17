class Trade {
  final String id;
  final DateTime date;
  final List<String> givenItemIds;
  final List<String> receivedItemIds;

  Trade({
    required this.id,
    required this.date,
    required this.givenItemIds,
    required this.receivedItemIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'givenItemIds': givenItemIds,
      'receivedItemIds': receivedItemIds,
    };
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      date: DateTime.parse(json['date']),
      givenItemIds: List<String>.from(json['givenItemIds']),
      receivedItemIds: List<String>.from(json['receivedItemIds']),
    );
  }
}
