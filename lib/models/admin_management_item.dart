import '../core/api_config.dart';

class AdminBookingItem {
  const AdminBookingItem({
    required this.id,
    required this.customerName,
    required this.branchName,
    required this.roomName,
    required this.roomTypeId,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.total,
    required this.status,
    required this.rawStatus,
    this.payment,
  });

  factory AdminBookingItem.fromJson(Map<String, dynamic> json) {
    final customer =
        (json['customer'] as Map?)?.cast<String, dynamic>() ??
        (json['user'] as Map?)?.cast<String, dynamic>() ??
        {};
    final room =
        (json['room'] as Map?)?.cast<String, dynamic>() ??
        (json['room_data'] as Map?)?.cast<String, dynamic>() ??
        {};
    final roomType =
        (json['room_type'] as Map?)?.cast<String, dynamic>() ??
        (room['room_type'] as Map?)?.cast<String, dynamic>() ??
        {};
    final branch =
        (json['branch'] as Map?)?.cast<String, dynamic>() ??
        (roomType['branch'] as Map?)?.cast<String, dynamic>() ??
        {};
    final paymentJson =
        (json['payment'] as Map?)?.cast<String, dynamic>() ??
        (json['latest_payment'] as Map?)?.cast<String, dynamic>();
    final rawStatus = '${json['status'] ?? json['booking_status'] ?? ''}';
    return AdminBookingItem(
      id: _intValue(json['id']),
      customerName:
          '${json['customer_name'] ?? customer['name'] ?? json['name'] ?? '-'}',
      branchName:
          '${json['branch_name'] ?? branch['name'] ?? roomType['branch_name'] ?? 'Cabang'}',
      roomName:
          '${json['room_type_name'] ?? roomType['name'] ?? json['room_name'] ?? 'Kamar'}',
      roomTypeId: _intValue(
        json['room_type_id'] ?? roomType['id'] ?? room['room_type_id'],
      ),
      roomNumber: '${json['room_number'] ?? room['number'] ?? '-'}',
      checkIn: _dateLabel(json['check_in'] ?? json['start_date']),
      checkOut: _dateLabel(json['check_out'] ?? json['end_date']),
      total: _rupiah(json['total'] ?? json['total_price'] ?? json['amount']),
      status: AdminBookingStatus.from(rawStatus),
      rawStatus: rawStatus.isEmpty ? 'pending' : rawStatus,
      payment: paymentJson == null
          ? null
          : AdminPaymentItem.fromJson(paymentJson, bookingJson: json),
    );
  }

  final int id;
  final String customerName;
  final String branchName;
  final String roomName;
  final int roomTypeId;
  final String roomNumber;
  final String checkIn;
  final String checkOut;
  final String total;
  final AdminBookingStatus status;
  final String rawStatus;
  final AdminPaymentItem? payment;
}

class AdminPaymentItem {
  const AdminPaymentItem({
    required this.id,
    required this.bookingId,
    required this.customerName,
    required this.branchName,
    required this.roomName,
    required this.amount,
    required this.status,
    required this.rawStatus,
    required this.proofUrl,
    required this.createdAt,
  });

