import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunderapp/screens/home/home_screen_controller.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/screens/orders/orders_repository.dart';
import 'package:thunderapp/screens/orders/orders_screen.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/models/pedido_model.dart';

import '../../shared/components/dialogs/default_alert_dialog.dart';
import '../../shared/constants/style_constants.dart';
import '../../shared/core/models/produto_pedido_model.dart';
import '../../shared/core/user_storage.dart';
import '../home/home_screen.dart';



class OrdersController extends GetxController {
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());
  int quantPedidos = 0;
  RxString statusOrder = ''.obs;
  ListBancaModel? bancaModel;
  HomeScreenRepository homeRepository = HomeScreenRepository();
  PedidoModel? pedidoModel;
  List<PedidoModel> orders = [];
  List<OrderCard> pedidos = [];
  late Future<List<dynamic>> orderData;
  OrdersRepository repository = OrdersRepository();
  bool confirmSucess = false;
  bool confirmedOrder = false;
  bool delivery = false;
  File? _comprovante;
  String? _comprovanteType;
  String? _pdfPath;
  String? _downloadPath;
  Uint8List? _comprovanteBytes;

  double totalPedidosMesAtual = 0.0;

  List<PedidoModel> pedidosMesAtual = [];

  File? get comprovante => _comprovante;

  String? get comprovanteType => _comprovanteType;

  String? get pdfPath => _pdfPath;

  String? get downloadPath => _downloadPath;

  DateTime ultimaVerificacao = DateTime.now();
  String get chaveUltimoMes => 'ultimo_mes_verificado_${bancaModel?.id ?? 0}';
  String get chaveTotalUltimoMes => 'total_ultimo_mes_${bancaModel?.id ?? 0}';

  Uint8List? get comprovanteBytes => _comprovanteBytes;

  List<PedidoModel> get getOrders => orders;

  void setConfirm(bool value) {
    confirmedOrder = value;
    update();
  }

  void setStatus(String value) {
    statusOrder.value = value;
    update();
  }

  void confirmOrder(BuildContext context, int id) async {
    try {
      confirmSucess = await repository.confirmOrder(id, confirmedOrder);
      if (confirmSucess && confirmedOrder == true) {
        showDialog(
            context: context,
            builder: (context) => DefaultAlertDialogOneButton(
              title: 'Sucesso',
              body: 'O pedido foi aceito',
              confirmText: 'Ok',
              onConfirm: () {
                // navigator?.pushAndRemoveUntil(
                //   MaterialPageRoute(
                //       builder: (context) =>
                //           const HomeScreen()),
                //   (Route<dynamic> route) => false,
                // );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
              buttonColor: kSuccessColor,
            ));
      } else {
        showDialog(
            context: context,
            builder: (context) => DefaultAlertDialogOneButton(
              title: 'Sucesso',
              body: 'O pedido foi negado',
              confirmText: 'Ok',
              onConfirm: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
              buttonColor: kSuccessColor,
            ));
      }
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Erro'),
          content:
          Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
          actions: [
            TextButton(
              child: const Text('Voltar'),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
    }
  }

  void confirmDeliver(BuildContext context, int id) async {
    try {
      delivery = await repository.confirmDelivery(id);
      if (delivery == true) {
        showDialog(
            context: context,
            builder: (context) => DefaultAlertDialogOneButton(
              title: 'Sucesso',
              body: 'O pedido está pronto',
              confirmText: 'Ok',
              onConfirm: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
              buttonColor: kSuccessColor,
            ));
      } else {
        showDialog(
            context: context,
            builder: (context) => DefaultAlertDialogOneButton(
              title: 'Erro',
              body: 'Erro na entrega',
              confirmText: 'Ok',
              onConfirm: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
              buttonColor: kSuccessColor,
            ));
      }
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Erro'),
          content:
          Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
          actions: [
            TextButton(
              child: const Text('Voltar'),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchOrders() async {
    UserStorage userStorage = UserStorage();
    String userId = await userStorage.getUserId();
    try {
      bancaModel = homeScreenController.bancas[homeScreenController.banca.value];
      var fetchedOrders = await repository.getOrders(bancaModel!.id!);
      
      // Atualizar a lista completa de pedidos
      orders.assignAll(fetchedOrders);
      
      // Filtrar apenas pedidos do mês atual
      filtrarPedidosMesAtual();
      
      // Calcular o total do mês atual
      calcularTotalMesAtual();
      
      // Atualizar a UI com os pedidos filtrados
      await populateOrderCard();
      update();
    } catch (e) {
      print('Erro ao buscar pedidos: $e');
    }
  }

  void filtrarPedidosMesAtual() {
    // Obter o mês e ano atuais
    final agora = DateTime.now();
    final mesAtual = agora.month;
    final anoAtual = agora.year;
    
    // Filtrar os pedidos que são do mês atual
    pedidosMesAtual = orders.where((pedido) {
      if (pedido.dataPedido == null) return false;
      
      return pedido.dataPedido!.month == mesAtual && 
            pedido.dataPedido!.year == anoAtual;
    }).toList();
  }

  void calcularTotalMesAtual() {
    totalPedidosMesAtual = 0.0;
    
    for (var pedido in pedidosMesAtual) {
      if (pedido.status != "pedido recusado" && 
          pedido.status != "pagamento expirado") {
        totalPedidosMesAtual += pedido.total ?? 0.0;
      }
    }
  }

  Future<List<OrderCard>> populateOrderCard() async {
    List<OrderCard> list = [];
    bancaModel = homeScreenController.bancas[homeScreenController.banca.value];

    for (var order in pedidosMesAtual) {
      if (order.status != "pedido recusado" &&
          order.status != "pagamento expirado" &&
          order.status != "pedido entregue") {
        OrderCard card = OrderCard(order, this);
        list.add(card);
      }
    }

    pedidos = list; // Atualiza a lista de pedidos exibidos
    return list;
  }

  Future<String> fetchUserDetails(int userId) async {
    try {
      var userDetails = await repository.fetchUserDetails(userId);
      if (userDetails != null && userDetails.containsKey('user')) {
        return userDetails['user']['name']; // Retorna apenas o nome do usuário
      } else {
        return "Nome não encontrado"; // Retorna uma mensagem padrão
      }
    } catch (e) {
      print('Erro ao buscar nome do usuário: $e');
      return "Erro ao buscar usuário"; // Retorna uma mensagem de erro
    }
  }

  Future<void> pickComprovante() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _comprovante = File(result.files.single.path!);
        _comprovanteType = result.files.single.extension;
        _pdfPath = (_comprovanteType == 'pdf') ? _comprovante!.path : null;
        update();
      } else {
        debugPrint('Nenhum arquivo selecionado');
      }
    } catch (e) {
      debugPrint('Erro ao selecionar arquivo: $e');
    }
  }

  Future<void> loadPDF(String? path) async {
    try {
      if (path != null && path.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Erro ao carregar PDF: $e');
      throw Exception('Erro ao carregar PDF');
    }
  }

  Future<void> downloadComprovante(int orderId) async {
      try {
        _downloadPath = await repository.downloadComprovante(orderId);
        _comprovanteType = _downloadPath!.split('.').last;
        _pdfPath = (_comprovanteType == 'pdf') ? _downloadPath : null;
        update();
      } catch (e) {
        debugPrint('Erro ao baixar comprovante: $e');
      }
    }

    Future<void> verificarNovoMes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obter a data da última verificação
      final ultimoMesStr = prefs.getString(chaveUltimoMes);
      final agora = DateTime.now();
      final mesAtual = DateTime(agora.year, agora.month, 1);
      
      if (ultimoMesStr != null) {
        final ultimoMes = DateTime.parse(ultimoMesStr);
        
        // Verificar se estamos em um novo mês
        if (ultimoMes.month != mesAtual.month || ultimoMes.year != mesAtual.year) {
          // É um novo mês! Armazenar o total do mês anterior antes de reiniciar
          prefs.setDouble(chaveTotalUltimoMes, totalPedidosMesAtual);
          
          // Reiniciar o total para o novo mês
          totalPedidosMesAtual = 0.0;
          
          // Atualizar a data de última verificação
          prefs.setString(chaveUltimoMes, mesAtual.toIso8601String());
        }
      } else {
        // Primeira execução, simplesmente salva a data atual
        prefs.setString(chaveUltimoMes, mesAtual.toIso8601String());
      }
    } catch (e) {
      print('Erro ao verificar novo mês: $e');
    }
  }

  Future<double> getTotalMesAnterior() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(chaveTotalUltimoMes) ?? 0.0;
    } catch (e) {
      print('Erro ao obter total do mês anterior: $e');
      return 0.0;
    }
  }

  void exibirHistorico(BuildContext context) async {
    final totalAnterior = await getTotalMesAnterior();
    
    final mesAnterior = DateTime.now().month - 1 > 0 
        ? DateTime.now().month - 1 
        : 12;
    
    final anoMesAnterior = mesAnterior == 12 
        ? DateTime.now().year - 1 
        : DateTime.now().year;
    
    final nomeMesAnterior = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ][mesAnterior - 1];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Histórico de Vendas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total de $nomeMesAnterior/$anoMesAnterior:'),
            SizedBox(height: 8),
            Text(
              NumberFormat.simpleCurrency(locale: 'pt-BR', decimalDigits: 2)
                  .format(totalAnterior),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> fetchComprovanteBytes(int orderId) async {
    try {
      _comprovanteBytes = await repository.getComprovanteBytes(orderId);
      _comprovanteType = detectFileType(_comprovanteBytes!);
      update();
    } catch (e) {
      debugPrint('Erro ao obter bytes do comprovante: $e');
    }
  }

  String detectFileType(Uint8List bytes) {
    final pdfHeader = [0x25, 0x50, 0x44, 0x46];
    final jpgHeader = [0xFF, 0xD8, 0xFF];
    final pngHeader = [0x89, 0x50, 0x4E, 0x47];

    bool matchesHeader(Uint8List bytes, List<int> header) {
      for (int i = 0; i < header.length; i++) {
        if (bytes[i] != header[i]) {
          return false;
        }
      }
      return true;
    }

    if (bytes.length >= 4 && matchesHeader(bytes, pdfHeader)) {
      return 'pdf';
    } else if (bytes.length >= 3 && matchesHeader(bytes, jpgHeader)) {
      return 'jpg';
    } else if (bytes.length >= 4 && matchesHeader(bytes, pngHeader)) {
      return 'png';
    } else {
      return 'unknown';
    }
  }

  Future<List<PedidoModel>> loadList() async {
    UserStorage userStorage = UserStorage();
    var userId = await userStorage.getUserId();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> listaString = prefs.getStringList('$userId/vendas') ?? [];
    return listaString
        .map((string) => PedidoModel.fromJson(json.decode(string)))
        .toList();
  }

  List<ProdutoPedidoModel> getItensDoPedido(int pedidoId) {
    try {
      var pedido = orders.firstWhere((order) => order.id == pedidoId);
      return pedido.listaDeProdutos ?? [];
    } catch (e) {
      // Pedido não encontrado
      return [];
    }
  }

  @override
  void onInit() {
    super.onInit();
    verificarNovoMes();
    fetchOrders();
  }
}

