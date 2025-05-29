import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunderapp/screens/home/home_screen_controller.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/screens/add_products/add_products_repository.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';

import '../edit_products/edit_products_repository.dart';
import '../list_products/components/card_products_list.dart';
import 'list_products_repository.dart';

class ListProductsController extends GetxController {
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());
  List<TableProductsModel> tableProducts = [];
  List<CardProductsList> products = [];
  ListBancaModel? bancaModel;
  int quantProducts = 0;
  int quantStock = 0;
  int? productId;
  late String userToken;
  late String userId;
  late bool hasImage = false;

  // ✅ Estados de loading e erro
  bool isLoading = false;
  String? errorMessage;

  HomeScreenRepository homeRepository = HomeScreenRepository();
  EditProductsRepository editRepository = EditProductsRepository();
  ListProductsRepository repository = ListProductsRepository();
  final TextEditingController _searchController = TextEditingController();
  TextEditingController get searchController => _searchController;

  void setHasImage(bool value) {
    hasImage = value;
    update();
  }

  // ✅ Método para controlar loading
  void _setLoading(bool loading) {
    isLoading = loading;
    update();
  }

  // ✅ Método para definir erro
  void _setError(String? error) {
    errorMessage = error;
    update();
  }

  Future<List<CardProductsList>> populateCardsProductsList() async {
    if (kDebugMode) {
      debugPrint('=== POPULANDO LISTA DE PRODUTOS ===');
    }

    List<CardProductsList> list = [];
    
    try {
      _setLoading(true);
      _setError(null);

      UserStorage userStorage = UserStorage();
      var token = await userStorage.getUserToken();
      var userId = await userStorage.getUserId();
      
      // ✅ Verificar se homeScreenController está inicializado
      if (homeScreenController.bancas.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Lista de bancas vazia, tentando recarregar...');
        }
        // ✅ CORREÇÃO: onInit() retorna void, não Future
        // Tentar forçar atualização do homeScreenController
        homeScreenController.onInit();
        
        // Aguardar um pouco para dar tempo de carregar
        await Future.delayed(Duration(milliseconds: 500));
        
        // Se ainda estiver vazio, tentar método alternativo
        if (homeScreenController.bancas.isEmpty) {
          throw Exception('Não foi possível carregar a lista de bancas');
        }
      }

      // ✅ Verificar se o índice da banca é válido
      int bancaIndex = homeScreenController.banca.value;
      if (bancaIndex >= homeScreenController.bancas.length) {
        throw Exception('Índice da banca inválido: $bancaIndex');
      }

      bancaModel = homeScreenController.bancas[bancaIndex];
      
      if (bancaModel?.id == null) {
        throw Exception('ID da banca não encontrado');
      }

      if (kDebugMode) {
        debugPrint('Banca selecionada: ${bancaModel?.nome} (ID: ${bancaModel?.id})');
        debugPrint('Token: ${token.substring(0, 20)}...');
        debugPrint('User ID: $userId');
      }

      // ✅ Buscar produtos da API
      var products = await repository.getProducts(bancaModel?.id);
      
      if (kDebugMode) {
        debugPrint('Produtos retornados da API: ${products.length}');
      }

      // ✅ Atualizar contadores
      quantProducts = products.length;
      quantStock = 0; // Resetar o contador

      if (products.isNotEmpty) {
        for (int i = 0; i < products.length; i++) {
          try {
            CardProductsList card = CardProductsList(
              token,
              products[i],
              repository,
              tableProducts,
              editRepository
            );
            list.add(card);
            
            // ✅ Somar estoque com null safety
            if (products[i].estoque != null) {
              quantStock += products[i].estoque!;
            }

            if (kDebugMode) {
              debugPrint('Card criado para: ${products[i].titulo}');
            }

          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Erro ao criar card para produto ${i}: $e');
            }
            continue; // Pular este produto e continuar
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Nenhum produto encontrado para a banca');
        }
        _setError('Nenhum produto cadastrado nesta banca');
        return [];
      }

      if (kDebugMode) {
        debugPrint('=== RESUMO ===');
        debugPrint('Cards criados: ${list.length}');
        debugPrint('Quantidade de produtos: $quantProducts');
        debugPrint('Estoque total: $quantStock');
        debugPrint('==============');
      }

      _setError(null); // Limpar erro se chegou aqui
      return list;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== ERRO AO POPULAR LISTA ===');
        debugPrint('Erro: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        debugPrint('=============================');
      }
      
      _setError('Erro ao carregar produtos: ${e.toString()}');
      return [];
      
    } finally {
      _setLoading(false);
    }
  }

  Future<List<TableProductsModel>> loadList() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> listaString = prefs.getStringList('listaProdutosTabelados') ?? [];
      return listaString.map((string) => TableProductsModel.fromJson(json.decode(string))).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao carregar lista local: $e');
      }
      return [];
    }
  }

  Future<void> fetchProducts() async {
    if (kDebugMode) {
      debugPrint('=== FETCH PRODUCTS INICIADO ===');
    }

    try {
      // ✅ Carregar produtos tabelados primeiro
      tableProducts = await loadList();
      
      if (kDebugMode) {
        debugPrint('Produtos tabelados carregados: ${tableProducts.length}');
      }

      // ✅ Carregar produtos da banca
      products = await populateCardsProductsList();
      
      if (kDebugMode) {
        debugPrint('Produtos da banca carregados: ${products.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro em fetchProducts: $e');
      }
      _setError('Erro ao carregar dados: ${e.toString()}');
    }
    
    update();
  }

  // ✅ Método para refresh manual
  Future<void> refreshProductList() async {
    if (kDebugMode) {
      debugPrint('=== REFRESH MANUAL ===');
    }

    try {
      var newList = await populateCardsProductsList();
      products = newList;
      
      if (kDebugMode) {
        debugPrint('✅ Lista atualizada: ${products.length} produtos');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro no refresh: $e');
      }
    }
    
    update();
  }

  // ✅ Método para debug - verificar estado
  void debugState() {
    if (!kDebugMode) return;
    
    debugPrint('=== ESTADO DO CONTROLLER ===');
    debugPrint('isLoading: $isLoading');
    debugPrint('errorMessage: $errorMessage');
    debugPrint('bancaModel: ${bancaModel?.toString()}');
    debugPrint('quantProducts: $quantProducts');
    debugPrint('quantStock: $quantStock');
    debugPrint('products.length: ${products.length}');
    debugPrint('tableProducts.length: ${tableProducts.length}');
    debugPrint('homeScreenController.bancas.length: ${homeScreenController.bancas.length}');
    debugPrint('homeScreenController.banca.value: ${homeScreenController.banca.value}');
    debugPrint('============================');
  }

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint('=== ListProductsController onInit ===');
    }
    fetchProducts();
  }

  @override
  void onReady() {
    super.onReady();
    if (kDebugMode) {
      debugPrint('=== ListProductsController onReady ===');
    }
    refreshProductList();
  }

  @override
  void onClose() {
    _searchController.dispose();
    super.onClose();
  }
}