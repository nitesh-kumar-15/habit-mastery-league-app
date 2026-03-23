import 'package:flutter_test/flutter_test.dart';

import 'package:habit_mastery_league/utils/app_dates.dart';

void main() {
  test('AppDates formats stable yyyy-MM-dd', () {
    expect(AppDates.formatDate(DateTime(2025, 3, 1)), '2025-03-01');
    expect(AppDates.parseDate('2025-03-01'), DateTime(2025, 3, 1));
  });
}
