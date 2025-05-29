import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunderapp/screens/add_products/add_products_repository.dart';
import 'package:thunderapp/screens/home/home_screen_controller.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/shared/components/dialogs/default_alert_dialog.dart';
import 'package:thunderapp/shared/constants/app_enums.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';

class AddProductsController extends GetxController {
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());
  ScreenState screenState = ScreenState.idle;

  // ✅ CORREÇÃO 1: Controle de estado de carregamento
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ✅ CORREÇÃO 2: Debounce para prevenir duplo clique
  DateTime? _lastClickTime;
  static const Duration _debounceTime = Duration(milliseconds: 1000); // 1 segundo

  // Informações para o post de cadastro de produtos.
  String? description;
  String? title;
  String measure = 'unidade';
  int? productId;
  int? stock;
  String? salePrice;
  String? token;
  ListBancaModel? bancaModel;
  String? userId;
  late String userToken;
  bool hasImage = false;
  var selectedDropdownValue1 = 'DefaultValue1'.obs;
  var selectedDropdownValue2 = 'DefaultValue2'.obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  HomeScreenRepository homeRepository = HomeScreenRepository();
  UserStorage userStorage = UserStorage();
  AddProductsRepository repository = AddProductsRepository();

  List<TableProductsModel> products = [];

  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _saleController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  TextEditingController get saleController => _saleController;
  TextEditingController get titleController => _titleController;
  TextEditingController get stockController => _stockController;
  TextEditingController get descriptionController => _descriptionController;

  // ✅ CORREÇÃO 3: Método para verificar se pode processar clique
  bool _canProcessClick() {
    final now = DateTime.now();
    
    if (_lastClickTime == null || now.difference(_lastClickTime!) > _debounceTime) {
      _lastClickTime = now;
      return true;
    }
    
    if (kDebugMode) {
      debugPrint('⚠️ Duplo clique detectado - ignorando');
    }
    return false;
  }

  // ✅ CORREÇÃO 4: Método para controlar estado de loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    update();
  }

  double changeProfit(String salePrice, String costPrice) {
    salePrice = salePrice.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.');
    costPrice = costPrice.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.');

    double profit = 0.0;
    if (salePrice.isNotEmpty && costPrice.isNotEmpty) {
      profit = double.parse(salePrice) - double.parse(costPrice);
    }

    return profit;
  }

  void setProductId(int? value) {
    productId = value;
    update();
  }

  void setDescription() {
    description = descriptionController.text.trim();
    update();
  }

  void setTitle() {
    title = titleController.text.trim();
    update();
  }

  void setMeasure(String value) {
    measure = value;
    update();
  }

  void setStock() {
    String value = stockController.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    if (value.isNotEmpty) {
      stock = int.tryParse(value);
    }
    update();
  }

  void setSalePrice() {
    String cleanPrice = saleController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
        
    if (cleanPrice.isNotEmpty) {
      salePrice = cleanPrice;
    }
    update();
  }

  void loadTableProducts() async {
    products = await repository.getProducts();
    update();
  }

  // ✅ CORREÇÃO 5: Método principal com proteção contra duplo clique
  Future<bool> validateEmptyFields(context) async {
    // ✅ Verificar se já está processando ou se é duplo clique
    if (_isLoading) {
      if (kDebugMode) {
        debugPrint('⚠️ Já está processando cadastro - ignorando');
      }
      return false;
    }

    if (!_canProcessClick()) {
      return false;
    }

    Size size = MediaQuery.of(context).size;
    ButtonStyle styleCancel = ElevatedButton.styleFrom(
      backgroundColor: kErrorColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    );

    try {
      // ✅ Ativar loading
      _setLoading(true);

      if (kDebugMode) {
        debugPrint('=== INICIANDO CADASTRO ===');
        debugPrint('Título: $title');
        debugPrint('Descrição: $description');
        debugPrint('Produto ID: $productId');
        debugPrint('Estoque: $stock');
        debugPrint('Preço: $salePrice');
        debugPrint('=========================');
      }

      // ✅ Validação com mensagens mais específicas
      if (_titleController.text.trim().isEmpty) {
        _showValidationError(context, 'Por favor, preencha o título do produto.');
        return false;
      }

      if (_descriptionController.text.trim().isEmpty) {
        _showValidationError(context, 'Por favor, preencha a descrição do produto.');
        return false;
      }

      if (_stockController.text.trim().isEmpty) {
        _showValidationError(context, 'Por favor, preencha a quantidade em estoque.');
        return false;
      }

      if (_saleController.text.trim().isEmpty) {
        _showValidationError(context, 'Por favor, preencha o preço de venda.');
        return false;
      }

      if (productId == null) {
        _showValidationError(context, 'Por favor, selecione um produto da lista.');
        return false;
      }

      if (measure.isEmpty) {
        measure = 'unidade'; // Valor padrão
      }

      // ✅ Atualizar valores antes da requisição
      setTitle();
      setDescription();
      setStock();
      setSalePrice();

      if (kDebugMode) {
        debugPrint('Enviando requisição para API...');
      }

      // ✅ Fazer requisição com timeout
      var response = await repository.registerProduct(
        description, 
        title, 
        measure,
        stock, 
        salePrice, 
        productId, 
        bancaModel?.id
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou muito para responder');
        },
      );

      if (response) {
        if (kDebugMode) {
          debugPrint('✅ Produto cadastrado com sucesso!');
        }
        
        // ✅ Limpar campos após sucesso
        clearFields();
        
        return true;
      } else {
        _showValidationError(context, 'Erro ao cadastrar produto. Tente novamente.');
        return false;
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro durante cadastro: $e');
      }

      // ✅ Tratamento específico de erros
      if (e is DioError) {
        if (e.response?.statusCode == 400) {
          Get.dialog(
            AlertDialog(
              title: Text('Produto Duplicado', style: TextStyle(fontSize: size.height * 0.026)),
              content: Text(
                'Este produto já está cadastrado na sua banca.',
                style: TextStyle(fontSize: size.height * 0.022),
              ),
              actions: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: size.width * 0.3,
                      height: size.height * 0.040,
                      child: ElevatedButton(
                        style: styleCancel,
                        onPressed: () => Get.back(),
                        child: Text(
                          'Entendi',
                          style: TextStyle(
                              color: kTextColor,
                              fontSize: size.height * 0.022,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (e.response?.statusCode == 401) {
          _showValidationError(context, 'Sessão expirada. Faça login novamente.');
        } else if (e.response?.statusCode == 500) {
          _showValidationError(context, 'Erro no servidor. Tente novamente mais tarde.');
        } else {
          _showValidationError(context, 'Erro de conexão. Verifique sua internet.');
        }
      } else if (e.toString().contains('Timeout')) {
        _showValidationError(context, 'A requisição demorou muito. Verifique sua conexão.');
      } else {
        Get.dialog(
          AlertDialog(
            title: const Text('Erro Inesperado', style: TextStyle(fontSize: 22)),
            content: Container(
              alignment: Alignment.center,
              height: 100,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Text(
                  'Ocorreu um erro inesperado. Tente novamente.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Voltar',
                  style: TextStyle(color: kErrorColor, fontSize: 20),
                ),
                onPressed: () => Get.back(),
              ),
            ],
          ),
        );
      }
      return false;
    } finally {
      // ✅ SEMPRE desativar loading
      _setLoading(false);
    }
  }

  // ✅ CORREÇÃO 6: Método helper para mostrar erros de validação
  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void printList() {
    if (kDebugMode) {
      print(products);
    }
  }

  Future<List<TableProductsModel>> loadList() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> listaString = prefs.getStringList('listaProdutosTabelados') ?? [];
      return listaString
          .map((string) => TableProductsModel.fromJson(json.decode(string)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar lista local: $e');
      }
      return [];
    }
  }

  TableProductsModel? search(int? tableProId) {
    try {
      return products.firstWhere((product) => product.id == tableProId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Produto não encontrado para ID: $tableProId');
      }
      return null;
    }
  }

  void clearFields() {
    _saleController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _stockController.clear();
    measure = 'unidade';
    productId = null;
    description = null;
    title = null;
    stock = null;
    salePrice = null;
    
    // ✅ Reset do debounce
    _lastClickTime = null;
    
    update();
  }

  @override
  void onClose() {
    _saleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    super.onClose();
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      token = await userStorage.getUserToken();
      userId = await userStorage.getUserId();
      bancaModel = homeScreenController.bancas[homeScreenController.banca.value];
      products = await loadList();
      clearFields();
      
      if (kDebugMode) {
        debugPrint('AddProductsController inicializado com sucesso');
        debugPrint('Produtos carregados: ${products.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro na inicialização: $e');
      }
    }
    
    update();
  }
}