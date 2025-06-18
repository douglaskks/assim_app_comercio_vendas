import 'dart:convert';
import 'dart:developer';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  // Informações para o post de cadastro de produtos.

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

  // -----------------------
  EditProductsController(ProductsModel model) {
    description = model.descricao;
    title = model.titulo;
    productId = model.id;
    stock = model.estoque;
    costPrice = "1.00";
    salePrice = model.preco.toString();
  }
  HomeScreenRepository homeRepository =
      HomeScreenRepository();
  UserStorage userStorage = UserStorage();

  EditProductsRepository repository =
      EditProductsRepository();
  List<TableProductsModel> products = [];
  final TextEditingController _stockController =
      TextEditingController();

  CurrencyTextInputFormatter currencyFormatter =
      CurrencyTextInputFormatter.currency(
          locale: 'pt-Br', symbol: 'R\$');

  final TextEditingController _saleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _titleController =
      TextEditingController();

  TextEditingController get saleController =>
      _saleController;

  TextEditingController get titleController =>
      _titleController;

  TextEditingController get descriptionController =>
      _descriptionController;

  TextEditingController get stockController =>
      _stockController;

  double changeProfit(String salePrice, String costPrice) {
    salePrice = salePrice
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    costPrice = costPrice
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');

    double profit = 0.0;
    if (salePrice.isNotEmpty && costPrice.isNotEmpty) {
      profit =
          double.parse(salePrice) - double.parse(costPrice);
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
    description = descriptionController.text;
    update();
  }

  void setTitle() {
    title = titleController.text;
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
      stock = int.parse(value);
    }
    update();
  }

  void setSalePrice() {
  // Remover símbolos de moeda (R$), espaços e substituir vírgulas por pontos
  salePrice = _saleController.text
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll(RegExp(r'[^0-9,.]'), '')
      .replaceAll(',', '.');
  
  // Garantir que é um número decimal válido
  try {
    double value = double.parse(salePrice!);
    salePrice = value.toString(); // Formato decimal padrão com ponto
  } catch (e) {
    // Se não for possível converter, manter o valor como está
    log('Erro ao converter preço para decimal: $e');
  }
  
  update();
}

  Future<bool> validateEmptyFields() async {
    try {
      log('Iniciando validação de campos...');
      
      // Verificar se o ID do produto existe (necessário para a edição)
      if (productId == null) {
        log('Erro: ID do produto não fornecido. Operação cancelada.');
        return false;
      }
      
      log('Preparando campos para envio...');
      
      // ✅ SEMPRE ENVIAR TODOS OS CAMPOS (como no Insomnia)
      Map<String, dynamic> allFields = {};
      
      // ✅ TÍTULO: Usar valor do controller se preenchido, senão usar original
      String finalTitle = _titleController.text.isNotEmpty 
          ? _titleController.text 
          : (title ?? '');
      if (finalTitle.isNotEmpty) {
        allFields['titulo'] = finalTitle;
        log('Campo título: $finalTitle');
      }
      
      // ✅ DESCRIÇÃO: Usar valor do controller se preenchido, senão usar original  
      String finalDescription = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : (description ?? '');
      if (finalDescription.isNotEmpty) {
        allFields['descricao'] = finalDescription;
        log('Campo descrição: $finalDescription');
      }
      
      // ✅ TIPO_MEDIDA: Usar valor atual (measure)
      allFields['tipo_medida'] = measure.toLowerCase() == 'unidade' ? 'Unidade' : measure;
      log('Campo tipo_medida: $measure');
      
      // ✅ ESTOQUE: Usar valor do controller se preenchido, senão usar original
      if (_stockController.text.isNotEmpty) {
        try {
          String value = _stockController.text
              .replaceAll(RegExp(r'[^0-9,.]'), '')
              .replaceAll(',', '.');
          int finalStock = int.parse(value);
          allFields['estoque'] = finalStock;
          log('Campo estoque: $finalStock');
        } catch (e) {
          log('Erro ao converter estoque, usando valor original: $stock');
          allFields['estoque'] = stock ?? 0;
        }
      } else {
        allFields['estoque'] = stock ?? 0;
        log('Campo estoque (original): ${stock ?? 0}');
      }
      
      // ✅ PREÇO: Usar valor do controller se preenchido, senão usar original
      if (_saleController.text.isNotEmpty) {
        try {
          String value = _saleController.text
              .replaceAll('R\$', '')
              .replaceAll(' ', '')
              .replaceAll(RegExp(r'[^0-9,.]'), '')
              .replaceAll(',', '.');
          allFields['preco'] = value;
          log('Campo preço: $value');
        } catch (e) {
          log('Erro ao converter preço, usando valor original: $salePrice');
          allFields['preco'] = salePrice ?? "0.00";
        }
      } else {
        allFields['preco'] = salePrice ?? "0.00";
        log('Campo preço (original): ${salePrice ?? "0.00"}');
      }
      
      // ✅ CUSTO: Sempre incluir
      allFields['custo'] = costPrice ?? "1.00";
      log('Campo custo: ${costPrice ?? "1.00"}');
      
      // ✅ DISPONÍVEL: Sempre incluir
      allFields['disponivel'] = true;
      log('Campo disponível: true');
      
      // ✅ VALIDAÇÃO: Verificar se campos obrigatórios estão preenchidos
      List<String> camposVazios = [];
      
      if (!allFields.containsKey('titulo') || allFields['titulo'].toString().isEmpty) {
        camposVazios.add('título');
      }
      if (!allFields.containsKey('descricao') || allFields['descricao'].toString().isEmpty) {
        camposVazios.add('descrição');
      }
      if (!allFields.containsKey('estoque') || allFields['estoque'] == null) {
        camposVazios.add('estoque');
      }
      if (!allFields.containsKey('preco') || allFields['preco'].toString().isEmpty) {
        camposVazios.add('preço');
      }
      
      if (camposVazios.isNotEmpty) {
        log('Campos obrigatórios vazios: ${camposVazios.join(", ")}');
        return false;
      }
      
      log('Enviando TODOS os campos para API...');
      log('Campos que serão enviados: $allFields');
      
      var response = await repository.editProductsWithChanges(this, allFields);
      
      if (response) {
        log('Produto atualizado com sucesso!');
        return true;
      } else {
        log('Falha ao atualizar o produto.');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('=== ERRO NA VALIDAÇÃO ===');
        
        if (e is DioError) {
          final dioError = e;
          if (dioError.response != null) {
            debugPrint('❌ Status HTTP: ${dioError.response!.statusCode}');
            debugPrint('❌ Dados da resposta: ${dioError.response!.data}');
            
            if (dioError.response!.data is Map) {
              var errorData = dioError.response!.data as Map;
              if (errorData.containsKey('message')) {
                debugPrint('❌ Mensagem do servidor: ${errorData['message']}');
              }
            }
          } else {
            debugPrint('❌ Tipo de erro: ${dioError.type}');
            debugPrint('❌ Mensagem: ${dioError.message}');
          }
        } else {
          debugPrint('❌ Erro inesperado: ${e.toString()}');
        }
        
        debugPrint('========================');
      }
      return false;
    }
  }

  Future<List<TableProductsModel>> loadList() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    List<String> listaString =
        prefs.getStringList('listaProdutosTabelados') ?? [];
    return listaString
        .map((string) => TableProductsModel.fromJson(
            json.decode(string)))
        .toList();
  }

  TableProductsModel? search(int? tableProId) {
    for (int i = 0; i < tableProducts.length; i++) {
      if (tableProducts[i].id == tableProId) {
        return tableProducts[i];
      }
    }
    return null;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    tableProducts = await loadList();

    _titleController.text = title ?? '';
    _descriptionController.text = description ?? '';
    _stockController.text = stock?.toString() ?? '';
    
    // Mostrar o preço formatado para o usuário, mas mantendo o valor original
    if (salePrice != null && salePrice!.isNotEmpty) {
      try {
        double price = double.parse(salePrice!);
        // Usar o formato de moeda apenas para visualização
        _saleController.text = "R\$ ${price.toStringAsFixed(2)}".replaceAll('.', ',');
      } catch (e) {
        _saleController.text = salePrice ?? '';
      }
    }
    
    update();
  }
}