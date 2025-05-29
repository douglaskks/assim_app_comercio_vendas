import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:thunderapp/screens/list_products/list_products_screen.dart';
import 'package:thunderapp/shared/core/models/products_model.dart';
import '../home/home_screen.dart';
import 'components/dropdown_edit_product.dart';
import 'components/dropdown_qtd_edit_product.dart';
import 'components/image_edit.dart';
import 'components/sale_infos.dart';
import 'edit_products_controller.dart';
import 'edit_products_repository.dart';
import '../../shared/constants/style_constants.dart';

class EditProductsScreen extends StatefulWidget {
  final ProductsModel model;
  final EditProductsRepository repository;

  const EditProductsScreen(this.model, this.repository, {Key? key}) : super(key: key);

  @override
  State<EditProductsScreen> createState() => _EditProductsScreenState();
}

class _EditProductsScreenState extends State<EditProductsScreen> {
  late EditProductsController controller;
  bool _isLoading = false;
  late String _uniqueTag;

  @override
  void initState() {
    super.initState();
    
    // ✅ Criar tag única para evitar conflitos
    _uniqueTag = 'EditProductsController_${widget.model.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    // ✅ Remover controller anterior se existir
    if (Get.isRegistered<EditProductsController>(tag: _uniqueTag)) {
      Get.delete<EditProductsController>(tag: _uniqueTag);
    }
    
    // ✅ Criar novo controller com tag única
    controller = Get.put(
      EditProductsController(widget.model), 
      tag: _uniqueTag,
      permanent: false
    );
    
    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== SCREEN INICIALIZADA ===');
      debugPrint('Produto ID: ${widget.model.id}');
      debugPrint('Produto Título: ${widget.model.titulo}');
      debugPrint('Controller Tag: $_uniqueTag');
      debugPrint('Build Mode: ${_getBuildMode()}');
      debugPrint('===========================');
    }
  }

  @override
  void dispose() {
    // ✅ Limpar controller ao fechar a tela
    if (Get.isRegistered<EditProductsController>(tag: _uniqueTag)) {
      Get.delete<EditProductsController>(tag: _uniqueTag);
    }
    
    if (kDebugMode) {
      debugPrint('Controller removido: $_uniqueTag');
    }
    super.dispose();
  }

  // ✅ HELPER: Detectar modo de build
  String _getBuildMode() {
    if (kDebugMode) return 'DEBUG';
    if (kProfileMode) return 'PROFILE';  
    if (kReleaseMode) return 'RELEASE';
    return 'UNKNOWN';
  }

  // ✅ HELPER: Verificar se deve mostrar debug
  bool get _shouldShowDebug {
    // Apenas em debug mode E durante desenvolvimento
    return kDebugMode && !kReleaseMode;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return GetBuilder<EditProductsController>(
      init: controller,
      tag: _uniqueTag,
      builder: (controller) => GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(size),
          body: _isLoading 
              ? _buildLoadingIndicator()
              : _buildBody(size, controller),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Size size) {
    return AppBar(
      backgroundColor: kPrimaryColor,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      title: Text(
        // ✅ TÍTULO DIFERENTE EM DEBUG
        _shouldShowDebug 
            ? 'Editar Produto [DEBUG]' 
            : 'Editar Produto',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size.height * 0.025,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => _showDeleteDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Salvando produto...',
            style: TextStyle(
              fontSize: 16,
              color: kSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Size size, EditProductsController controller) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ SEÇÃO DEBUG - APENAS EM DESENVOLVIMENTO
            if (_shouldShowDebug) _buildDebugSection(),
            
            // SEÇÃO 1: IMAGEM E INFORMAÇÕES BÁSICAS
            _buildSectionCard(
              title: 'Imagem e Informações',
              subtitle: 'Visualize a foto e dados básicos do produto',
              child: Column(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ImageEdit(controller, widget.model),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            //SEÇÃO 2: CATEGORIA E TIPO
            _buildSectionCard(
              title: 'Produto',
              subtitle: 'Produto a ser editado',
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropDownEditProduct(controller, widget.model),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // SEÇÃO 3: PREÇOS E ESTOQUE
            _buildSectionCard(
              title: 'Preços e Estoque',
              subtitle: 'Configure valores e quantidade disponível',
              child: Column(
                children: [
                  SaleInfos(controller, widget.model),
                  const SizedBox(height: 16),
                  DropDownQtdEditProduct(controller, widget.model),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // BOTÕES DE AÇÃO
            _buildActionButtons(size, controller),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ SEÇÃO DEBUG - Apenas visível em desenvolvimento
  Widget _buildDebugSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.amber[800], size: 16),
              const SizedBox(width: 8),
              Text(
                '🔧 DEBUG INFO - ${_getBuildMode()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('ID: ${widget.model.id}', style: const TextStyle(fontSize: 12)),
          Text('Título Original: ${widget.model.titulo}', style: const TextStyle(fontSize: 12)),
          Text('Descrição Original: ${widget.model.descricao}', style: const TextStyle(fontSize: 12)),
          Text('Estoque Original: ${widget.model.estoque}', style: const TextStyle(fontSize: 12)),
          Text('Preço Original: ${widget.model.preco}', style: const TextStyle(fontSize: 12)),
          Text('Controller Tag: $_uniqueTag', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Size size, EditProductsController controller) {
    return Column(
      children: [
        // Botão Salvar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _handleSave(controller),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Salvar Alterações',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kSuccessColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red[400], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Excluir Produto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir este produto? Esta ação não pode ser desfeita.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produto: ${widget.model.titulo ?? 'Sem título'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (widget.model.descricao != null)
                    Text('Descrição: ${widget.model.descricao}'),
                  Text('ID: ${widget.model.id}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _handleDelete(context),
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(EditProductsController controller) async {
    // ✅ LOGS APENAS EM DEBUG
    if (kDebugMode) {
      debugPrint('=== INICIANDO SALVAMENTO ===');
      debugPrint('Produto ID: ${widget.model.id}');
      debugPrint('Título Controller: ${controller.titleController.text}');
      debugPrint('============================');
    }
    
    if (!controller.formKey.currentState!.validate()) {
      _showErrorSnackbar('Por favor, corrija os campos destacados em vermelho');
      return;
    }

    setState(() => _isLoading = true);

    try {
      controller.setTitle();
      controller.setDescription();
      controller.setStock();
      controller.setSalePrice();

      bool success = await controller.validateEmptyFields();

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackbar('Erro ao salvar. Tente novamente.');
      }
    } catch (e) {
      // ✅ LOGS DE ERRO APENAS EM DEBUG
      if (kDebugMode) {
        debugPrint('Erro durante salvamento: $e');
      }
      _showErrorSnackbar('Erro inesperado. Verifique sua conexão.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    Navigator.pop(context);
    
    if (kDebugMode) {
      debugPrint('=== INICIANDO EXCLUSÃO ===');
      debugPrint('Produto ID: ${widget.model.id}');
      debugPrint('==========================');
    }
    
    setState(() => _isLoading = true);

    try {
      bool success = await widget.repository.deleteProduct(context, widget.model.id);
      
      if (success) {
        _showDeleteSuccessDialog();
      } else {
        _showErrorSnackbar('Erro ao excluir produto. Tente novamente.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro durante exclusão: $e');
      }
      _showErrorSnackbar('Erro inesperado ao excluir produto.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.green[600],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sucesso!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Produto atualizado com sucesso',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.off(() => ListProductsScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Ok',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Produto Excluído',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O produto foi removido com sucesso',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.offAll(() => const HomeScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Ok',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
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
}