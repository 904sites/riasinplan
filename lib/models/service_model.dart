import 'dart:convert';

class ServiceExtra {
  final String name;
  final double price;

  ServiceExtra({required this.name, required this.price});

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  factory ServiceExtra.fromMap(Map<String, dynamic> map) {
    return ServiceExtra(
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int duration;
  final List<ServiceExtra> addOns;
  final List<ServiceExtra> attires;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.duration = 60,
    this.addOns = const [],
    this.attires = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'addOns': addOns.map((x) => x.toMap()).toList(),
      'attires': attires.map((x) => x.toMap()).toList(),
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      duration: map['duration'] ?? 60,
      addOns: map['addOns'] != null
          ? List<ServiceExtra>.from(
              (map['addOns'] as List).map((x) => ServiceExtra.fromMap(x)))
          : [],
      attires: map['attires'] != null
          ? List<ServiceExtra>.from(
              (map['attires'] as List).map((x) => ServiceExtra.fromMap(x)))
          : [],
    );
  }

  String toJson() => json.encode(toMap());
  factory ServiceModel.fromJson(String source) =>
      ServiceModel.fromMap(json.decode(source));
}
