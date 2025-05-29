import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';

import '../../shared/constants/app_text_constants.dart';
import '../../shared/core/user_storage.dart';

class AddProductsRepository extends GetxController {
  late String userToken;
  
  // ✅ OTIMIZAÇÃO 1: Dio singleton com configuração otimizada
  static Dio? _dioInstance;
  
  Dio get _dio {
    if (_dioInstance == null) {
      _dioInstance = Dio(BaseOptions(
        baseUrl: kBaseURL,
        connectTimeout: 15000,    // 15 segundos
        receiveTimeout: 30000,    // 30 segundos
        sendTimeout: 30000,       // 30 segundos
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ));
      
      // ✅ OTIMIZAÇÃO 2: Interceptor para logs apenas em debug
      if (kDebugMode) {
        _dioInstance!.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ));
      }
      
      // ✅ OTIMIZAÇÃO 3: Interceptor para adicionar token automaticamente
      _dioInstance!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Buscar token sempre antes da requisição
          try {
            UserStorage userStorage = UserStorage();
            String token = await userStorage.getUserToken();
            options.headers['Authorization'] = 'Bearer $token';
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Erro ao obter token: $e');
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('Erro HTTP: ${error.response?.statusCode} - ${error.message}');
          }
          handler.next(error);
        },
      ));
    }
    return _dioInstance!;
  }

  Future<List<TableProductsModel>> getProducts() async {
    if (kDebugMode) {
      debugPrint('=== CARREGANDO PRODUTOS TABELADOS ===');
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      var response = await _dio.get('/produtos/tabelados');

      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('Tempo de resposta da API: ${stopwatch.elapsedMilliseconds}ms');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> responseData = response.data['produtos'];
        
        // ✅ OTIMIZAÇÃO 4: Usar List.generate para melhor performance
        List<TableProductsModel> products = List.generate(
          responseData.length,
          (index) => TableProductsModel(
            id: responseData[index]["id"],
            nome: responseData[index]["nome"],
            categoria: responseData[index]["categoria"],
          ),
        );

        // ✅ OTIMIZAÇÃO 5: Ordenação otimizada com null safety
        products.sort((a, b) {
          String nomeA = a.nome?.toLowerCase() ?? '';
          String nomeB = b.nome?.toLowerCase() ?? '';
          return nomeA.compareTo(nomeB);
        });

        if (kDebugMode) {
          debugPrint('✅ ${products.length} produtos carregados com sucesso');
        }

        return products;
      }
      
      if (kDebugMode) {
        debugPrint('❌ Status code inesperado: ${response.statusCode}');
      }
      return [];
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao carregar produtos tabelados: $e');
      }
      
      // ✅ OTIMIZAÇÃO 6: Retornar lista vazia em caso de erro
      return [];
    }
  }

  Future<bool> registerProduct(
      String? description,
      String? title,
      String? measure,
      int? stock,
      String? salePrice,
      int? productId,
      int? bancaId) async {
    
    if (kDebugMode) {
      debugPrint('=== REGISTRANDO PRODUTO ===');
      debugPrint('Título: $title');
      debugPrint('Produto ID: $productId');
      debugPrint('Banca ID: $bancaId');
    }

    // ✅ OTIMIZAÇÃO 7: Validação prévia para evitar requisições desnecessárias
    if (title == null || title.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Título não pode estar vazio');
      }
      return false;
    }

    if (productId == null) {
      if (kDebugMode) {
        debugPrint('❌ ID do produto não pode ser nulo');
      }
      return false;
    }

    if (bancaId == null) {
      if (kDebugMode) {
        debugPrint('❌ ID da banca não pode ser nulo');
      }
      return false;
    }

    // ✅ OTIMIZAÇÃO 8: Limpar e validar preço
    String cleanPrice = salePrice?.replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.') ?? '0';
    
    double? priceValue;
    try {
      priceValue = double.parse(cleanPrice);
      if (priceValue <= 0) {
        if (kDebugMode) {
          debugPrint('❌ Preço deve ser maior que zero');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Preço inválido: $salePrice');
      }
      return false;
    }

    // ✅ OTIMIZAÇÃO 9: Payload otimizado
    var body = {
      "descricao": description?.trim() ?? "",
      "titulo": title.trim(),
      "tipo_medida": measure?.trim() ?? "unidade",
      "estoque": stock ?? 0,
      "preco": cleanPrice,
      "custo": "1.00",
      "produto_tabelado_id": productId,
      "banca_id": bancaId,
      "disponivel": true, // ✅ Sempre disponível no cadastro
    };

    if (kDebugMode) {
      debugPrint('Payload: $body');
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      var response = await _dio.post("/produtos", data: body);
      
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('Tempo de cadastro: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Status code: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Produto cadastrado com sucesso!');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Status code inesperado: ${response.statusCode}');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao registrar produto: $e');
      }
      
      // ✅ OTIMIZAÇÃO 10: Re-throw para tratamento específico no controller
      rethrow;
    }
  }

  Future<bool> deleteProduct(context, int? prodId) async {
    if (prodId == null) {
      if (kDebugMode) {
        debugPrint('❌ ID do produto não pode ser nulo para exclusão');
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint('=== EXCLUINDO PRODUTO ===');
      debugPrint('Produto ID: $prodId');
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      var response = await _dio.delete('/produtos/$prodId');
      
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('Tempo de exclusão: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Status code: ${response.statusCode}');
      }
      
      bool success = response.statusCode == 200 || response.statusCode == 204;
      
      if (kDebugMode) {
        if (success) {
          debugPrint('✅ Produto excluído com sucesso');
        } else {
          debugPrint('❌ Falha na exclusão - Status: ${response.statusCode}');
        }
      }
      
      return success;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao excluir produto: $e');
      }
      return false;
    }
  }

  // ✅ OTIMIZAÇÃO 11: Método para testar conectividade
  Future<bool> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Requisição simples para testar a conexão
      await _dio.get('/produtos/tabelados').timeout(
        const Duration(seconds: 10),
      );
      
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('✅ Conexão OK - Tempo: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Falha na conexão: $e');
      }
      return false;
    }
  }

  // ✅ OTIMIZAÇÃO 12: Limpeza de recursos
  @override
  void onClose() {
    _dioInstance?.close();
    _dioInstance = null;
    super.onClose();
  }
}