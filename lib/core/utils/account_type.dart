/*
|--------------------------------------------------------------------------
| AccountType
|--------------------------------------------------------------------------
|
| Whether the vendor signing up is an individual person or a registered
| company. Selected at the top of the "upload files" step and sent to
| the API as the `type` field on POST /api/auth/signup.
|
| NOTE: adjust the apiValue strings below if your backend expects
| different literals (e.g. "individual" instead of "person").
|--------------------------------------------------------------------------
*/

enum AccountType {
  person,
  company;

  /// Value sent to the API's `type` field.
  String get apiValue => switch (this) {
    AccountType.person => 'personal',
    AccountType.company => 'company',
  };
}
