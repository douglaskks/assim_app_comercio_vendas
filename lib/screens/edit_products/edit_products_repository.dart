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
  
  // ✅ CORREÇÃO: Remover estados globais que podem causar conflitos
  // List<TableProductsModel> products = [];
  // TableProductsModel product = TableProductsModel();

  Future<List<TableProductsModel>> getProducts() async {
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();

    userToken = await userStorage.getUserToken();

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
        
        // ✅ CORREÇÃO: Criar lista local ao invés de usar estado global
        List<TableProductsModel> localProducts = [];
        
        for (int i = 0; i < responseData.length; i++) {
          TableProductsModel product = TableProductsModel(
            id: responseData[i]["id"],
            nome: responseData[i]["nome"],
            categoria: responseData[i]["categoria"]
          );
          localProducts.add(product);
        }
        
        log('Produtos tabelados carregados: ${localProducts.length}');
        return localProducts;
      }
    } catch (e) {
      log('Erro ao carregar produtos tabelados: $e');
    }
    
    return [];
  }

  Future<bool> editProductsWithChanges(
    EditProductsController controller,
    Map<String, dynamic> changedFields) async {
  
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    // ✅ CORREÇÃO: Usar productId do controller que vem do produto original
    int? productId = controller.productId;
    
    if (productId == null) {
      log('❌ ERRO: Product ID não encontrado no controller');
      return false;
    }

    log('=== REQUISIÇÃO PATCH ===');
    log('Endpoint: $kBaseURL/produtos/$productId');
    log('Headers: Authorization: Bearer ${userToken.substring(0, 20)}...');
    log('Corpo da requisição: $changedFields');
    log('========================');
    
    try {
      var response = await dio.patch(
        "$kBaseURL/produtos/$productId",
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
          // ✅ CORREÇÃO: Usar int ao invés de Duration para timeout
          sendTimeout: 30000, // 30 segundos em milissegundos
          receiveTimeout: 30000, // 30 segundos em milissegundos
        ),
        data: changedFields
      );

      log('=== RESPOSTA DA API ===');
      log('Status code: ${response.statusCode}');
      log('Corpo da resposta: ${response.data}');
      log('======================');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ Produto atualizado com sucesso');
        return true;
      } else {
        log('❌ Status code inesperado: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      log('=== ERRO DURANTE PATCH ===');
      
      // ✅ CORREÇÃO: Usar DioError ao invés de DioException (dependendo da versão do Dio)
      if (e is DioError) {
        final dioError = e;
        if (dioError.response != null) {
          log('❌ Erro de API - Status code: ${dioError.response!.statusCode}');
          log('❌ Erro de API - Corpo: ${dioError.response!.data}');
          log('❌ Headers da resposta: ${dioError.response!.headers}');
        } else {
          log('❌ Erro de conexão: ${dioError.message}');
          log('❌ Tipo do erro: ${dioError.type}');
        }
      } else {
        log('❌ Erro inesperado: ${e.toString()}');
      }
      
      log('==========================');
      return false;
    }
  }

  Future<bool> deleteProduct(context, int? prodId) async {
    if (prodId == null) {
      log('❌ ERRO: Product ID não fornecido para exclusão');
      return false;
    }

    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    log('=== REQUISIÇÃO DELETE ===');
    log('Endpoint: $kBaseURL/produtos/$prodId');
    log('Product ID: $prodId');
    log('=========================');

    try {
      var response = await dio.delete(
        '$kBaseURL/produtos/$prodId',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
          // ✅ CORREÇÃO: Usar int ao invés de Duration
          sendTimeout: 30000,
          receiveTimeout: 30000,
        ),
      );
      
      log('=== RESPOSTA DELETE ===');
      log('Status code: ${response.statusCode}');
      log('Corpo da resposta: ${response.data}');
      log('=======================');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        log('✅ Produto excluído com sucesso');
        return true;
      } else {
        log('❌ Status code inesperado para exclusão: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      log('=== ERRO DURANTE DELETE ===');
      
      // ✅ CORREÇÃO: Usar DioError
      if (e is DioError) {
        final dioError = e;
        if (dioError.response != null) {
          log('❌ Erro de API - Status code: ${dioError.response!.statusCode}');
          log('❌ Erro de API - Corpo: ${dioError.response!.data}');
        } else {
          log('❌ Erro de conexão: ${dioError.message}');
        }
      } else {
        log('❌ Erro inesperado: ${e.toString()}');
      }
      
      log('===========================');
      return false;
    }
  }

  // ✅ MÉTODO LEGADO - Manter por compatibilidade mas marcar como deprecated
  // ignore: deprecated_member_use_from_same_package
  @Deprecated('Use editProductsWithChanges instead')
  Future<bool> editProducts(EditProductsController controller) async {
    log('⚠️  AVISO: Método editProducts está deprecated. Use editProductsWithChanges');
    
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    userToken = await userStorage.getUserToken();

    var body = {
      "descricao": controller.description.toString(),
      "titulo": controller.title.toString(),
      "tipo_medida": controller.measure.toString(),
      "estoque": controller.stock,
      "preco": controller.salePrice,
      "custo": controller.costPrice,
      "disponivel": true
    };
    
    log('Body do método legado: $body');
    
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      log('Erro no método legado: $e');
      return false;
    }
  }
}