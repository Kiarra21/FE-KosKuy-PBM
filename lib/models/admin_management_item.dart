import '../core/api_config.dart';
import 'booking_item.dart';

class AdminBookingItem {
  const AdminBookingItem({
    required this.id,
    required this.customerName,
    required this.branchId,
    required this.branchName,
    required this.roomName,
    required this.roomTypeId,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.total,
    required this.status,
    required this.rawStatus,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    this.payment,
  });

  factory AdminBookingItem.fromJson(Map<String, dynamic> json) {
    final customerBooking = BookingItem.fromJson(json);
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
    final booking = (json['booking'] as Map?)?.cast<String, dynamic>() ?? {};
    final checkProcess = _firstMap([
      json['check_process'],
      json['booking_check'],
      json['booking_process'],
      json['check_in_process'],
      json['checkin_process'],
      json['check_out_process'],
      json['checkout_process'],
      json['check_log'],
      json['check_logs'],
      json['checkin'],
      json['checkins'],
      json['check_in_data'],
      json['check_out_data'],
      json['latest_check_in'],
      json['latest_checkin'],
      json['latest_check_process'],
      booking['check_process'],
      booking['booking_check'],
      booking['booking_process'],
      booking['check_in_process'],
      booking['checkin_process'],
      booking['check_out_process'],
      booking['checkout_process'],
      booking['check_log'],
      booking['check_logs'],
      booking['checkin'],
      booking['checkins'],
      booking['check_in_data'],
      booking['check_out_data'],
      booking['latest_check_in'],
      booking['latest_checkin'],
      booking['latest_check_process'],
    ]);
    final nestedBooking = booking.isEmpty
        ? null
        : BookingItem.fromJson(booking);
    final paymentJson =
        (json['payment'] as Map?)?.cast<String, dynamic>() ??
        (json['latest_payment'] as Map?)?.cast<String, dynamic>();
    final rawStatus =
        '${json['status'] ?? json['booking_status'] ?? booking['status'] ?? ''}';
    final hasCheckedIn =
        _flagValue(
          json['checked_in_at'] ??
              json['check_in_at'] ??
              json['actual_check_in_at'] ??
              json['checked_in_date'] ??
              json['is_checked_in'] ??
              booking['checked_in_at'] ??
              booking['check_in_at'] ??
              booking['actual_check_in_at'] ??
              booking['checked_in_date'] ??
              booking['is_checked_in'] ??
              checkProcess['checked_in_at'] ??
              checkProcess['check_in_at'] ??
              checkProcess['actual_check_in_at'] ??
              checkProcess['checked_in_date'] ??
              checkProcess['check_in_photo'] ??
              checkProcess['is_checked_in'],
        ) ||
        _statusHas(rawStatus, const [
          'check-in',
          'check_in',
          'checked-in',
          'checked_in',
          'checked in',
          'inap',
          'occupied',
        ]);
    final hasCheckedOut =
        _flagValue(
          json['checked_out_at'] ??
              json['check_out_at'] ??
              json['actual_check_out_at'] ??
              json['checked_out_date'] ??
              json['is_checked_out'] ??
              booking['checked_out_at'] ??
              booking['check_out_at'] ??
              booking['actual_check_out_at'] ??
              booking['checked_out_date'] ??
              booking['is_checked_out'] ??
              checkProcess['checked_out_at'] ??
              checkProcess['check_out_at'] ??
              checkProcess['actual_check_out_at'] ??
              checkProcess['checked_out_date'] ??
              checkProcess['check_out_photo'] ??
              checkProcess['is_checked_out'],
        ) ||
        _statusHas(rawStatus, const [
          'check-out',
          'check_out',
          'checked-out',
          'checked_out',
          'checked out',
          'checkout',
          'selesai',
          'complete',
        ]);
    final checkIn = _dateLabel(
      json['check_in_date'] ??
          json['checkin_date'] ??
          json['check_in'] ??
          json['checkin'] ??
          json['start_date'] ??
          json['from_date'] ??
          booking['check_in_date'] ??
          booking['checkin_date'] ??
          booking['check_in'] ??
          booking['checkin'] ??
          booking['start_date'],
    );
    final checkOut = _dateLabel(
      json['check_out_date'] ??
          json['checkout_date'] ??
          json['check_out'] ??
          json['checkout'] ??
          json['end_date'] ??
          json['to_date'] ??
          booking['check_out_date'] ??
          booking['checkout_date'] ??
          booking['check_out'] ??
          booking['checkout'] ??
          booking['end_date'],
    );
    return AdminBookingItem(
      id: _intValue(json['id']),
      customerName:
          '${json['customer_name'] ?? customer['name'] ?? json['name'] ?? '-'}',
      branchId: _intValue(
        json['branch_id'] ??
            branch['id'] ??
            roomType['branch_id'] ??
            booking['branch_id'],
      ),
      branchName:
          '${json['branch_name'] ?? branch['name'] ?? roomType['branch_name'] ?? 'Cabang'}',
      roomName:
          '${json['room_type_name'] ?? roomType['name'] ?? json['room_name'] ?? 'Kamar'}',
      roomTypeId: _intValue(
        json['room_type_id'] ?? roomType['id'] ?? room['room_type_id'],
      ),
      roomNumber: '${json['room_number'] ?? room['number'] ?? '-'}',
      checkIn: _adminDateFallback(
        checkIn,
        nestedBooking?.checkInDate,
        customerBooking.checkInDate,
      ),
      checkOut: _adminDateFallback(
        checkOut,
        nestedBooking?.checkOutDate,
        customerBooking.checkOutDate,
      ),
      total: _rupiah(json['total'] ?? json['total_price'] ?? json['amount']),
      status: AdminBookingStatus.from(rawStatus),
      rawStatus: rawStatus.isEmpty ? 'pending' : rawStatus,
      hasCheckedIn: hasCheckedIn || hasCheckedOut,
      hasCheckedOut: hasCheckedOut,
      payment: paymentJson == null
          ? null
          : AdminPaymentItem.fromJson(
              paymentJson,
              bookingJson: json,
              hasPaymentRecord: true,
            ),
    );
  }

