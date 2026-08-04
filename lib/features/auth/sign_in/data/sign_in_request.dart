/*
|--------------------------------------------------------------------------
| SignInRequest
|--------------------------------------------------------------------------
|
| Plain request payload sent to the login endpoint.
|
|--------------------------------------------------------------------------
*/
class SignInRequest {
  final String phone;
  final String password;
  final String fcmToken;

  SignInRequest({
    required this.phone,
    required this.password,
    required this.fcmToken,
  });

  Map<String, dynamic> toJson() => {
        'username': phone,
        'password': password,
        'firebaseToken': fcmToken, // أو الاسم اللي الـ API محدده
      };
}
// class SignInRequest {
//   final String phone;
//   final String password;

//   SignInRequest({required this.phone, required this.password});

//   Map<String, dynamic> toJson() => {
//         'username': phone,
//         'password': password,
//       };
// }
