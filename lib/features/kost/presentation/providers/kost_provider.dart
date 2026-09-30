import 'package:flutter/material.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/kost_model.dart';

enum KostLoadState { initial, loading, loaded, error }

class KostProvider extends ChangeNotifier {
  List<KostModel> _kostList = [];
  KostModel? _selectedKost;
  KostLoadState _state = KostLoadState.initial;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterType = 'ALL';

  List<KostModel> get kostList => _kostList;
  KostModel? get selectedKost => _selectedKost;
  KostLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == KostLoadState.loading;
  String get filterType => _filterType;

  List<KostModel> get filteredList {
    return _kostList.where((k) {
      final matchQuery =
          _searchQuery.isEmpty ||
          k.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          k.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchType = _filterType == 'ALL' || k.type == _filterType;
      return matchQuery && matchType;
    }).toList();
  }

  Future<void> fetchKostList({String? search}) async {
    _state = KostLoadState.loading;
    notifyListeners();
    try {
      _kostList = await MockService.fetchKostList(
        search: search,
        type: _filterType == 'ALL' ? null : _filterType,
      );
      _state = KostLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = KostLoadState.error;
    }
    notifyListeners();
  }

  Future<void> fetchKostDetail(int id) async {
    _state = KostLoadState.loading;
    notifyListeners();
    try {
      _selectedKost = await MockService.fetchKostById(id);
      _state = KostLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = KostLoadState.error;
    }
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }
}
