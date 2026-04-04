// Model class representing the subject information required for enrollment, containing fields such as common name (cn), organization (o), organizational unit (ou), country (c), state (st), locality (l), and serial number, and providing a constructor to initialize these fields when creating an instance of the EnrollmentSubject class
class EnrollmentSubject {
  final String cn;
  final String on;
  final String ou;
  final String c;
  final String st;
  final String l;
  final String serialNumber;

  const EnrollmentSubject({
    required this.cn,
    required this.on,
    required this.ou,
    required this.c,
    required this.st,
    required this.l,
    required this.serialNumber,
  });
}
