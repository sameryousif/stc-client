// Model class representing the result of the enrollment process, containing the base64-encoded CSR and the private key generated during the enrollment, and providing a constructor to initialize these fields when creating an instance of the EnrollmentResult class
class EnrollmentResult {
  final String csrBase64;
  final String privateKey;

  EnrollmentResult({required this.csrBase64, required this.privateKey});
}
