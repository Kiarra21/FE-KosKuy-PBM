import '../core/api_config.dart';

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.userPhoto,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawPhoto = '${user['profile_picture'] ?? user['profile_picture_url'] ?? ''}';

    return ReviewItem(
      id: _intValue(json['id']),
      bookingId: _intValue(json['booking_id']),
      userId: _intValue(json['user_id']),
      rating: _intValue(json['rating']),
      comment: '${json['comment'] ?? ''}',
      userName: '${user['name'] ?? 'Pengguna'}',
      userPhoto: rawPhoto.isEmpty ? '' : ApiConfig.storageUrl(rawPhoto),
      createdAt: _dateLabel(json['created_at']),
    );
  }

  final int id;
  final int bookingId;
  final int userId;
  final int rating;
  final String comment;
  final String userName;
  final String userPhoto;
  final String createdAt;

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static String _dateLabel(dynamic value) {
    final raw = '${value ?? ''}';
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class BranchReviewStats {
  const BranchReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.starCounts,
    required this.reviews,
  });

  final double averageRating;
  final int totalReviews;
  final Map<int, int> starCounts;
  final List<ReviewItem> reviews;

  static BranchReviewStats fromReviews(List<ReviewItem> reviews) {
    if (reviews.isEmpty) {
      return const BranchReviewStats(
        averageRating: 0,
        totalReviews: 0,
        starCounts: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        reviews: [],
      );
    }
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var total = 0;
    for (final review in reviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
      total += review.rating;
    }
    return BranchReviewStats(
      averageRating: total / reviews.length,
      totalReviews: reviews.length,
      starCounts: counts,
      reviews: reviews,
    );
  }
}
