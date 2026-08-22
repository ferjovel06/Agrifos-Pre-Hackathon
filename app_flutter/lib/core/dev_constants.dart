/// TODO: remove once a real "parcel selection" feature exists.
///
/// Several screens (sensor capture, home dashboard) need a `parcel_id` to
/// talk to the backend but there's no parcel picker yet, so they all fall
/// back to this same hardcoded UUID for now.
const String kPlaceholderParcelId = 'c365e14f-da8a-4cdf-b7d2-9c9357ba5f61';