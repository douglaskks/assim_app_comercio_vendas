import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:thunderapp/screens/add_products/add_products_controller.dart';
import 'package:thunderapp/screens/add_products/add_products_repository.dart';
import 'package:thunderapp/screens/add_products/components/dropdown_add_product.dart';
import 'package:thunderapp/screens/add_products/components/dropdown_qtd_add_product.dart';
import 'package:thunderapp/screens/add_products/components/elevated_button_add_product.dart';
import 'package:thunderapp/screens/add_products/components/image_edit.dart';
import 'package:thunderapp/screens/add_products/components/sale_infos.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';
import '../../shared/constants/app_number_constants.dart';
import '../../shared/constants/style_constants.dart';

class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({Key? key}) : super(key: key);

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  late AddProductsRepository repository;
  Future<List<TableProductsModel>>? products;
  late AddProductsController controller;

  @override
  void initState() {
    super.initState();
    
    // ✅ OTIMIZAÇÃO 1: Inicialização otimizada
    repository = AddProductsRepository();
    
    // ✅ OTIMIZAÇÃO 2: Carregamento assíncrono dos produtos
    products = repository.getProducts();
    
    if (kDebugMode) {
      debugPrint('AddProductsScreen inicializada');
    }
  }

  @override
  void dispose() {
    // ✅ OTIMIZAÇÃO 3: Limpeza de recursos
    repository.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return GetBuilder<AddProductsController>(
      init: AddProductsController(),
      builder: (controller) => GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Scaffold(
          backgroundColor: Colors.grey[50], // ✅ Cor de fundo mais suave
          appBar: _buildAppBar(context, controller),
          body: _buildBody(context, size, controller),
        ),
      ),
    );
  }

  // ✅ OTIMIZAÇÃO 4: AppBar otimizada
  PreferredSizeWidget _buildAppBar(BuildContext context, AddProductsController controller) {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      title: Text(
        controller.isLoading 
            ? 'Cadastrando Produto...' 
            : 'Adicionar Produto',
        style: kTitle2.copyWith(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: controller.isLoading 
            ? null // ✅ Desabilitar voltar durante loading
            : () => Navigator.of(context).pop(),
      ),
      // ✅ INDICADOR DE LOADING NA APPBAR
      bottom: controller.isLoading 
          ? const PreferredSize(
              preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : null,
    );
  }

  // ✅ OTIMIZAÇÃO 5: Body otimizado
  Widget _buildBody(BuildContext context, Size size, AddProductsController controller) {
    return Form(
      key: controller.formKey,
      child: Container(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            // ✅ INDICADOR DE STATUS DE CONEXÃO (apenas em debug)
            if (kDebugMode) _buildDebugStatus(controller),
            
            // ✅ CONTEÚDO PRINCIPAL
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(kDefaultPadding),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 8),
                  
                  // Imagem do produto
                  ImageEdit(controller),
                  
                  const SizedBox(height: 24),
                  
                  // Informações de venda
                  SaleInfos(controller),
                  
                  const SizedBox(height: 16),
                  
                  // Dropdown de quantidade
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DropDownQtdAddProduct(controller),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botão de adicionar
                  ElevatedButtonAddProduct(controller),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // ✅ FOOTER COM INFORMAÇÕES (apenas quando não está carregando)
            if (!controller.isLoading) _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ✅ DEBUG: Status de conexão
  Widget _buildDebugStatus(AddProductsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber[100],
      child: Row(
        children: [
          Icon(
            Icons.bug_report,
            color: Colors.amber[800],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'DEBUG MODE - Produtos carregados: ${controller.products.length}',
            style: TextStyle(
              color: Colors.amber[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FOOTER com dicas
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: kPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dica: Preencha todos os campos para um cadastro completo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}