  final int id;
  final String customerName;
  final int branchId;
  final String branchName;
  final String roomName;
  final int roomTypeId;
  final String roomNumber;
  final String checkIn;
  final String checkOut;
  final String total;
  final AdminBookingStatus status;
  final String rawStatus;
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final AdminPaymentItem? payment;

  bool get canCheckOut =>
      status == AdminBookingStatus.confirmed && !hasCheckedOut;

  String get flowTitle {
    switch (status) {
      case AdminBookingStatus.pending:
        return 'Menunggu verifikasi';
      case AdminBookingStatus.confirmed:
        return hasCheckedIn
            ? 'Aktif, siap check-out'
            : 'Aktif, check-in belum tersinkron';
      case AdminBookingStatus.cancelled:
        return 'Booking dibatalkan';
      case AdminBookingStatus.completed:
        return 'Selesai check-out';
    }
  }

  String get flowDescription {
    switch (status) {
      case AdminBookingStatus.pending:
        return 'Pilih nomor kamar untuk mengaktifkan booking.';
      case AdminBookingStatus.confirmed:
        return hasCheckedIn
            ? 'Data check-in sudah ada. Tekan check-out saat tamu keluar.'
            : 'Saat checkout, sistem akan coba membuat data check-in otomatis.';
      case AdminBookingStatus.cancelled:
        return 'Tidak ada aksi lanjutan untuk booking ini.';
      case AdminBookingStatus.completed:
        return 'Kamar sudah dikosongkan dan booking selesai.';
    }
  }
}

class AdminPaymentItem {
  const AdminPaymentItem({
    required this.id,
    required this.bookingId,
    required this.customerName,
    required this.branchId,
    required this.branchName,
    required this.roomName,
    required this.amount,
    required this.amountRaw,
    required this.status,
    required this.rawStatus,
    required this.proofUrl,
    required this.createdAt,
    required this.createdDate,
    required this.hasPaymentRecord,
  });

