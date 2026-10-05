// lib/models/repair_order.dart

class RepairOrder {
  final int id;
  final String title;
  final String vin;
  final int year;
  final int clientId; // many-to-one
  final int masterId; // many-to-one
  final List<int> serviceIds; // many-to-many
  final double cost;
  final String status;
  final DateTime? deletedAt;

  const RepairOrder({
    required this.id,
    required this.title,
    required this.vin,
    required this.year,
    required this.clientId,
    required this.masterId,
    required this.serviceIds,
    required this.cost,
    required this.status,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  RepairOrder copyWith({
    String? title,
    String? vin,
    int? year,
    int? clientId,
    int? masterId,
    List<int>? serviceIds,
    double? cost,
    String? status,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return RepairOrder(
      id: id,
      title: title ?? this.title,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      clientId: clientId ?? this.clientId,
      masterId: masterId ?? this.masterId,
      serviceIds: serviceIds ?? this.serviceIds,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Формат для отправки на сервер (write-модель).
  /// Отправляем только идентификаторы связей, не развёрнутые объекты.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'vin': vin,
    'year': year,
    'clientId': clientId,
    'masterId': masterId,
    'serviceIds': serviceIds,
    'cost': cost,
    'status': status,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  /// Разбор ответа сервера. Устойчив к двум формам:
  ///   - write-форма: clientId / masterId / serviceIds (числа/списки чисел),
  ///   - read-форма: client / master / services (объекты/списки объектов).
  /// Любое отсутствующее поле подменяется значением по умолчанию.
  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is Map) return (v['id'] as num?)?.toInt() ?? 0;
      return 0;
    }

    List<int> parseIds(dynamic v) {
      if (v is List) return v.map(parseId).toList();
      return const [];
    }

    return RepairOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      clientId: parseId(json['client'] ?? json['clientId']),
      masterId: parseId(json['master'] ?? json['masterId']),
      serviceIds: json.containsKey('services')
          ? parseIds(json['services'])
          : parseIds(json['serviceIds']),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'new',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );
  }
}
