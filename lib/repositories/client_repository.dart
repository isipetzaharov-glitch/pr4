// lib/repositories/client_repository.dart
import '../models/client.dart';
import '../models/page_result.dart';

abstract interface class ClientRepository {
  Future<PageResult<Client>> find({
    String search = '',
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  });
  Future<Client?> findById(int id);
  Future<Client> create(Client c);
  Future<Client> update(Client c);
  Future<void> softDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> emailExists(String email, {int? exceptId});
}
