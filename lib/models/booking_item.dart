class BookingItem {
  const BookingItem({
    required this.id,
    required this.kosName,
    required this.roomLabel,
    required this.price,
    required this.total,
    required this.durationLabel,
    required this.status,
    required this.paymentDeadline,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final room = (json['room'] as Map?)?.cast<String, dynamic>() ?? {};
    final roomType =
        (json['room_type'] as Map?)?.cast<String, dynamic>() ??
        (room['room_type'] as Map?)?.cast<String, dynamic>() ??
        {};
    final branch =
        (json['branch'] as Map?)?.cast<String, dynamic>() ??
        (roomType['branch'] as Map?)?.cast<String, dynamic>() ??
        {};
    final roomTypeName =
        '${roomType['name'] ?? json['room_type_name'] ?? json['type'] ?? 'Kamar'}';
    final roomCount = _intValue(json['room_count'] ?? json['rooms_count'] ?? 1);
    final duration = _durationLabel(json);
    return BookingItem(
      id: _intValue(json['id']),
      kosName:
          '${json['kos_name'] ?? json['branch_name'] ?? branch['name'] ?? roomType['name'] ?? 'KosKuy'}',
      roomLabel: '$roomCount Kamar, $roomTypeName',
      price: _rupiah(json['price'] ?? json['room_price'] ?? roomType['price']),
      total: _rupiah(json['total'] ?? json['total_price'] ?? json['amount']),
      durationLabel: duration,
      status: _statusLabel('${json['status'] ?? json['payment_status'] ?? ''}'),
      paymentDeadline: _dateLabel(
        json['payment_deadline'] ??
            json['expired_at'] ??
            json['expires_at'] ??
            json['pay_before'],
      ),
    );
  }

  final int id;
  final String kosName;
  final String roomLabel;
  final String price;
  final String total;
  final String durationLabel;
  final String status;
  final String paymentDeadline;

  bool get isPaid => status == 'Lunas';
  bool get isCancelled => status == 'Dibatalkan';
  bool get isActive => !isPaid && !isCancelled;

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static String _statusLabel(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('paid') ||
        normalized.contains('lunas') ||
        normalized.contains('success') ||
        normalized.contains('selesai')) {
      return 'Lunas';
    }
    if (normalized.contains('cancel') ||
        normalized.contains('batal') ||
        normalized.contains('expired') ||
        normalized.contains('reject')) {
      return 'Dibatalkan';
    }
    return 'Belum Bayar';
  }

  static String _durationLabel(Map<String, dynamic> json) {
    final duration =
        json['duration'] ??
        json['duration_days'] ??
        json['nights'] ??
        json['total_days'];
    final parsed = _intValue(duration);
    if (parsed > 0) return '$parsed malam';
    final checkIn = '${json['check_in'] ?? json['start_date'] ?? ''}';
    final checkOut = '${json['check_out'] ?? json['end_date'] ?? ''}';
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
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
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
