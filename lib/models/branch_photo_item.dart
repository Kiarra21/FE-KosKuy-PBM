import '../core/api_config.dart';

class BranchPhotoItem {
  const BranchPhotoItem({
    required this.id,
    required this.url,
    required this.order,
  });

  factory BranchPhotoItem.fromJson(Map<String, dynamic> json) {
    final path = '${json['photo_url'] ?? json['photo'] ?? ''}';
    return BranchPhotoItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      url: path.isEmpty ? '' : ApiConfig.storageUrl(path),
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse('${json['order']}') ?? 0,
    );
  }

  final int id;
  final String url;
  final int order;
}
