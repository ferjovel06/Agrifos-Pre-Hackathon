bool isCurrentParcelRevision({
  required String parcelId,
  required int parcelRevision,
  required String? currentParcelId,
  required int? currentParcelRevision,
}) {
  return parcelId == currentParcelId && parcelRevision == currentParcelRevision;
}
