import 'package:get/get.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';

class HomeScreenController extends GetxController {
  UserStorage userStorage = UserStorage();
  HomeScreenRepository homeScreenRepository = HomeScreenRepository();
  String? userToken;
  String? userId;
  BancaModel? bancaModel;
  RxInt banca = 0.obs;
  
  // Declarar uma lista normal em vez de RxList
  List<ListBancaModel> _bancas = [];
  
  // Getter para acessar a lista
  List<ListBancaModel> get bancas => _bancas;

  // ✅ NOVO MÉTODO: Carregar credenciais primeiro
  Future<void> loadUserCredentials() async {
    try {
      userId = await userStorage.getUserId();
      userToken = await userStorage.getUserToken();
      print("✅ Credenciais carregadas - UserID: $userId, Token: ${userToken != null ? 'PRESENTE' : 'AUSENTE'}");
    } catch (e) {
      print("❌ Erro ao carregar credenciais: $e");
    }
  }

  Future<void> loadBancas() async {
    try {
      // ✅ GARANTIR que as credenciais estão carregadas
      if (userId == null) {
        print("🔄 Credenciais não carregadas, carregando...");
        await loadUserCredentials();
      }
      
      if (userId == null) {
        print("❌ Não foi possível obter userId");
        return;
      }
      
      print("🔄 Carregando bancas para o usuário: $userId");
      
      // Buscar novas bancas do repositório
      List<ListBancaModel> novasBancas = await homeScreenRepository.getBancas(userId!);
      
      print("✅ Bancas carregadas do repositório: ${novasBancas.length}");
      for (var banca in novasBancas) {
        print("   - Banca ID: ${banca.id}, Nome: ${banca.nome}");
      }
      
      // Remover duplicatas baseadas no ID da banca
      Map<String, ListBancaModel> uniqueBancasMap = {};
      for (var banca in novasBancas) {
        uniqueBancasMap[banca.id.toString()] = banca;
      }
      
      // Converter o mapa de volta para uma lista sem duplicatas
      _bancas = uniqueBancasMap.values.toList();
      
      print("✅ Bancas após remoção de duplicatas: ${_bancas.length}");
      
      // Atualizar a UI
      update();
    } catch (e) {
      print('❌ Erro ao carregar bancas: $e');
    }
  }

  Future<void> getBancaPrefs() async {
    try {
      print("🔄 Iniciando getBancaPrefs...");
      
      // ✅ GARANTIR que as credenciais estão carregadas
      if (userId == null || userToken == null) {
        print("🔄 Credenciais ausentes, recarregando...");
        await loadUserCredentials();
      }
      
      // ✅ VERIFICAR se ainda estão ausentes
      if (userId == null || userToken == null) {
        print("❌ Credenciais ainda ausentes após reload");
        return;
      }
      
      // ✅ GARANTIR que a lista de bancas não está vazia
      if (_bancas.isEmpty) {
        print("🔄 Lista de bancas vazia, recarregando...");
        await loadBancas();
      }
      
      // ✅ VERIFICAR se ainda está vazia
      if (_bancas.isEmpty) {
        print("❌ Lista de bancas ainda vazia após reload");
        return;
      }
      
      // ✅ VALIDAR índice da banca
      if (banca.value >= _bancas.length) {
        print("⚠️ Índice de banca inválido (${banca.value}), total bancas: ${_bancas.length}. Usando índice 0");
        banca.value = 0;
      }
      
      print("🔄 Buscando dados da banca no índice: ${banca.value}");
      
      bancaModel = await homeScreenRepository.getBancaPrefs(
          userToken, userId, banca.value);
      
      if (bancaModel != null) {
        print("✅ Banca carregada com sucesso: ${bancaModel!.getNome} (ID: ${bancaModel!.id})");
      } else {
        print("❌ Falha ao carregar banca");
      }
      
      update();
    } catch (e) {
      print('❌ Erro ao carregar banca: $e');
    }
  }

  void setBanca(int value) async {
    try {
      print("🔄 Alterando banca para índice: $value");
      
      // ✅ VALIDAR índice antes de definir
      if (value >= _bancas.length || value < 0) {
        print("❌ Índice inválido: $value (total bancas: ${_bancas.length})");
        return;
      }
      
      banca.value = value;
      print("✅ Índice da banca alterado para: $value");
      
      await getBancaPrefs();
      update();
    } catch (e) {
      print("❌ Erro ao alterar banca: $e");
    }
  }

  @override
  void onInit() async {
    super.onInit();
    print("🚀 Iniciando HomeScreenController...");
    
    try {
      // ✅ SEQUÊNCIA CORRETA: Credenciais → Bancas → Banca atual
      await loadUserCredentials();
      await loadBancas(); 
      await getBancaPrefs();
      
      print("✅ HomeScreenController inicializado com sucesso");
      print("   - Total bancas: ${_bancas.length}");
      print("   - Banca atual: ${bancaModel?.getNome ?? 'NENHUMA'}");
      print("   - Índice atual: ${banca.value}");
      
      update();
    } catch (e) {
      print("❌ Erro na inicialização do HomeScreenController: $e");
    }
  }
  
  // ✅ MÉTODO MELHORADO: Recarregar tudo do zero
  Future<void> reloadEverything() async {
    try {
      print("🔄 Recarregando tudo...");
      
      // Limpar dados atuais
      _bancas = [];
      bancaModel = null;
      userToken = null;
      userId = null;
      
      // Forçar atualização para mostrar loading
      update();
      
      // Recarregar sequencialmente
      await loadUserCredentials();
      await loadBancas();
      await getBancaPrefs();
      
      print("✅ Reload completo finalizado");
      update();
    } catch (e) {
      print("❌ Erro durante reload completo: $e");
    }
  }

  // ✅ MÉTODO ADICIONAL: Verificar se está pronto para exibir imagem
  bool get isReadyForImage {
    bool ready = bancaModel?.id != null && 
                 userToken != null && 
                 userToken!.isNotEmpty;
    
    if (!ready) {
      print("⚠️ Não está pronto para imagem - BancaModel: ${bancaModel?.id}, Token: ${userToken != null ? 'PRESENTE' : 'AUSENTE'}");
    }
    
    return ready;
  }

  // ✅ MÉTODO ADICIONAL: Obter URL da imagem com validação
  String? get imageUrl {
    if (!isReadyForImage) return null;
    
    String url = 'https://comercioassim.ufape.edu.br/api/bancas/${bancaModel!.id}/imagem?t=${DateTime.now().millisecondsSinceEpoch}';
    print("🖼️ URL da imagem gerada: $url");
    return url;
  }

  // ✅ MÉTODO ADICIONAL: Obter headers para requisição de imagem
  Map<String, String>? get imageHeaders {
    if (userToken == null) return null;
    
    return {
      "Authorization": "Bearer $userToken"
    };
  }
}