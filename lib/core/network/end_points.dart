/*
|--------------------------------------------------------------------------
| EndPoints
|--------------------------------------------------------------------------
|
| Centralized place for the API base URL and every endpoint path used
| across the app. Keeping them here means no repository ever hardcodes
| a URL string directly.
|
|--------------------------------------------------------------------------
*/

class EndPoints {
  // Base
  static const String baseUrl = "https://whatsorder.shop/mohamed";

  // Auth
  static const String epLogin = "/api/auth/signin";
  static const String epSignup = "/api/auth/signup";
  static const String epVerify = "/api/auth/verify";
  static const String epLogout = "/api/auth/logout";
  static const String epGoogleSignIn = "/api/auth/google";
  static const String epSendOtp = "/api/auth/send-otp";
  static const String epVerifyPhone = "/api/auth/verify-phone";
  static const String epForgetPassword = "/api/auth/forgetPassword";

  // Orders (home screen)
  static const String epOrders = "/api/order/getAll";
  static const String epOrderDetails = "/api/orders/details";
  static const String epVendorOrders = "/api/order/getVendorOrders";
  // static const String epGetVendorOrdersById = "/api/order/getVendorOrdersById";
  static const String epFindAllByVendorIdAndOrderDate =
      "/api/order/findAllByVendorIdAndOrderDate";
  static const String epWalletByVendor = "/api/wallet/by-vendor";
  static const String epWalletTransactions = "/api/transaction/user";
  static const String epMakeOffer = "/api/order/makeOffer";
  static const String epNotification = "/api/notification";
  static const String epSmsMessages = "/api/sms-message";
  static const String epNotificationIsPressed = "/api/notification/isPressed";
  static const String epSmsIsPressed = "/api/sms-message/isPressed";
  //paymiet
  static const String epPaymentCheckout = '/api/payment/checkout';
  static const String epAddPaymentToMyWallet =
      '/api/payment/addPaymentToMyWallet';
  // Sectors
  static const String epSector = "/api/auth/sector";

  // Profile
  static const String epProfile = "profile";
  static const String epUpdateProfile = "profile/update";

  // Add more endpoints here as features grow.
}
