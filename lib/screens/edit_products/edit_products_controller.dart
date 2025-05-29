import 'dart:convert';
import 'dart:developer';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/shared/constants/app_enums.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/products_model.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';
import 'edit_products_repository.dart';

class EditProductsController extends GetxController {
  ScreenState screenState = ScreenState.idle;

  // ✅ CORREÇÃO: Armazenar cópia profunda do produto original
  late ProductsModel _originalProduct;
  
  // Informações atuais para edição
  String? description;
  String? title;
  String measure = 'unidade';
  int? productId;
  int? stock;
  String? costPrice;
  String? salePrice;
  String? token;
  BancaModel? bancaModel;
  String? userId;
  late String userToken;
  bool hasImage = false;
  List<TableProductsModel> tableProducts = [];
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ✅ CORREÇÃO: Controllers únicos para cada instância
  late TextEditingController _stockController;
  late TextEditingController _saleController;
  late TextEditingController _descriptionController;
  late TextEditingController _titleController;

  // Repositories
  HomeScreenRepository homeRepository = HomeScreenRepository();
  UserStorage userStorage = UserStorage();
  EditProductsRepository repository = EditProductsRepository();
  List<TableProductsModel> products = [];

  // Formatador de moeda
  CurrencyTextInputFormatter currencyFormatter =
      CurrencyTextInputFormatter.currency(locale: 'pt-Br', symbol: 'R\$');

  // Getters para os controllers
  TextEditingController get saleController => _saleController;
  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get stockController => _stockController;

  // ✅ CONSTRUTOR CORRIGIDO - Cria cópia profunda e inicializa controllers
  EditProductsController(ProductsModel model) {
    // ✅ Criar cópia profunda do produto original
    _originalProduct = ProductsModel.fromJson(model.toJson());
    
    // ✅ Inicializar controllers únicos
    _stockController = TextEditingController();
    _saleController = TextEditingController();
    _descriptionController = TextEditingController();
    _titleController = TextEditingController();
    
    // ✅ RESET completo de todos os valores
    _resetControllerState();
    
    // Inicializar com valores do produto ORIGINAL
    description = _originalProduct.descricao;
    title = _originalProduct.titulo;
    productId = _originalProduct.id;
    stock = _originalProduct.estoque;
    costPrice = "1.00";
    salePrice = _originalProduct.preco?.toString();
    measure = _originalProduct.tipoMedida ?? 'Unidade';
    
    log('=== CONTROLLER INICIALIZADO ===');
    log('Produto ID: ${_originalProduct.id}');
    log('Título Original: ${_originalProduct.titulo}');
    log('Descrição Original: ${_originalProduct.descricao}');
    log('Estoque Original: ${_originalProduct.estoque}');
    log('Preço Original: ${_originalProduct.preco}');
    log('Medida Original: ${_originalProduct.tipoMedida}');
    log('================================');
  }

  // ✅ NOVO: Método para resetar completamente o estado
  void _resetControllerState() {
    description = null;
    title = null;
    measure = 'unidade';
    productId = null;
    stock = null;
    costPrice = null;
    salePrice = null;
    hasImage = false;
    tableProducts.clear();
    products.clear();
    screenState = ScreenState.idle;
    
    log('Estado do controller resetado completamente');
  }

  double changeProfit(String salePrice, String costPrice) {
    salePrice = salePrice
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    costPrice = costPrice
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');

    double profit = 0.0;
    if (salePrice.isNotEmpty && costPrice.isNotEmpty) {
      profit = double.parse(salePrice) - double.parse(costPrice);
    }
    return profit;
  }

  void setHasImage(bool value) {
    hasImage = value;
    update();
  }

  void setProductId(int? value) {
    productId = value;
    update();
  }

  void setDescription() {
    description = _descriptionController.text.trim();
    log('Descrição alterada para: $description');
    update();
  }

  void setTitle() {
    title = _titleController.text.trim();
    log('Título alterado para: $title');
    update();
  }

  void setMeasure(String value) {
    measure = value;
    log('Medida alterada para: $measure');
    update();
  }

  void setStock() {
    String value = _stockController.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    if (value.isNotEmpty) {
      stock = int.tryParse(value);
    }
    log('Estoque alterado para: $stock');
    update();
  }

  void setSalePrice() {
    String cleanPrice = _saleController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    
    if (cleanPrice.isNotEmpty) {
      try {
        double value = double.parse(cleanPrice);
        salePrice = value.toString();
        log('Preço de venda alterado para: $salePrice');
      } catch (e) {
        log('Erro ao converter preço para decimal: $e');
        salePrice = null;
      }
    } else {
      salePrice = null;
    }
    update();
  }