  factory AdminPaymentItem.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? bookingJson,
  }) {
    final booking =
        (json['booking'] as Map?)?.cast<String, dynamic>() ?? bookingJson ?? {};
    final customer =
        (booking['customer'] as Map?)?.cast<String, dynamic>() ??
        (booking['user'] as Map?)?.cast<String, dynamic>() ??
        (json['customer'] as Map?)?.cast<String, dynamic>() ??
        {};
    final room =
        (booking['room'] as Map?)?.cast<String, dynamic>() ??
        (json['room'] as Map?)?.cast<String, dynamic>() ??
        {};
    final roomType =
        (booking['room_type'] as Map?)?.cast<String, dynamic>() ??
        (room['room_type'] as Map?)?.cast<String, dynamic>() ??
        (json['room_type'] as Map?)?.cast<String, dynamic>() ??
        {};
    final branch =
        (booking['branch'] as Map?)?.cast<String, dynamic>() ??
        (roomType['branch'] as Map?)?.cast<String, dynamic>() ??
        (json['branch'] as Map?)?.cast<String, dynamic>() ??
        {};
    final proof =
        '${json['proof_url'] ?? json['proof_image_url'] ?? json['payment_proof_url'] ?? json['proof_of_payment_url'] ?? json['proof_image'] ?? json['proof'] ?? json['payment_proof'] ?? ''}';
    final rawStatus =
        '${json['status'] ?? json['payment_status'] ?? booking['payment_status'] ?? ''}';
    return AdminPaymentItem(
      id: _intValue(json['payment_id'] ?? json['id'] ?? booking['payment_id']),
      bookingId: _intValue(json['booking_id'] ?? booking['id']),
      customerName:
          '${json['customer_name'] ?? booking['customer_name'] ?? customer['name'] ?? '-'}',
      branchName:
          '${json['branch_name'] ?? booking['branch_name'] ?? branch['name'] ?? 'Cabang'}',
      roomName:
          '${json['room_type_name'] ?? booking['room_type_name'] ?? roomType['name'] ?? 'Kamar'}',
      amount: _rupiah(
        json['amount'] ??
            json['total'] ??
            booking['total'] ??
            booking['total_price'],
      ),
      status: AdminPaymentStatus.from(rawStatus),
      rawStatus: rawStatus.isEmpty ? 'pending' : rawStatus,
      proofUrl: proof.isEmpty ? '' : ApiConfig.storageUrl(proof),
      createdAt: _dateLabel(json['created_at'] ?? json['paid_at']),
    );
  }

  final int id;
  final int bookingId;
  final String customerName;
  final String branchName;
  final String roomName;
  final String amount;
  final AdminPaymentStatus status;
  final String rawStatus;
  final String proofUrl;
  final String createdAt;
}

enum AdminBookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  static AdminBookingStatus from(String value) {
    final text = value.toLowerCase();
    if (text.contains('approve') ||
        text.contains('confirm') ||
        text.contains('active') ||
        text.contains('berlangsung') ||
        text.contains('diterima')) {
      return AdminBookingStatus.confirmed;
    }
    if (text.contains('cancel') ||
        text.contains('reject') ||
        text.contains('batal') ||
        text.contains('ditolak')) {
      return AdminBookingStatus.cancelled;
    }
    if (text.contains('complete') ||
        text.contains('selesai') ||
        text.contains('check-out') ||
        text.contains('checkout')) {
      return AdminBookingStatus.completed;
    }
    return AdminBookingStatus.pending;
  }

  String get label {
    switch (this) {
      case AdminBookingStatus.pending:
        return 'Menunggu';
      case AdminBookingStatus.confirmed:
        return 'Confirmed';
      case AdminBookingStatus.cancelled:
        return 'Dibatalkan';
      case AdminBookingStatus.completed:
        return 'Selesai';
    }
  }
}

enum AdminPaymentStatus {
  pending,
  paid,
  rejected;

  static AdminPaymentStatus from(String value) {
    final text = value.toLowerCase();
    if (text.contains('paid') ||
        text.contains('lunas') ||
        text.contains('verified') ||
        text.contains('success') ||
        text.contains('valid')) {
      return AdminPaymentStatus.paid;
    }
    if (text.contains('failed') ||
        text.contains('fail') ||
        text.contains('reject') ||
        text.contains('invalid') ||
        text.contains('tolak') ||
        text.contains('batal')) {
      return AdminPaymentStatus.rejected;
    }
    return AdminPaymentStatus.pending;
  }

  String get label {
    switch (this) {
      case AdminPaymentStatus.pending:
        return 'Menunggu';
      case AdminPaymentStatus.paid:
        return 'Terverifikasi';
      case AdminPaymentStatus.rejected:
        return 'Ditolak';
    }
  }
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('${value ?? ''}') ?? 0;
}

String _dateLabel(dynamic value) {
  final raw = '${value ?? ''}';
  if (raw.isEmpty) return '-';
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

String _rupiah(dynamic value) {
  final number = value is num
      ? value.round()
      : double.tryParse('${value ?? ''}')?.round() ?? 0;
  final text = number.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final remaining = text.length - index;
    buffer.write(text[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return 'Rp$buffer';
}
