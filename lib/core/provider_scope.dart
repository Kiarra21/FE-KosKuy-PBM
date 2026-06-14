import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/admin_management_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/customer_room_provider.dart';
import '../providers/owner_room_provider.dart';
import '../providers/owner_user_provider.dart';

void clearAllProviders(BuildContext context) {
  context.read<BookingProvider>().clear();
  context.read<BranchProvider>().clear();
  context.read<CustomerRoomProvider>().clear();
  context.read<AdminManagementProvider>().clear();
  context.read<OwnerRoomProvider>().clear();
  context.read<OwnerUserProvider>().clear();
}