  // ✅ VALIDAÇÃO CORRIGIDA - com logs detalhados
  Future<bool> validateEmptyFields() async {
    try {
      log('=== INICIANDO VALIDAÇÃO ===');
      log('Produto Original ID: ${_originalProduct.id}');
      log('Produto Original Título: ${_originalProduct.titulo}');
      
      if (_originalProduct.id == null) {
        log('❌ ERRO: ID do produto original não encontrado');
        return false;
      }

      // ✅ Criar payload apenas com campos alterados
      Map<String, dynamic> payload = {};
      bool hasChanges = false;

      // Verificar título
      String currentTitle = _titleController.text.trim();
      log('Título atual no controller: "$currentTitle"');
      log('Título original: "${_originalProduct.titulo}"');
      
      if (currentTitle.isNotEmpty && currentTitle != (_originalProduct.titulo ?? '')) {
        payload['titulo'] = currentTitle;
        hasChanges = true;
        log('✅ Título será alterado: $currentTitle');
      }

      // Verificar descrição
      String currentDescription = _descriptionController.text.trim();
      log('Descrição atual no controller: "$currentDescription"');
      log('Descrição original: "${_originalProduct.descricao}"');
      
      if (currentDescription.isNotEmpty && currentDescription != (_originalProduct.descricao ?? '')) {
        payload['descricao'] = currentDescription;
        hasChanges = true;
        log('✅ Descrição será alterada: $currentDescription');
      }

      // Verificar unidade de medida
      if (measure.isNotEmpty && measure != (_originalProduct.tipoMedida ?? 'Unidade')) {
        payload['tipo_medida'] = measure;
        hasChanges = true;
        log('✅ Medida será alterada: $measure');
      } else {
        // Sempre incluir tipo_medida se existir
        payload['tipo_medida'] = measure.isNotEmpty ? measure : 'Unidade';
      }

      // Verificar estoque
      String currentStockText = _stockController.text.trim();
      log('Estoque atual no controller: "$currentStockText"');
      log('Estoque original: ${_originalProduct.estoque}');
      
      if (currentStockText.isNotEmpty) {
        try {
          int currentStock = int.parse(currentStockText.replaceAll(RegExp(r'[^0-9]'), ''));
          if (currentStock != (_originalProduct.estoque ?? 0)) {
            payload['estoque'] = currentStock;
            hasChanges = true;
            log('✅ Estoque será alterado: $currentStock');
          }
        } catch (e) {
          log('❌ Erro ao converter estoque: $e');
          return false;
        }
      }

      // Verificar preço de venda
      String currentPriceText = _saleController.text.trim();
      log('Preço atual no controller: "$currentPriceText"');
      log('Preço original: ${_originalProduct.preco}');
      
      if (currentPriceText.isNotEmpty) {
        try {
          String cleanPrice = currentPriceText
              .replaceAll('R\$', '')
              .replaceAll(' ', '')
              .replaceAll(RegExp(r'[^0-9,.]'), '')
              .replaceAll(',', '.');
          
          double currentPrice = double.parse(cleanPrice);
          if ((currentPrice - (_originalProduct.preco ?? 0.0)).abs() > 0.01) { // Comparação com tolerância
            payload['preco'] = cleanPrice;
            hasChanges = true;
            log('✅ Preço será alterado: $cleanPrice');
          }
        } catch (e) {
          log('❌ Erro ao converter preço: $e');
          return false;
        }
      }

      // Sempre incluir disponibilidade
      payload['disponivel'] = true;

      log('=== RESULTADO DA VALIDAÇÃO ===');
      log('Tem alterações: $hasChanges');
      log('Payload final: $payload');
      log('==============================');

      // ✅ Se nenhum campo foi alterado, não fazer requisição
      if (!hasChanges) {
        log('✅ Nenhum campo foi alterado. Produto já está atualizado.');
        return true;
      }

      // ✅ Usar ID do produto original
      var response = await repository.editProductsWithChanges(this, payload);
      
      if (response) {
        log('✅ Produto atualizado com sucesso!');
        return true;
      } else {
        log('❌ Falha ao atualizar o produto');
        return false;
      }
      
    } catch (e) {
      log('❌ Erro durante validação: ${e.toString()}');
      return false;
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
      log('Erro ao carregar lista de produtos tabelados: $e');
      return [];
    }
  }

  TableProductsModel? search(int? tableProId) {
    try {
      return tableProducts.firstWhere((product) => product.id == tableProId);
    } catch (e) {
      log('Produto tabelado não encontrado para ID: $tableProId');
      return null;
    }
  }

  // ✅ onInit CORRIGIDO - Inicialização segura e com logs
  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      log('=== INICIANDO onInit ===');
      log('Produto Original ID: ${_originalProduct.id}');
      
      // ✅ Carregar produtos tabelados
      tableProducts = await loadList();
      log('Produtos tabelados carregados: ${tableProducts.length}');

      // ✅ Inicializar campos de texto com valores ORIGINAIS
      _titleController.text = _originalProduct.titulo ?? '';
      _descriptionController.text = _originalProduct.descricao ?? '';
      _stockController.text = _originalProduct.estoque?.toString() ?? '';
      
      // ✅ Inicializar unidade de medida
      measure = _originalProduct.tipoMedida ?? 'Unidade';
      
      // ✅ Inicializar preço formatado de forma segura
      if (_originalProduct.preco != null && _originalProduct.preco! > 0) {
        String precoFormatado = "R\$ ${_originalProduct.preco!.toStringAsFixed(2)}".replaceAll('.', ',');
        _saleController.text = precoFormatado;
      } else {
        _saleController.text = '';
      }
      
      log('=== CAMPOS INICIALIZADOS ===');
      log('Título Controller: "${_titleController.text}"');
      log('Descrição Controller: "${_descriptionController.text}"');
      log('Estoque Controller: "${_stockController.text}"');
      log('Medida: "$measure"');
      log('Preço Controller: "${_saleController.text}"');
      log('============================');
      
    } catch (e) {
      log('❌ Erro durante inicialização: ${e.toString()}');
    }
    
    update();
  }

  @override
  void onClose() {
    log('=== FECHANDO CONTROLLER ===');
    log('Produto ID: ${_originalProduct.id}');
    
    // ✅ Limpar controllers para evitar memory leaks
    _titleController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _saleController.dispose();
    
    // ✅ Limpar listas
    tableProducts.clear();
    products.clear();
    
    log('Controller limpo com sucesso');
    super.onClose();
  }
}