enum UserRole {
  customer,
  deliveryPerson,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.deliveryPerson:
        return 'Delivery Person';
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.deliveryPerson:
        return 'delivery_person';
    }
  }
}

UserRole userRoleFromFirestore(Object? value) {
  final normalized = (value?.toString() ?? '').trim().toLowerCase();
  if (normalized == 'delivery_person') {
    return UserRole.deliveryPerson;
  }
  return UserRole.customer;
}
