import 'dart:async';

import 'package:app_flutter/presentation/sensor/parcel_revision_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects an older request that completes after a newer revision',
    () async {
      const parcelId = 'parcel-1';
      var currentRevision = 1;
      String? appliedResult;
      final older = Completer<String>();
      final newer = Completer<String>();

      Future<void> apply(
        Completer<String> request,
        int capturedRevision,
      ) async {
        final result = await request.future;
        if (isCurrentParcelRevision(
          parcelId: parcelId,
          parcelRevision: capturedRevision,
          currentParcelId: parcelId,
          currentParcelRevision: currentRevision,
        )) {
          appliedResult = result;
        }
      }

      final olderTask = apply(older, 1);
      currentRevision = 2;
      final newerTask = apply(newer, 2);
      newer.complete('newer');
      await newerTask;
      older.complete('older');
      await olderTask;

      expect(appliedResult, 'newer');
    },
  );
}
