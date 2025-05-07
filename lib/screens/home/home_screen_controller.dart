import 'package:get/get.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';

class HomeScreenController extends GetxController {
  UserStorage userStorage = UserStorage();
  HomeScreenRepository homeScreenRepository = HomeScreenRepository();
  String? userToken;
  BancaModel? bancaModel;
  RxInt banca = 0.obs;
  String? userId;
  
  // Declarar uma lista normal em vez de RxList
  List<ListBancaModel> _bancas = [];
  
  // Getter para acessar a lista
  List<ListBancaModel> get bancas => _bancas;

  Future<void> loadBancas() async {
    try {
      userId = await userStorage.getUserId();
      
      print("Carregando bancas para o usuário: $userId");
      
      // Buscar novas bancas do repositório
      List<ListBancaModel> novasBancas = await homeScreenRepository.getBancas(userId!);
      
      print("Bancas carregadas do repositório: ${novasBancas.length}");
      for (var banca in novasBancas) {
        print("Banca ID: ${banca.id}, Nome: ${banca.nome}");
      }
      
      // Remover duplicatas baseadas no ID da banca
      Map<String, ListBancaModel> uniqueBancasMap = {};
      for (var banca in novasBancas) {
        uniqueBancasMap[banca.id.toString()] = banca;
      }
      
      // Converter o mapa de volta para uma lista sem duplicatas
      _bancas = uniqueBancasMap.values.toList();
      
      print("Bancas após remoção de duplicatas: ${_bancas.length}");
      
      // Atualizar a UI
      update();
    } catch (e) {
      print('Erro ao carregar bancas: $e');
    }
  }

  void setBanca(int value) async {
    banca.value = value;
    print("valor do index da banca: $banca");
    await getBancaPrefs();
    update();
  }

  Future getBancaPrefs() async {
    userId = await userStorage.getUserId();
    userToken = await userStorage.getUserToken();
    bancaModel = await homeScreenRepository.getBancaPrefs(
        userToken, userId, banca.value);
    update();
  }

  @override
  void onInit() async {
    super.onInit();
    await loadBancas(); // Use await para garantir que as bancas são carregadas primeiro
    print("valor da banca: $banca");
    await getBancaPrefs();
    update();
  }
  
  // Adicionar um método para forçar o recarregamento completo
  Future<void> reloadEverything() async {
    _bancas = []; // Limpar a lista
    update(); // Atualizar a UI para mostrar lista vazia temporariamente
    await loadBancas(); // Recarregar bancas do zero
    await getBancaPrefs(); // Atualizar a banca selecionada
    update(); // Garantir que a UI seja atualizada
  }
}