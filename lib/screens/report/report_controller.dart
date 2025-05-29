import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunderapp/screens/home/home_screen_controller.dart';
import 'package:thunderapp/screens/home/home_screen_repository.dart';
import 'package:thunderapp/screens/orders/orders_controller.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/list_banca_model.dart';
import 'package:thunderapp/shared/core/models/pedido_model.dart';
import '../../shared/core/user_storage.dart';
import 'report_repository.dart';
import 'report_screen.dart';

class ReportController extends GetxController {
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());

  int quantPedidos = 0;
  ListBancaModel? bancaModel;
  HomeScreenRepository homeRepository = HomeScreenRepository();
  List<PedidoModel> orders = [];
  List<ReportCard> pedidos = [];
  late Future<List<dynamic>> orderData;
  ReportRepository repository = ReportRepository();
  
  // Novas propriedades para cálculo de vendas
  double totalPedidosMesAtual = 0.0;
  List<PedidoModel> pedidosMesAtual = [];
  
  // Chaves para SharedPreferences
  String get chaveUltimoMes => 'ultimo_mes_verificado_${bancaModel?.id ?? 0}';
  String get chaveTotalUltimoMes => 'total_ultimo_mes_${bancaModel?.id ?? 0}';

  List<PedidoModel> get getOrders => orders;

  Future<List<ReportCard>> populateReportCard() async {
    List<ReportCard> list = [];
    UserStorage userStorage = UserStorage();
    var token = await userStorage.getUserToken();
    var userId = await userStorage.getUserId();
    bancaModel = homeScreenController.bancas[homeScreenController.banca.value];
    var pedidos = await repository.getReports(bancaModel!.id!);

    // Ordenar por data decrescente (mais recente primeiro)
    pedidos.sort((a, b) => b.dataPedido!.compareTo(a.dataPedido!));
    
    // Atualizar a lista completa de pedidos
    orders.assignAll(pedidos);
    
    // Filtrar apenas pedidos do mês atual
    filtrarPedidosMesAtual();
    
    // Calcular o total do mês atual
    calcularTotalMesAtual();

    quantPedidos = pedidos.length;

    for (int i = 0; i < pedidos.length; i++) {
      if (pedidos[i].status != "aguardando confirmação") {
        ReportCard card = ReportCard(pedidos[i], this, OrdersController());
        list.add(card);
      }
    }

    if (list.isNotEmpty) {
      update();
      return list;
    } else {
      log('CARD VAZIO');
      return list;
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

  @override
  void onInit() async {
    await verificarNovoMes();
    pedidos = await populateReportCard();
    super.onInit();
    update();
  }
}