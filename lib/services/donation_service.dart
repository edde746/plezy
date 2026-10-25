class DonationService {
  static const String donationUrl = String.fromEnvironment('DONATION_URL');

  static bool get isEnabled {
    return const bool.fromEnvironment('ENABLE_DONATIONS', defaultValue: false) && donationUrl.isNotEmpty;
  }
}