  factory AdminPaymentItem.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? bookingJson,
    bool hasPaymentRecord = true,
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
    final rawStatus = hasPaymentRecord
        ? '${json['status'] ?? json['payment_status'] ?? booking['payment_status'] ?? ''}'
        : 'unpaid';
    final rawAmount =
        json['amount'] ??
        json['total'] ??
        booking['total'] ??
        booking['total_price'];
    final rawDate =
        json['paid_at'] ??
        json['created_at'] ??
        booking['paid_at'] ??
        booking['updated_at'] ??
        booking['created_at'];
    return AdminPaymentItem(
      id: hasPaymentRecord
          ? _intValue(json['payment_id'] ?? json['id'] ?? booking['payment_id'])
          : 0,
      bookingId: _intValue(json['booking_id'] ?? booking['id']),
      customerName:
          '${json['customer_name'] ?? booking['customer_name'] ?? customer['name'] ?? '-'}',
      branchId: _intValue(
        json['branch_id'] ??
            booking['branch_id'] ??
            branch['id'] ??
            roomType['branch_id'],
      ),
      branchName:
          '${json['branch_name'] ?? booking['branch_name'] ?? branch['name'] ?? 'Cabang'}',
      roomName:
          '${json['room_type_name'] ?? booking['room_type_name'] ?? roomType['name'] ?? 'Kamar'}',
      amount: _rupiah(rawAmount),
      amountRaw: _doubleValue(rawAmount),
      status: AdminPaymentStatus.from(rawStatus),
      rawStatus: rawStatus.isEmpty ? 'pending' : rawStatus,
      proofUrl: proof.isEmpty ? '' : ApiConfig.storageUrl(proof),
      createdAt: _dateLabel(rawDate),
      createdDate: _dateValue(rawDate),
      hasPaymentRecord: hasPaymentRecord,
    );
  }

  final int id;
  final int bookingId;
  final String customerName;
  final int branchId;
  final String branchName;
  final String roomName;
  final String amount;
  final double amountRaw;
  final AdminPaymentStatus status;
  final String rawStatus;
  final String proofUrl;
  final String createdAt;
  final DateTime? createdDate;
  final bool hasPaymentRecord;

  bool get hasProof => proofUrl.isNotEmpty;
  bool get canReview =>
      hasPaymentRecord && hasProof && status == AdminPaymentStatus.pending;
  String get displayStatus => hasPaymentRecord ? status.label : 'Belum Bayar';
}

class AdminReviewItem {
  const AdminReviewItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.createdDate,
    required this.isVisible,
  });

  factory AdminReviewItem.fromJson(Map<String, dynamic> json) {
    final customer =
        (json['customer'] as Map?)?.cast<String, dynamic>() ??
        (json['user'] as Map?)?.cast<String, dynamic>() ??
        {};
    final rawDate = json['created_at'] ?? json['updated_at'];
    return AdminReviewItem(
      id: _intValue(json['id']),
      customerName:
          '${json['customer_name'] ?? json['user_name'] ?? customer['name'] ?? 'Customer'}',
      rating: _intValue(json['rating']),
      comment: '${json['comment'] ?? json['review'] ?? json['message'] ?? ''}',
      createdAt: _dateLabel(rawDate),
      createdDate: _dateValue(rawDate),
      isVisible: _boolValue(
        json['is_visible'] ?? json['visible'] ?? json['is_public'] ?? true,
      ),
    );
  }

  final int id;
  final String customerName;
  final int rating;
  final String comment;
  final String createdAt;
  final DateTime? createdDate;
  final bool isVisible;
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

double _doubleValue(dynamic value) {
  if (value is num) return value.toDouble();
  final sanitized = '${value ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(sanitized) ?? 0;
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = '${value ?? ''}'.toLowerCase();
  if (text == 'false' || text == '0' || text == 'no') return false;
  return true;
}

bool _flagValue(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = '$value'.trim().toLowerCase();
  if (text.isEmpty || text == '-' || text == 'null') return false;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return true;
}

bool _statusHas(String value, List<String> needles) {
  final text = value.toLowerCase();
  return needles.any((needle) => text.contains(needle));
}

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    if (value is Map && value.isNotEmpty) {
      return value.cast<String, dynamic>();
    }
    if (value is List && value.isNotEmpty) {
      for (final item in value) {
        if (item is Map && item.isNotEmpty) {
          return item.cast<String, dynamic>();
        }
      }
    }
  }
  return {};
}

DateTime? _dateValue(dynamic value) {
  final raw = '${value ?? ''}';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
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

String _adminDateFallback(String primary, String? nested, String root) {
  if (primary != '-') return primary;
  if (nested != null && nested.isNotEmpty) return nested;
  if (root.isNotEmpty) return root;
  return '-';
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
