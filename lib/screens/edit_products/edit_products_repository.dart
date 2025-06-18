import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';

import '../../shared/constants/app_text_constants.dart';
import '../../shared/core/user_storage.dart';
import 'edit_products_controller.dart';

class EditProductsRepository extends GetxController {
  late String userToken;

  // ✅ Método para carregar produtos tabelados
  Future<List<TableProductsModel>> getProducts() async {
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();

    userToken = await userStorage.getUserToken();

    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== CARREGANDO PRODUTOS TABELADOS ===');
    }

    try {
      var response = await dio.get(
        '$kBaseURL/produtos/tabelados',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> responseData = response.data['produtos'];
        
        // ✅ Criar lista local ao invés de usar estado global
        List<TableProductsModel> localProducts = [];
        
        for (int i = 0; i < responseData.length; i++) {
          TableProductsModel product = TableProductsModel(
            id: responseData[i]["id"],
            nome: responseData[i]["nome"],
            categoria: responseData[i]["categoria"]
          );
          localProducts.add(product);
        }
        
        // ✅ LOGS APENAS EM DEBUG - Removidos automaticamente em produção
        if (kDebugMode) {
          debugPrint('✅ Produtos tabelados carregados: ${localProducts.length}');
        }
        
        return localProducts;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Status code inesperado: ${response.statusCode}');
        }
      }
    } catch (e) {
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('❌ Erro ao carregar produtos tabelados: $e');
      }
    }
    
    return [];
  }

  // ✅ Método principal para editar produtos com campos alterados
  Future<bool> editProductsWithChanges(
    EditProductsController controller,
    Map<String, dynamic> changedFields) async {
  
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    // ✅ Usar productId do controller que vem do produto original
    int? productId = controller.productId;
    
    if (productId == null) {
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('❌ ERRO: Product ID não encontrado no controller');
      }
      return false;
    }

    // ✅ LOGS APENAS EM DEBUG - Não aparecem em produção
    if (kDebugMode) {
      debugPrint('=== EDITANDO PRODUTO ===');
      debugPrint('Product ID: $productId');
      debugPrint('Endpoint: $kBaseURL/produtos/$productId');
      debugPrint('Campos alterados: $changedFields');
      debugPrint('Token: ${userToken.substring(0, 20)}...');
      debugPrint('========================');
    }
    
    try {
      var response = await dio.patch(
        "$kBaseURL/produtos/$productId",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
        data: changedFields
      );

      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('=== RESPOSTA DA EDIÇÃO ===');
        debugPrint('Status code: ${response.statusCode}');
        debugPrint('Corpo da resposta: ${response.data}');
        debugPrint('==========================');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ LOGS APENAS EM DEBUG
        if (kDebugMode) {
          debugPrint('✅ Produto editado com sucesso');
        }
        return true;
      } else {
        // ✅ LOGS APENAS EM DEBUG
        if (kDebugMode) {
          debugPrint('❌ Status code inesperado: ${response.statusCode}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== ERRO DURANTE EDIÇÃO ===');
        
        // ✅ Dio 4.x usa DioError
        if (e is DioError) {
          final dioError = e;
          
          // Verificar se há resposta do servidor
          if (dioError.response != null) {
            debugPrint('❌ Erro de API - Status: ${dioError.response!.statusCode}');
            debugPrint('❌ Erro de API - Dados: ${dioError.response!.data}');
            debugPrint('❌ Erro de API - Mensagem: ${dioError.response!.statusMessage}');
            
            // Extrair mensagem de erro específica se disponível
            if (dioError.response!.data is Map) {
              var errorData = dioError.response!.data as Map;
              if (errorData.containsKey('message')) {
                debugPrint('❌ Mensagem do servidor: ${errorData['message']}');
              }
              if (errorData.containsKey('errors')) {
                debugPrint('❌ Erros de validação: ${errorData['errors']}');
              }
            }
          } else {
            // Erro de conexão/rede
            debugPrint('❌ Erro de conexão - Tipo: ${dioError.type}');
            debugPrint('❌ Erro de conexão - Mensagem: ${dioError.message}');
            
            // Tipos específicos de erro do Dio 4.x
            switch (dioError.type) {
              case DioErrorType.connectTimeout:
                debugPrint('❌ Timeout de conexão');
                break;
              case DioErrorType.sendTimeout:
                debugPrint('❌ Timeout de envio');
                break;
              case DioErrorType.receiveTimeout:
                debugPrint('❌ Timeout de recebimento');
                break;
              case DioErrorType.response:
                debugPrint('❌ Erro de resposta do servidor');
                break;
              case DioErrorType.cancel:
                debugPrint('❌ Requisição cancelada');
                break;
              case DioErrorType.other:
                debugPrint('❌ Outro tipo de erro');
                break;
            }
          }
        } else {
          debugPrint('❌ Erro não relacionado ao Dio: ${e.toString()}');
        }
        
        debugPrint('============================');
      }
      return false;
    }
  }

  // ✅ Método para excluir produto
  Future<bool> deleteProduct(context, int? prodId) async {
    if (prodId == null) {
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('❌ ERRO: Product ID não fornecido para exclusão');
      }
      return false;
    }

    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== EXCLUINDO PRODUTO ===');
      debugPrint('Product ID: $prodId');
      debugPrint('Endpoint: $kBaseURL/produtos/$prodId');
      debugPrint('Token: ${userToken.substring(0, 20)}...');
      debugPrint('=========================');
    }

    try {
      var response = await dio.delete(
        '$kBaseURL/produtos/$prodId',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
      );
      
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('=== RESPOSTA DA EXCLUSÃO ===');
        debugPrint('Status code: ${response.statusCode}');
        debugPrint('Corpo da resposta: ${response.data}');
        debugPrint('============================');
      }
      
      // ✅ Verificar status codes válidos para exclusão
      if (response.statusCode == 200 || response.statusCode == 204) {
        // ✅ LOGS APENAS EM DEBUG
        if (kDebugMode) {
          debugPrint('✅ Produto excluído com sucesso');
        }
        return true;
      } else {
        // ✅ LOGS APENAS EM DEBUG
        if (kDebugMode) {
          debugPrint('❌ Status code inesperado para exclusão: ${response.statusCode}');
        }
        return false;
      }
      
    } catch (e) {
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('=== ERRO DURANTE EXCLUSÃO ===');
        
        if (e is DioError) {
          final dioError = e;
          if (dioError.response != null) {
            debugPrint('❌ Erro de API - Status: ${dioError.response!.statusCode}');
            debugPrint('❌ Erro de API - Corpo: ${dioError.response!.data}');
            debugPrint('❌ Erro de API - Mensagem: ${dioError.response!.statusMessage}');
          } else {
            debugPrint('❌ Erro de conexão: ${dioError.message}');
            debugPrint('❌ Tipo do erro: ${dioError.type}');
          }
        } else {
          debugPrint('❌ Erro inesperado: ${e.toString()}');
        }
        
        debugPrint('==============================');
      }
      return false;
    }
  }

  // ✅ Método legado - mantido para compatibilidade
  Future<bool> editProducts(EditProductsController controller) async {
    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('⚠️ AVISO: Usando método deprecated editProducts');
      debugPrint('⚠️ Recomenda-se usar editProductsWithChanges');
    }
    
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    // ✅ Validação prévia
    if (controller.productId == null) {
      if (kDebugMode) {
        debugPrint('❌ ERRO: Product ID não encontrado no controller');
      }
      return false;
    }

    var body = {
      "descricao": controller.description?.toString() ?? "",
      "titulo": controller.title?.toString() ?? "",
      "tipo_medida": controller.measure.toString(),
      "estoque": controller.stock ?? 0,
      "preco": controller.salePrice?.toString() ?? "0",
      "custo": controller.costPrice?.toString() ?? "1.00",
      "disponivel": true
    };
    
    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== MÉTODO LEGADO ===');
      debugPrint('Product ID: ${controller.productId}');
      debugPrint('Body: $body');
      debugPrint('====================');
    }
    
    try {
      var response = await dio.patch(
        "$kBaseURL/produtos/${controller.productId}",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
        data: body
      );

      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('Status da resposta: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ LOGS APENAS EM DEBUG
        if (kDebugMode) {
          debugPrint('✅ Produto editado com sucesso (método legado)');
        }
        return true;
      }
      
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('❌ Falha na edição - Status: ${response.statusCode}');
      }
      return false;
      
    } catch (e) {
      // ✅ LOGS APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('❌ Erro no método legado: $e');
      }
      return false;
    }
  }

  // ✅ Método para testar conectividade (útil para debug)
  Future<bool> testConnection() async {
    if (!kDebugMode) {
      // Em produção, assumir que a conexão está OK
      return true;
    }

    try {
      UserStorage userStorage = UserStorage();
      userToken = await userStorage.getUserToken();
      
      Dio dio = Dio();
      
      debugPrint('🔍 Testando conectividade...');
      
      final stopwatch = Stopwatch()..start();
      
      await dio.get(
        '$kBaseURL/produtos/tabelados',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
      );
      
      stopwatch.stop();
      debugPrint('✅ Conexão OK - Tempo: ${stopwatch.elapsedMilliseconds}ms');
      
      return true;
    } catch (e) {
      debugPrint('❌ Falha na conexão: $e');
      return false;
    }
  }

  // ✅ Limpeza de recursos
  @override
  void onClose() {
    // Limpeza se necessário
    super.onClose();
  }
}