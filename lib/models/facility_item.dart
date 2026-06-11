class FacilityItem {
  const FacilityItem({required this.id, required this.name});

  factory FacilityItem.fromJson(Map<String, dynamic> json) {
    return FacilityItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
    );
  }

  final int id;
  final String name;
}
