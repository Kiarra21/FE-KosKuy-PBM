import '../core/api_config.dart';

class BookingItem {
  const BookingItem({
    required this.id,
    required this.reviewBookingId,
    required this.branchId,
    required this.kosName,
    required this.roomLabel,
    required this.price,
    required this.total,
    required this.totalPriceRaw,
    required this.durationLabel,
    required this.status,
    required this.paymentDeadline,
    required this.qrisCodeUrl,
    required this.checkInDate,
    required this.checkOutDate,
    required this.notes,
    required this.hasReview,
    required this.reviewRating,
    required this.reviewComment,
    required this.reviewCreatedAt,
    required this.paymentProofUrl,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final room = (json['room'] as Map?)?.cast<String, dynamic>() ?? {};
    final booking = (json['booking'] as Map?)?.cast<String, dynamic>() ?? {};
    final roomType =
        (json['room_type'] as Map?)?.cast<String, dynamic>() ??
        (room['room_type'] as Map?)?.cast<String, dynamic>() ??
        (booking['room_type'] as Map?)?.cast<String, dynamic>() ??
        {};
    final branch =
        (json['branch'] as Map?)?.cast<String, dynamic>() ??
        (booking['branch'] as Map?)?.cast<String, dynamic>() ??
        (roomType['branch'] as Map?)?.cast<String, dynamic>() ??
        {};
    final roomTypeName =
        '${roomType['name'] ?? json['room_type_name'] ?? json['type'] ?? 'Kamar'}';
    final roomCount = _intValue(json['room_count'] ?? json['rooms_count'] ?? 1);
    final duration = _durationLabel(json);

    final rawQris =
        '${json['qris_code_url'] ?? json['qris_url'] ?? json['branch_qris_code_url'] ?? json['branch_qris_url'] ?? json['qris_code'] ?? json['qris'] ?? booking['qris_code_url'] ?? booking['qris_url'] ?? booking['branch_qris_code_url'] ?? booking['branch_qris_url'] ?? booking['qris_code'] ?? booking['qris'] ?? branch['qris_code_url'] ?? branch['qris_url'] ?? branch['qris_code'] ?? branch['qris'] ?? ''}';
    final qrisUrl = rawQris.isEmpty ? '' : ApiConfig.storageUrl(rawQris);

    // Bukti pembayaran
    final payment = (json['payment'] as Map?)?.cast<String, dynamic>();
    final rawProof = '${payment?['proof_image_url'] ?? ''}';
    final proofUrl = rawProof.isEmpty ? '' : ApiConfig.storageUrl(rawProof);

    // Harga total mentah
    final rawTotal = json['total'] ?? json['total_price'] ?? json['amount'];
    final totalPriceRaw = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse('$rawTotal') ?? 0.0;

    return BookingItem(
      id: _intValue(json['id']),
      reviewBookingId: _intValue(
        json['booking_id'] ?? booking['id'] ?? json['id'],
      ),
      branchId: _intValue(
        json['branch_id'] ??
            booking['branch_id'] ??
            branch['id'] ??
            roomType['branch_id'],
      ),
      kosName:
          '${json['kos_name'] ?? json['branch_name'] ?? booking['branch_name'] ?? branch['name'] ?? roomType['name'] ?? 'KosKuy'}',
      roomLabel: '$roomCount Kamar, $roomTypeName',
      price: _rupiah(json['price'] ?? json['room_price'] ?? roomType['price']),
      total: _rupiah(rawTotal),
      totalPriceRaw: totalPriceRaw,
      durationLabel: duration,
      status: _statusLabel('${json['display_status'] ?? json['status'] ?? ''}'),
      paymentDeadline: _dateLabel(
        json['payment_deadline'] ??
            json['expired_at'] ??
            json['expires_at'] ??
            json['pay_before'],
      ),
      qrisCodeUrl: qrisUrl,
      checkInDate: _dateLabel(
        json['check_in_date'] ?? json['check_in'] ?? json['start_date'],
      ),
      checkOutDate: _dateLabel(
        json['check_out_date'] ?? json['check_out'] ?? json['end_date'],
      ),
      notes: '${json['notes'] ?? ''}',
      hasReview: json['review'] != null,
      reviewRating: _intValue((json['review'] as Map?)?['rating']),
      reviewComment: '${(json['review'] as Map?)?['comment'] ?? ''}',
      reviewCreatedAt: _dateLabel((json['review'] as Map?)?['created_at']),
      paymentProofUrl: proofUrl,
    );
  }

  final int id;
  final int reviewBookingId;
  final int branchId;
  final String kosName;
  final String roomLabel;
  final String price;
  final String total;
  final double totalPriceRaw;
  final String durationLabel;
  final String status;
  final String paymentDeadline;
  final String qrisCodeUrl;
  final String checkInDate;
  final String checkOutDate;
  final String notes;
  final bool hasReview;
  final int reviewRating;
  final String reviewComment;
  final String reviewCreatedAt;
  final String paymentProofUrl;

  bool get isCompleted => status == 'Selesai';
  bool get isPaid => status == 'Lunas' || isConfirmed || isCompleted;
  bool get isCancelled => status == 'Dibatalkan';
  bool get isConfirmed => status == 'Dikonfirmasi';
  bool get isWaitingVerification => status == 'Menunggu Verifikasi';
  bool get isUnpaid => status == 'Belum Bayar';

  bool get isActive =>
      isUnpaid || isWaitingVerification || status == 'Lunas' || isConfirmed;

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static String _statusLabel(String value) {
    if (value == 'Dibatalkan' ||
        value == 'Selesai' ||
        value == 'Dikonfirmasi' ||
        value == 'Menunggu Verifikasi' ||
        value == 'Lunas' ||
        value == 'Belum Bayar') {
      return value;
    }

    // Fallback logic
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('paid') ||
        normalized.contains('lunas') ||
        normalized.contains('success')) {
      return 'Lunas';
    }
    if (normalized.contains('completed') || normalized.contains('selesai')) {
      return 'Selesai';
    }
    if (normalized.contains('cancel') ||
        normalized.contains('batal') ||
        normalized.contains('expired') ||
        normalized.contains('reject')) {
      return 'Dibatalkan';
    }
    if (normalized.contains('confirmed') || normalized.contains('confirm')) {
      return 'Dikonfirmasi';
    }
    return 'Belum Bayar';
  }

  static String _durationLabel(Map<String, dynamic> json) {
    final totalNights =
        json['total_nights'] ??
        json['duration'] ??
        json['duration_days'] ??
        json['nights'] ??
        json['total_days'];
    final parsed = _intValue(totalNights);
    if (parsed > 0) return '$parsed malam';
    final checkIn =
        '${json['check_in_date'] ?? json['check_in'] ?? json['start_date'] ?? ''}';
    final checkOut =
        '${json['check_out_date'] ?? json['check_out'] ?? json['end_date'] ?? ''}';
    if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
      final start = DateTime.tryParse(checkIn);
      final end = DateTime.tryParse(checkOut);
      if (start != null && end != null) {
        final days = end.difference(start).inDays;
        if (days > 0) return '$days malam';
      }
    }
    return '1 malam';
  }

  static String _dateLabel(dynamic value) {
    final raw = '${value ?? ''}';
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _rupiah(dynamic value) {
    final number = value is num
        ? value.round()
        : double.tryParse('$value')?.round() ?? 0;
    if (number == 0) return 'Rp0';
    final text = number.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp$buffer';
  }
}
