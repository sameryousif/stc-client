// Data models for the application, including the Supplier and Customer classes, which represent the supplier and customer information respectively, containing fields such as name, TIN, address, city, country, phone number, and email address, and providing constructors to initialize these fields when creating instances of the classes
class Supplier {
  String name;
  String tin;
  String address;
  String city;
  String country;
  String phone;
  String email;

  Supplier({
    required this.name,
    required this.tin,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.email,
  });
}

class Customer {
  String name;
  String tin;
  String address;
  String city;
  String country;
  String phone;
  String email;

  Customer({
    required this.name,
    required this.tin,
    required this.address,
    required this.city,
    required this.country,
    required this.phone,
    required this.email,
  });
}
