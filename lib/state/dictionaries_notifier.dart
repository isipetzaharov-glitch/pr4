// lib/state/dictionaries_notifier.dart
import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/master.dart';
import '../models/service_type.dart';
import '../repositories/api_master_repository.dart';
import '../repositories/api_service_type_repository.dart';
import '../repositories/client_repository.dart';

class DictionariesNotifier extends ChangeNotifier {
  final ClientRepository _clientRepo;
  final ApiMasterRepository _masterRepo;
  final ApiServiceTypeRepository _serviceRepo;

  DictionariesNotifier(this._clientRepo, this._masterRepo, this._serviceRepo);

  List<Client> clients = [];
  List<Master> masters = [];
  List<ServiceType> serviceTypes = [];

  bool _loaded = false;
  bool get loaded => _loaded;

  String? _error;
  String? get error => _error;

  /// Пункт 15: справочники запрашиваются один раз и кэшируются.
  /// force=true — принудительно перезагрузить (например, после CRUD).
  Future<void> ensureLoaded({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      final page = await _clientRepo.find(size: 1000);
      clients = page.items;
      masters = await _masterRepo.getAll();
      serviceTypes = await _serviceRepo.getAll();
      _loaded = true;
      _error = null;
    } catch (e) {
      _error = 'Не удалось загрузить справочники: $e';
    }
    notifyListeners();
  }
}
