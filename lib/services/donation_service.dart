class DonationService {
  static const String donationUrl = 'https://liberapay.com/edde746';

  static bool get isEnabled {
    return const bool.fromEnvironment('ENABLE_DONATIONS', defaultValue: false);
  }
}
