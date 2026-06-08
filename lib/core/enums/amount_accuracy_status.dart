enum AmountAccuracyStatus {
  elementalConfirmed,
  compoundOnly,
  unknown,
  estimated;

  static AmountAccuracyStatus fromString(String value) {
    return AmountAccuracyStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AmountAccuracyStatus.unknown,
    );
  }
}

extension AmountAccuracyStatusX on AmountAccuracyStatus {
  String get label {
    switch (this) {
      case AmountAccuracyStatus.elementalConfirmed:
        return 'Elemental confirmed';
      case AmountAccuracyStatus.compoundOnly:
        return 'Compound only';
      case AmountAccuracyStatus.unknown:
        return 'Unknown';
      case AmountAccuracyStatus.estimated:
        return 'Estimated';
    }
  }

  String get shortLabel {
    switch (this) {
      case AmountAccuracyStatus.elementalConfirmed:
        return 'Confirmed';
      case AmountAccuracyStatus.compoundOnly:
        return 'Compound only';
      case AmountAccuracyStatus.unknown:
        return 'Unknown';
      case AmountAccuracyStatus.estimated:
        return 'Estimated';
    }
  }

}
