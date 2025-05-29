import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:thunderapp/shared/constants/app_text_constants.dart';
import 'package:thunderapp/shared/core/models/products_model.dart';
import '../../shared/core/user_storage.dart';

class ListProductsRepository {
  late String userToken;

  Future<List<ProductsModel>> getProducts(int? id) async {
    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== CARREGANDO PRODUTOS DA BANCA ===');
      debugPrint('Banca ID: $id');
    }

    // ✅ Validação prévia
    if (id == null) {
      if (kDebugMode) {
        debugPrint('❌ ERRO: ID da banca é nulo');
      }
      return [];
    }

    Dio dio = Dio();
    List<ProductsModel> stockProduct = [];
    UserStorage userStorage = UserStorage();
    
    try {
      String userToken = await userStorage.getUserToken();
      
      if (kDebugMode) {
        debugPrint('Token obtido: ${userToken.substring(0, 20)}...');
        debugPrint('Endpoint: $kBaseURL/bancas/$id/produtos');
      }

      var response = await dio.get(
        '$kBaseURL/bancas/$id/produtos',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $userToken"
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('Status da resposta: ${response.statusCode}');
        debugPrint('Corpo da resposta: ${response.data}');
      }

      // ✅ Verificar status code antes de processar
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (kDebugMode) {
          debugPrint('❌ Status code inesperado: ${response.statusCode}');
        }
        return [];
      }

      // ✅ Verificar se a resposta tem a estrutura esperada
      if (response.data == null) {
        if (kDebugMode) {
          debugPrint('❌ Resposta da API é nula');
        }
        return [];
      }

      if (response.data['produtos'] == null) {
        if (kDebugMode) {
          debugPrint('❌ Campo "produtos" não encontrado na resposta');
        }
        return [];
      }

      List<dynamic> data = response.data['produtos'];
      
      if (kDebugMode) {
        debugPrint('Número de produtos encontrados: ${data.length}');
      }

      // ✅ Processar cada produto com tratamento de erro
      for (int i = 0; i < data.length; i++) {
        try {
          var productData = data[i];
          
          // ✅ Validar dados obrigatórios
          if (productData['id'] == null) {
            if (kDebugMode) {
              debugPrint('⚠️ Produto no índice $i não tem ID, pulando...');
            }
            continue;
          }

          // ✅ Conversões seguras
          int? estoque;
          if (productData['estoque'] != null) {
            if (productData['estoque'] is String) {
              estoque = int.tryParse(productData['estoque']);
            } else {
              estoque = productData['estoque'] as int?;
            }
          }

          double? preco;
          if (productData['preco'] != null) {
            if (productData['preco'] is String) {
              preco = double.tryParse(productData['preco']);
            } else {
              preco = (productData['preco'] as num?)?.toDouble();
            }
          }

          double? custo;
          if (productData['custo'] != null) {
            if (productData['custo'] is String) {
              custo = double.tryParse(productData['custo']);
            } else {
              custo = (productData['custo'] as num?)?.toDouble();
            }
          }

          ProductsModel product = ProductsModel(
            id: productData['id'],
            nome: productData['nome']?.toString(),
            descricao: productData['descricao']?.toString(),
            titulo: productData['titulo']?.toString(),
            tipoMedida: productData['tipo_medida']?.toString(),
            estoque: estoque,
            preco: preco,
            custo: custo ?? 1.00, // Valor padrão se não informado
            disponivel: productData['disponivel'] ?? true,
            produtoTabeladoId: productData['produto_tabelado_id'],
            bancaId: productData['banca_id'],
            createdAt: productData['created_at']?.toString(),
            updatedAt: productData['updated_at']?.toString(),
          );

          stockProduct.add(product);

          if (kDebugMode) {
            debugPrint('✅ Produto adicionado: ${product.titulo} (ID: ${product.id})');
          }

        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Erro ao processar produto no índice $i: $e');
          }
          continue; // Pular este produto e continuar com os outros
        }
      }

      // ✅ Ordenar os produtos por título (com null safety)
      stockProduct.sort((a, b) {
        String tituloA = a.titulo?.toLowerCase() ?? '';
        String tituloB = b.titulo?.toLowerCase() ?? '';
        return tituloA.compareTo(tituloB);
      });

      if (kDebugMode) {
        debugPrint('✅ Total de produtos processados: ${stockProduct.length}');
        for (var product in stockProduct) {
          debugPrint('- ${product.titulo} (Estoque: ${product.estoque}, Preço: R\$ ${product.preco})');
        }
      }

      return stockProduct;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== ERRO AO CARREGAR PRODUTOS ===');
        
        if (e is DioError) {
          final dioError = e;
          if (dioError.response != null) {
            debugPrint('❌ Status: ${dioError.response!.statusCode}');
            debugPrint('❌ Corpo: ${dioError.response!.data}');
            debugPrint('❌ Mensagem: ${dioError.response!.statusMessage}');
          } else {
            debugPrint('❌ Erro de conexão: ${dioError.message}');
            debugPrint('❌ Tipo: ${dioError.type}');
          }
        } else {
          debugPrint('❌ Erro inesperado: $e');
        }
        
        debugPrint('=================================');
      }
      
      return []; // Retornar lista vazia em caso de erro
    }
  }

  Future<bool> deleteProduct(int? prodId) async {
    // ✅ Validação prévia
    if (prodId == null) {
      if (kDebugMode) {
        debugPrint('❌ ERRO: ID do produto é nulo');
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint('=== EXCLUINDO PRODUTO ===');
      debugPrint('Produto ID: $prodId');
    }

    Dio dio = Dio();
    UserStorage userStorage = UserStorage();

    try {
      userToken = await userStorage.getUserToken();

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

      if (kDebugMode) {
        debugPrint('Status da exclusão: ${response.statusCode}');
        debugPrint('Resposta: ${response.data}');
      }

      // ✅ Verificar status codes válidos para exclusão
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
}