import 'dart:io';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:thunderapp/screens/home/home_screen_controller.dart';
import 'package:thunderapp/screens/my_store/my_store_repository.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/models/feira_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';
import '../../shared/components/dialogs/default_alert_dialog.dart';
import '../../shared/constants/style_constants.dart';
import '../../shared/core/image_picker_controller.dart';
import '../home/home_screen.dart';

class MyStoreController extends GetxController {
  UserStorage userStorage = UserStorage();
  MyStoreRepository myStoreRepository = MyStoreRepository();
  File? _selectedImage;
  String feira = 'Feira';
  final _imagePickerController = ImagePickerController();
  String? _imagePath;
  bool hasImg = false;
  bool editSucess = false;
  bool adcSucess = false;
  List<FeiraModel> feiras = [];
  var textoErro = "Verifique os campos";
  String userToken = '';
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void loadFeiras() async {
    feiras = await myStoreRepository.getFeiras();
    update();
  }
  
  final List<bool> isSelected = [false, false, false];
  final List<String> checkItems = ['Dinheiro', 'PIX', 'Cartão'];

  final List<bool> delivery = [false, false];
  final List<String> deliveryItems = ['Sim', 'Não'];

  List<String> diasSemana = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
  ];

  List<bool> diasSelecionados = List.filled(7, false);

  Map<String, Map<String, String>> horariosFuncionamento = {
    'segunda-feira': {'abertura': '', 'fechamento': ''},
    'terca-feira': {'abertura': '', 'fechamento': ''},
    'quarta-feira': {'abertura': '', 'fechamento': ''},
    'quinta-feira': {'abertura': '', 'fechamento': ''},
    'sexta-feira': {'abertura': '', 'fechamento': ''},
    'sábado': {'abertura': '', 'fechamento': ''},
    'domingo': {'abertura': '', 'fechamento': ''},
  };

  bool deliver = false;
  bool pixBool = false;
  bool cashBool = false;

  MaskTextInputFormatter timeFormatter = MaskTextInputFormatter(
      mask: '#@:%&',
      filter: {
        "#": RegExp(r'[0-2]'),
        "@": RegExp(r'^(?:[01]?\d|2[0-3])$'),
        "%": RegExp(r'[0-5]'),
        "&": RegExp(r'[0-9]')
      },
      type: MaskAutoCompletionType.lazy);

  MaskTextInputFormatter timeFormatter2 = MaskTextInputFormatter(
      mask: '#@:%&',
      filter: {
        "#": RegExp(r'[0-2]'),
        "@": RegExp(r'[0-3]'),
        "%": RegExp(r'[0-5]'),
        "&": RegExp(r'[0-9]')
      },
      type: MaskAutoCompletionType.lazy);

  final TextEditingController _nomeBancaController = TextEditingController();
  final TextEditingController _feiraIdController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();
  final TextEditingController _quantiaMinController = TextEditingController();
  final TextEditingController _horarioAberturaController = TextEditingController();
  final TextEditingController _horarioFechamentoController = TextEditingController();

  TextEditingController get nomeBancaController => _nomeBancaController;
  TextEditingController get feiraIdController => _feiraIdController;
  TextEditingController get quantiaMinController => _quantiaMinController;
  TextEditingController get pixController => _pixController;
  TextEditingController get horarioAberturaController => _horarioAberturaController;
  TextEditingController get horarioFechamentoController => _horarioFechamentoController;

  void onItemTapped(int index) {
    isSelected[index] = !isSelected[index];
    
    // Se alternar o índice 1 (PIX), atualiza o estado do pixBool
    if (index == 1) {
      pixBool = isSelected[1];
    }
    
    // Se alternar o índice 0 (Dinheiro), atualiza o estado do cashBool
    if (index == 0) {
      cashBool = isSelected[0];
    }
    
    update();
  }

  void onDeliveryTapped(int index) {
    //delivery[index] = !delivery[index];
    for (int i = 0; i < delivery.length; i++) {
      delivery[i] = false;
    }
    // Ativa o checkbox selecionado
    delivery[index] = true;
    deliver = delivery[0];
    print("Entrega: $deliver");
    update();
  }

  void carregarDadosBancaParaEdicao(BancaModel banca) {
    log("=== INICIANDO CARREGAMENTO DOS DADOS DA BANCA ===");
    log("Banca ID: ${banca.id}");
    log("Nome: ${banca.nome}");
    log("Formas de pagamento: '${banca.formasDePagamento}'");
    log("PIX: '${banca.pix}'");
    log("Faz entrega: ${banca.fazEntrega}");
    log("Horário abertura original: '${banca.horarioAbertura}'");
    log("Horário fechamento original: '${banca.horarioFechamento}'");
    log("Horários funcionamento: ${banca.horariosFuncionamento}");
    
    // ✅ Carregar dados básicos
    _nomeBancaController.text = banca.nome ?? '';
    _pixController.text = banca.pix ?? '';
    
    // ✅ CORREÇÃO: Formatar preço mínimo corretamente
    if (banca.precoMin != null && banca.precoMin!.isNotEmpty) {
      try {
        double valor = double.parse(banca.precoMin!.replaceAll(',', '.'));
        _quantiaMinController.text = 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
        log("Preço mínimo formatado: ${_quantiaMinController.text}");
      } catch (e) {
        log("Erro ao formatar preço: $e");
        _quantiaMinController.text = banca.precoMin ?? '';
      }
    } else {
      _quantiaMinController.text = '';
    }
    
    // ✅ CORREÇÃO: Sempre carregar horários gerais PRIMEIRO
    String horarioAberturaOriginal = banca.horarioAbertura ?? '';
    String horarioFechamentoOriginal = banca.horarioFechamento ?? '';
    
    _horarioAberturaController.text = horarioAberturaOriginal;
    _horarioFechamentoController.text = horarioFechamentoOriginal;
    
    log("Horários gerais carregados: abertura='$horarioAberturaOriginal', fechamento='$horarioFechamentoOriginal'");
    
    // ✅ CORREÇÃO: Resetar arrays ANTES de processar
    diasSelecionados = List.filled(7, false);
    horariosFuncionamento = {
      'segunda-feira': {'abertura': '', 'fechamento': ''},
      'terca-feira': {'abertura': '', 'fechamento': ''},
      'quarta-feira': {'abertura': '', 'fechamento': ''},
      'quinta-feira': {'abertura': '', 'fechamento': ''},
      'sexta-feira': {'abertura': '', 'fechamento': ''},
      'sábado': {'abertura': '', 'fechamento': ''},
      'domingo': {'abertura': '', 'fechamento': ''},
    };
    
    // ✅ NOVA LÓGICA: Processar horários específicos ou usar horários gerais
    bool temHorariosEspecificos = false;
    
    if (banca.horariosFuncionamento != null && banca.horariosFuncionamento!.isNotEmpty) {
      try {
        Map<String, dynamic> horariosOriginais = banca.horariosFuncionamento!;
        log("Processando horários específicos: $horariosOriginais");
        
        horariosOriginais.forEach((dia, valores) {
          String abertura = '';
          String fechamento = '';
          
          // ✅ CORREÇÃO: Suportar diferentes formatos de horários da API
          if (valores is Map) {
            // Formato: {'abertura': '08:00', 'fechamento': '18:00'}
            abertura = valores['abertura']?.toString() ?? '';
            fechamento = valores['fechamento']?.toString() ?? '';
          } else if (valores is List && valores.length >= 2) {
            // Formato: ['08:00', '18:00']
            abertura = valores[0]?.toString() ?? '';
            fechamento = valores[1]?.toString() ?? '';
          }
          
          // ✅ VALIDAÇÃO: Verificar se horários estão no formato correto
          if (_validarFormatoHorario(abertura) && _validarFormatoHorario(fechamento)) {
            String diaCorreto = _normalizarNomeDia(dia);
            
            horariosFuncionamento[diaCorreto] = {
              'abertura': abertura,
              'fechamento': fechamento
            };
            
            int index = _obterIndiceDia(diaCorreto);
            if (index >= 0) {
              diasSelecionados[index] = true;
              temHorariosEspecificos = true;
              log("Dia $diaCorreto configurado: $abertura - $fechamento");
            }
          } else {
            log("⚠️ Horários inválidos para $dia: abertura='$abertura', fechamento='$fechamento'");
          }
        });
        
      } catch (e) {
        log("Erro ao processar horários específicos: $e");
        temHorariosEspecificos = false;
      }
    }
    
    // ✅ FALLBACK: Se não tem horários específicos válidos, usar horários gerais
    if (!temHorariosEspecificos && 
        _validarFormatoHorario(horarioAberturaOriginal) && 
        _validarFormatoHorario(horarioFechamentoOriginal)) {
      log("Aplicando horários gerais para todos os dias");
      _carregarHorariosGeraisParaTodosOsDias();
    }
    
    // ✅ CARREGAR formas de pagamento
    _carregarFormasPagamentoCorrigido(banca);
    
    // ✅ CARREGAR configurações de entrega
    deliver = banca.fazEntrega ?? false;
    _atualizarCheckboxEntrega();
    
    log("=== DADOS CARREGADOS COM SUCESSO ===");
    log("Horários específicos carregados: $temHorariosEspecificos");
    log("Dias selecionados: $diasSelecionados");
    log("Estado final - Dinheiro: ${isSelected[0]}, PIX: ${isSelected[1]}, Cartão: ${isSelected[2]}");
    log("pixBool: $pixBool, deliver: $deliver");
    
    update();
  }

  // ADICIONAR NOVO MÉTODO - Validação de formato de horário
  bool _validarFormatoHorario(String horario) {
    if (horario.isEmpty) return false;
    
    // Regex para formato HH:MM (exemplo: 08:00, 18:30)
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(horario);
  }

  // ✅ NOVA FUNÇÃO CORRIGIDA para carregar formas de pagamento
  void _carregarFormasPagamentoCorrigido(BancaModel banca) {
    log("--- Carregando formas de pagamento ---");
    
    // Resetar TODOS os estados relacionados a pagamento
    isSelected.fillRange(0, isSelected.length, false);
    pixBool = false;
    cashBool = false;
    
    // Verificar se formasDePagamento existe e não está vazio
    String? formasPagamento = banca.formasDePagamento;
    
    if (formasPagamento != null && formasPagamento.isNotEmpty) {
      log("Formas de pagamento encontradas: '$formasPagamento'");
      
      // Dividir por vírgula e processar cada forma
      List<String> formas = formasPagamento.split(',');
      
      for (String forma in formas) {
        String formaTrimmed = forma.trim();
        log("Processando forma: '$formaTrimmed'");
        
        // Converter string para número (1=Dinheiro, 2=PIX, 3=Cartão)
        int? formaNumero = int.tryParse(formaTrimmed);
        
        if (formaNumero != null) {
          switch (formaNumero) {
            case 1: // Dinheiro
              isSelected[0] = true;
              cashBool = true;
              log("✅ Dinheiro ativado");
              break;
            case 2: // PIX
              isSelected[1] = true;
              pixBool = true;
              log("✅ PIX ativado");
              break;
            case 3: // Cartão
              isSelected[2] = true;
              log("✅ Cartão ativado");
              break;
            default:
              log("⚠️ Forma de pagamento inválida: $formaNumero");
          }
        } else {
          log("⚠️ Não foi possível converter '$formaTrimmed' para número");
        }
      }
    } else {
      log("⚠️ Nenhuma forma de pagamento encontrada, usando Dinheiro como padrão");
      // Padrão: Dinheiro ativado
      isSelected[0] = true;
      cashBool = true;
    }
    
    // ✅ CORREÇÃO: Se existe chave PIX mas PIX não foi ativado, ativar automaticamente
    if (!pixBool && banca.pix != null && banca.pix!.isNotEmpty) {
      log("🔧 CORREÇÃO: Encontrada chave PIX '${banca.pix}' mas PIX não estava ativado");
      log("🔧 Ativando PIX automaticamente...");
      isSelected[1] = true;
      pixBool = true;
    }
    
    // Log do estado final
    log("Estado final das formas de pagamento:");
    log("- Dinheiro: ${isSelected[0]} (cashBool: $cashBool)");
    log("- PIX: ${isSelected[1]} (pixBool: $pixBool)");
    log("- Cartão: ${isSelected[2]}");
  }

  void _carregarHorariosGeraisParaTodosOsDias() {
    String abertura = _horarioAberturaController.text;
    String fechamento = _horarioFechamentoController.text;
    
    if (abertura.isNotEmpty && fechamento.isNotEmpty) {
      // Aplicar horários gerais para todos os dias
      for (int i = 0; i < 7; i++) {
        String nomeDia = convertIndexToDiaSemana(i);
        horariosFuncionamento[nomeDia] = {
          'abertura': abertura,
          'fechamento': fechamento
        };
        diasSelecionados[i] = true;
      }
    }
  }

  void _atualizarCheckboxEntrega() {
    // Resetar delivery checkboxes
    delivery.fillRange(0, delivery.length, false);
    
    if (deliver) {
      delivery[0] = true; // Sim
    } else {
      delivery[1] = true; // Não
    }
  }

  String _normalizarNomeDia(String dia) {
    Map<String, String> mapeamento = {
      'segunda': 'segunda-feira',
      'terca': 'terca-feira',
      'quarta': 'quarta-feira',
      'quinta': 'quinta-feira',
      'sexta': 'sexta-feira',
      'sabado': 'sábado',
      'domingo': 'domingo',
      // Aceitar também os nomes completos
      'segunda-feira': 'segunda-feira',
      'terca-feira': 'terca-feira',
      'quarta-feira': 'quarta-feira',
      'quinta-feira': 'quinta-feira',
      'sexta-feira': 'sexta-feira',
      'sábado': 'sábado',
      'domingo': 'domingo',
    };
    
    return mapeamento[dia.toLowerCase()] ?? dia.toLowerCase();
  }

  int _obterIndiceDia(String dia) {
    Map<String, int> indices = {
      'segunda-feira': 0,
      'terca-feira': 1,
      'quarta-feira': 2,
      'quinta-feira': 3,
      'sexta-feira': 4,
      'sábado': 5,
      'domingo': 6,
    };
    
    return indices[dia] ?? -1;
  }

  void setDeliver(bool value) {
    deliver = value;
    update();
  }
  
  void setPixBool(bool value){
    pixBool = value;
    update();
  }
  
  void setCashBool(bool value){
    cashBool = value;
    update();
  }

  void setFeira(String value) {
    feira = value;
    print("Feira selecionada: $value");
    update();
  }

  bool checkImg() {
    if (_selectedImage == null) {
      return false;
    }
    return true;
  }

  String? get imagePath => _imagePath;

  File? get selectedImage => _selectedImage;
  File? get imgFile => _selectedImage;

  set selectedImage(File? value) {
    _selectedImage = value;
    update();
  }

  Future selectImageCam() async {
    try {
      File? file = await _imagePickerController.pickImageFromCamera();
      if (file != null) {
        _imagePath = file.path;
      } else {
        return null;
      }
      _selectedImage = file;
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Erro 1'),
          content: Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      );
    }

    update();
  }

  Future<bool> editBancaAsync(BuildContext context, BancaModel banca) async {
    try {
      // Validações adicionais
      if (nomeBancaController.text.isEmpty && 
          horarioAberturaController.text.isEmpty && 
          horarioFechamentoController.text.isEmpty && 
          quantiaMinController.text.isEmpty && 
          _imagePath == null) {
        print("Nenhum campo foi alterado");
        return false;
      }

      editSucess = await myStoreRepository.editarBanca(
        nomeBancaController.text.trim(),
        horarioAberturaController.text.trim(),
        horarioFechamentoController.text.trim(),
        quantiaMinController.text.trim(),
        feira,
        _imagePath,
        isSelected,
        pixController.text.trim(),
        deliver,
        banca);
      
      return editSucess;
    } catch (e) {
      print("Erro ao editar banca: $e");
      return false;
    }
  }

  Future selectImage() async {
    try {
      File? file = await _imagePickerController.pickImageFromGallery();
      if (file != null) {
        _imagePath = file.path;
      } else {
        return null;
      }

      _selectedImage = file;
      update();
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Erro'),
          content: Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
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

  Future clearImg() async {
    _selectedImage = null;
    update();
  }

  Future<bool> editBancaComHorarios(BuildContext context, BancaModel banca) async {
    try {
      log("=== INICIANDO EDIÇÃO DA BANCA ===");
      log("Nome atual no controller: '${nomeBancaController.text}'");
      log("PIX atual no controller: '${pixController.text}'");
      log("Quantidade mínima no controller: '${quantiaMinController.text}'");
      log("Horário abertura no controller: '${horarioAberturaController.text}'");
      log("Horário fechamento no controller: '${horarioFechamentoController.text}'");
      
      // ✅ CORREÇÃO: Verificar se há ALGUMA alteração (mais flexível)
      bool temAlteracao = _verificarSeTemAlteracao(banca);
      
      if (!temAlteracao) {
        log("Nenhuma alteração detectada nos campos");
        return false;
      }

      // ✅ CORREÇÃO: Validar e limpar horários antes de enviar
      Map<String, Map<String, String>> horariosValidados = _validarELimparHorarios(banca);
      
      log("Horários validados a serem enviados: $horariosValidados");

      editSucess = await myStoreRepository.editarBancaComHorarios(
        nomeBancaController.text.trim(),
        horarioAberturaController.text.trim(),
        horarioFechamentoController.text.trim(),
        quantiaMinController.text.trim(),
        feira,
        _imagePath,
        isSelected,
        pixController.text.trim(),
        deliver,
        banca,
        horariosValidados // ✅ Passar horários validados
      );
      
      log("Resultado da edição: $editSucess");
      return editSucess;
    } catch (e) {
      log("Erro ao editar banca: $e");
      return false;
    }
  }

  // ✅ NOVO MÉTODO: Verificar campos que foram preenchidos
bool _verificarCamposNovos(BancaModel banca) {
  // PIX preenchido mas não existia antes
  if (pixController.text.trim().isNotEmpty && 
      (banca.pix == null || banca.pix!.trim().isEmpty)) {
    log("Novo PIX adicionado: '${pixController.text.trim()}'");
    return true;
  }
  
  // Preço preenchido mas não existia antes
  double precoAtual = _extrairValorMonetario(quantiaMinController.text);
  double precoOriginal = _extrairValorMonetario(banca.precoMin ?? '0');
  
  if (precoAtual > 0 && precoOriginal == 0) {
    log("Novo preço mínimo adicionado: '$precoAtual'");
    return true;
  }
  
  return false;
}

  // ✅ MÉTODO AUXILIAR MOVIDO PARA FORA
  double _extrairValorMonetario(String str) {
    if (str.isEmpty) return 0.0;
    
    String limpo = str
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();
    
    return double.tryParse(limpo) ?? 0.0;
  }

  // Método para verificar se houve alterações
  bool _verificarSeTemAlteracao(BancaModel banca) {
    log("=== VERIFICANDO ALTERAÇÕES ===");
    
    // ✅ CORREÇÃO: Normalizar strings para comparação
    String _normalizar(String? str) {
      return (str ?? '').trim().toLowerCase();
    }
    
    // ✅ CORREÇÃO: Comparação flexível de valores monetários
    double _extrairValorMonetario(String str) {
      if (str.isEmpty) return 0.0;
      
      String limpo = str
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.')
          .trim();
      
      return double.tryParse(limpo) ?? 0.0;
    }
    
    // 1. Verificar nome (ignorando case e espaços)
    String nomeAtual = _normalizar(nomeBancaController.text);
    String nomeOriginal = _normalizar(banca.nome);
    
    if (nomeAtual != nomeOriginal && nomeAtual.isNotEmpty) {
      log("✅ Nome alterado: '$nomeOriginal' -> '$nomeAtual'");
      return true;
    }
    
    // 2. Verificar PIX (ignorando case e espaços)
    String pixAtual = _normalizar(pixController.text);
    String pixOriginal = _normalizar(banca.pix);
    
    if (pixAtual != pixOriginal) {
      log("✅ PIX alterado: '$pixOriginal' -> '$pixAtual'");
      return true;
    }
    
    // 3. Verificar preço mínimo (comparação numérica)
    double precoAtual = _extrairValorMonetario(quantiaMinController.text);
    double precoOriginal = _extrairValorMonetario(banca.precoMin ?? '0');
    
    // Considerar alteração se diferença for maior que 0.01
    if ((precoAtual - precoOriginal).abs() > 0.01) {
      log("✅ Preço alterado: '$precoOriginal' -> '$precoAtual'");
      return true;
    }
    
    // 4. Verificar horários gerais (normalizar formato)
    String _normalizarHorario(String? horario) {
      if (horario == null || horario.isEmpty) return '';
      
      // Garantir formato HH:MM
      String limpo = horario.trim();
      if (limpo.length == 4 && limpo.contains(':')) {
        // Formato H:MM -> HH:MM
        if (limpo.indexOf(':') == 1) {
          limpo = '0$limpo';
        }
      }
      return limpo;
    }
    
    String aberturaAtual = _normalizarHorario(horarioAberturaController.text);
    String aberturaOriginal = _normalizarHorario(banca.horarioAbertura);
    
    String fechamentoAtual = _normalizarHorario(horarioFechamentoController.text);
    String fechamentoOriginal = _normalizarHorario(banca.horarioFechamento);
    
    if (aberturaAtual != aberturaOriginal && aberturaAtual.isNotEmpty) {
      log("✅ Horário abertura alterado: '$aberturaOriginal' -> '$aberturaAtual'");
      return true;
    }
    
    if (fechamentoAtual != fechamentoOriginal && fechamentoAtual.isNotEmpty) {
      log("✅ Horário fechamento alterado: '$fechamentoOriginal' -> '$fechamentoAtual'");
      return true;
    }
    
    // 5. Verificar formas de pagamento
    if (_verificarAlteracaoFormasPagamento(banca)) {
      log("✅ Formas de pagamento alteradas");
      return true;
    }
    
    // 6. Verificar entrega
    bool entregaAtual = deliver;
    bool entregaOriginal = banca.fazEntrega ?? false;
    
    if (entregaAtual != entregaOriginal) {
      log("✅ Configuração de entrega alterada: '$entregaOriginal' -> '$entregaAtual'");
      return true;
    }
    
    // 7. Verificar nova imagem
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      log("✅ Nova imagem selecionada: $_imagePath");
      return true;
    }
    
    // 8. Verificar horários específicos por dia
    if (_verificarAlteracaoHorariosEspecificos(banca)) {
      log("✅ Horários específicos alterados");
      return true;
    }
    
    // ✅ NOVA VERIFICAÇÃO: Campo preenchido mas não estava antes
    if (_verificarCamposNovos(banca)) {
      log("✅ Novos campos preenchidos");
      return true;
    }
    
    log("❌ Nenhuma alteração detectada");
    return false;
  }



  // Método para verificar alteração nas formas de pagamento
  bool _verificarAlteracaoFormasPagamento(BancaModel banca) {
    log("--- Verificando alteração nas formas de pagamento ---");
    
    // ✅ CORREÇÃO: Tratar strings vazias e nulas
    String formasOriginais = (banca.formasDePagamento ?? '').trim();
    
    // Se não havia formas de pagamento originais, considerar dinheiro como padrão
    List<String> formasOriginaisList = [];
    if (formasOriginais.isEmpty) {
      formasOriginaisList = ['1']; // Dinheiro como padrão
      log("Formas originais vazias, usando dinheiro como padrão");
    } else {
      formasOriginaisList = formasOriginais
          .split(',')
          .where((f) => f.trim().isNotEmpty)
          .map((f) => f.trim())
          .toList();
    }
    
    // ✅ CORREÇÃO: Construir lista atual mais robusta
    List<String> formasAtuais = [];
    for (int i = 0; i < isSelected.length; i++) {
      if (isSelected[i]) {
        formasAtuais.add((i + 1).toString());
      }
    }
    
    // ✅ FALLBACK: Se nenhuma forma atual selecionada, manter as originais
    if (formasAtuais.isEmpty) {
      log("⚠️ Nenhuma forma de pagamento selecionada, mantendo originais");
      return false;
    }
    
    // Ordenar para comparação
    formasOriginaisList.sort();
    formasAtuais.sort();
    
    log("Formas originais: $formasOriginaisList");
    log("Formas atuais: $formasAtuais");
    
    bool alteracao = !_listasIguais(formasOriginaisList, formasAtuais);
    
    if (alteracao) {
      log("✅ Formas de pagamento alteradas");
    } else {
      log("Formas de pagamento inalteradas");
    }
    
    return alteracao;
  }

  // Método auxiliar para comparar listas
  bool _listasIguais(List<String> lista1, List<String> lista2) {
    if (lista1.length != lista2.length) {
      log("Listas têm tamanhos diferentes: ${lista1.length} vs ${lista2.length}");
      return false;
    }
    
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i] != lista2[i]) {
        log("Diferença no índice $i: '${lista1[i]}' vs '${lista2[i]}'");
        return false;
      }
    }
    
    return true;
  }

  // Método para verificar alteração nos horários específicos
  bool _verificarAlteracaoHorariosEspecificos(BancaModel banca) {
    // Se não há horários específicos originais, mas agora há alguns configurados
    if ((banca.horariosFuncionamento == null || banca.horariosFuncionamento!.isEmpty) &&
        verificarDiasSelecionados()) {
      return true;
    }
    
    // Implementar comparação mais detalhada se necessário
    return false;
  }

  // Método para validar e limpar horários
  Map<String, Map<String, String>> _validarELimparHorarios(BancaModel banca) {
    Map<String, Map<String, String>> horariosLimpos = {};
    
    // ✅ CORREÇÃO PRINCIPAL: Se não há dias selecionados, usar horários gerais
    if (!verificarDiasSelecionados()) {
      String horarioAbertura = horarioAberturaController.text.trim();
      String horarioFechamento = horarioFechamentoController.text.trim();
      
      // Se horários gerais estão vazios, usar os originais da banca
      if (horarioAbertura.isEmpty) {
        horarioAbertura = banca.horarioAbertura ?? '';
      }
      if (horarioFechamento.isEmpty) {
        horarioFechamento = banca.horarioFechamento ?? '';
      }
      
      // Validar formato dos horários gerais
      if (_validarFormatoHorario(horarioAbertura) && _validarFormatoHorario(horarioFechamento)) {
        log("Usando horários gerais validados: $horarioAbertura - $horarioFechamento");
        
        // Aplicar para todos os dias
        List<String> diasSemana = ['segunda-feira', 'terca-feira', 'quarta-feira', 
                                  'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
        
        for (String dia in diasSemana) {
          horariosLimpos[dia] = {
            'abertura': horarioAbertura,
            'fechamento': horarioFechamento
          };
        }
      } else {
        log("⚠️ Horários gerais inválidos, tentando usar horários originais da banca");
        // Tentar usar horários originais da banca
        if (banca.horariosFuncionamento != null) {
          return _processarHorariosOriginais(banca.horariosFuncionamento!);
        }
      }
    } else {
      // Processar horários específicos por dia
      for (int i = 0; i < diasSelecionados.length; i++) {
        if (diasSelecionados[i]) {
          String nomeDia = convertIndexToDiaSemana(i);
          String abertura = horariosFuncionamento[nomeDia]?['abertura'] ?? '';
          String fechamento = horariosFuncionamento[nomeDia]?['fechamento'] ?? '';
          
          if (_validarFormatoHorario(abertura) && _validarFormatoHorario(fechamento)) {
            horariosLimpos[nomeDia] = {
              'abertura': abertura,
              'fechamento': fechamento
            };
            log("Horário validado para $nomeDia: $abertura - $fechamento");
          } else {
            log("⚠️ Horário inválido para $nomeDia: abertura='$abertura', fechamento='$fechamento'");
          }
        }
      }
    }
    
    return horariosLimpos;
  }

  // Método para processar horários originais da banca
  Map<String, Map<String, String>> _processarHorariosOriginais(Map<String, dynamic> horariosOriginais) {
    Map<String, Map<String, String>> horariosProcessados = {};
    
    horariosOriginais.forEach((dia, valores) {
      String abertura = '';
      String fechamento = '';
      
      if (valores is Map) {
        abertura = valores['abertura']?.toString() ?? '';
        fechamento = valores['fechamento']?.toString() ?? '';
      } else if (valores is List && valores.length >= 2) {
        abertura = valores[0]?.toString() ?? '';
        fechamento = valores[1]?.toString() ?? '';
      }
      
      if (_validarFormatoHorario(abertura) && _validarFormatoHorario(fechamento)) {
        String diaCorreto = _normalizarNomeDia(dia);
        horariosProcessados[diaCorreto] = {
          'abertura': abertura,
          'fechamento': fechamento
        };
      }
    });
    
    return horariosProcessados;
  }

    // Validação atualizada para considerar os dias específicos
    bool verifyFieldsForEdit() {
      // Verificar se pelo menos um dia de funcionamento foi selecionado e configurado
      if (!verificarDiasSelecionados()) {
        // Se nenhum dia está configurado, verificar se os horários gerais estão preenchidos
        if (horarioAberturaController.text.isEmpty || horarioFechamentoController.text.isEmpty) {
          textoErro = 'Configure pelo menos um dia de funcionamento ou preencha os horários gerais';
          return false;
        }
      }
      
      // Verificar se forma de pagamento foi selecionada
      if (!isSelected.contains(true)) {
        textoErro = 'Selecione pelo menos uma forma de pagamento';
        return false;
      }
      
      // Verificar PIX se estiver selecionado
      if (isSelected[1] && pixController.text.isEmpty) {
        textoErro = 'Insira a chave PIX';
        return false;
      }
      
      return true;
    }

  void toggleDiaSemana(int index) {
    diasSelecionados[index] = !diasSelecionados[index];
    
    // Se desmarcar o dia, limpar os horários desse dia
    if (!diasSelecionados[index]) {
      String nomeDia = convertIndexToDiaSemana(index);
      horariosFuncionamento[nomeDia] = {'abertura': '', 'fechamento': ''};
    }
    
    update();
  }

  void definirHorarioDia(int index, String abertura, String fechamento) {
    String nomeDia = convertIndexToDiaSemana(index);
    print("Definindo horário para $nomeDia: abertura=$abertura, fechamento=$fechamento");
    
    horariosFuncionamento[nomeDia] = {'abertura': abertura, 'fechamento': fechamento};
    diasSelecionados[index] = true;
    
    print("Horários configurados: ${horariosFuncionamento[nomeDia]}");
    update();
  }

  String convertIndexToDiaSemana(int index) {
    switch (index) {
    case 0: return 'segunda-feira';
    case 1: return 'terca-feira';
    case 2: return 'quarta-feira';
    case 3: return 'quinta-feira';
    case 4: return 'sexta-feira';
    case 5: return 'sábado';
    case 6: return 'domingo';
    default: return 'segunda-feira';
    }
  }

  bool verificarDiasSelecionados() {
    for (int i = 0; i < diasSelecionados.length; i++) {
      if (diasSelecionados[i]) {
        String nomeDia = convertIndexToDiaSemana(i);
        if (horariosFuncionamento[nomeDia]?['abertura']?.isNotEmpty == true &&
            horariosFuncionamento[nomeDia]?['fechamento']?.isNotEmpty == true) {
          return true;
        }
      }
    }
    return false;
  }

  void editBanca(BuildContext context, BancaModel banca) async {
    String nome = _nomeBancaController.text.trim();
    String horarioAbertura = _horarioAberturaController.text.trim();
    String horarioFechamento = _horarioFechamentoController.text.trim();
    String precoMin = _quantiaMinController.text.trim();
    String pix = _pixController.text.trim();

    log("Editando banca: Nome: ${nome.isEmpty ? 'não alterado' : nome}");
    log("Horário Abertura: ${horarioAbertura.isEmpty ? 'não alterado' : horarioAbertura}");
    log("Horário Fechamento: ${horarioFechamento.isEmpty ? 'não alterado' : horarioFechamento}");
    log("Preço Min: ${precoMin.isEmpty ? 'não alterado' : precoMin}");
    log("PIX: ${pix.isEmpty ? 'não alterado' : pix}");
    log("Imagem selecionada: ${_imagePath == null ? 'não alterada' : 'nova imagem'}");
    
    // Log dos horários específicos
    log("Dias selecionados: ${diasSelecionados}");
    for (int i = 0; i < diasSemana.length; i++) {
      if (diasSelecionados[i]) {
        String nomeDia = convertIndexToDiaSemana(i);
        log("Dia ${diasSemana[i]}: Abertura=${horariosFuncionamento[nomeDia]?['abertura']}, Fechamento=${horariosFuncionamento[nomeDia]?['fechamento']}");
      }
    }
    
    // Mostrar loading
    mostrarLoading(context);
    
    try {
      // Verificar se horários gerais podem ser usados como fallback
      if (!verificarDiasSelecionados() && horarioAbertura.isNotEmpty && horarioFechamento.isNotEmpty) {
        log("Usando horários gerais para todos os dias na edição");
        // Preencher horários de todos os dias com os horários gerais
        horariosFuncionamento = {
          'segunda-feira': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'terca-feira': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'quarta-feira': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'quinta-feira': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'sexta-feira': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'sábado': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
          'domingo': {'abertura': horarioAbertura, 'fechamento': horarioFechamento},
        };
        // Marcar todos os dias como selecionados
        diasSelecionados = List.filled(7, true);
        update();
      }
      
      // Usar o novo método que suporta horários específicos
      editSucess = await myStoreRepository.editarBancaComHorarios(
          nome,
          horarioAbertura,
          horarioFechamento,
          precoMin,
          feira,
          _imagePath,
          isSelected,
          pix,
          deliver,
          banca,
          horariosFuncionamento); // Passar os horários específicos
          
      // Remover loading
      removerLoading();
          
      if (editSucess) {
        // Tenta atualizar o HomeScreenController se estiver disponível
        if (Get.isRegistered<HomeScreenController>()) {
          final homeController = Get.find<HomeScreenController>();
          homeController.reloadEverything(); // Recarregar tudo do zero
        }
        
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => DefaultAlertDialogOneButton(
            title: 'Sucesso',
            body: 'Sua banca foi editada com sucesso',
            confirmText: 'Ok',
            onConfirm: () {
              Get.offAll(() => const HomeScreen());
            },
            buttonColor: kSuccessColor,
          )
        );
      } else {
        if (nome.isEmpty && !verificarDiasSelecionados() && horarioAbertura.isEmpty && horarioFechamento.isEmpty) {
          textoErro = "Nenhuma alteração foi feita";
        } else if (!isSelected.contains(true)) {
          textoErro = "Adicione pelo menos um método de pagamento";
        } else if (isSelected[1] && pix.isEmpty) {
          textoErro = "Insira a chave PIX";
        } else {
          textoErro = "Ocorreu um erro ao editar a banca. Verifique os campos e tente novamente.";
          log("Ocorreu um erro, verifique os campos");
        }
        
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => DefaultAlertDialogOneButton(
            title: 'Erro',
            body: textoErro,
            confirmText: 'Ok',
            onConfirm: () {
              Get.back();
            },
            buttonColor: kAlertColor,
          )
        );
      }
    } catch (e) {
      removerLoading();
      log("Erro ao editar banca: $e");
      Get.dialog(
        AlertDialog(
          title: const Text('Erro'),
          content: Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
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

  void mostrarLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void removerLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void adicionarBanca(BuildContext context) async {
    // Mostrar loading
    mostrarLoading(context);
    
    try {
      print("Horários gerais: Abertura=${_horarioAberturaController.text}, Fechamento=${_horarioFechamentoController.text}");
      print("Dias selecionados: ${diasSelecionados}");
      
      // Imprimir horários configurados para cada dia
      for (int i = 0; i < diasSemana.length; i++) {
        if (diasSelecionados[i]) {
          String nomeDia = convertIndexToDiaSemana(i);
          print("Dia ${diasSemana[i]}: Abertura=${horariosFuncionamento[nomeDia]?['abertura']}, Fechamento=${horariosFuncionamento[nomeDia]?['fechamento']}");
        }
      }
      
      // Verificar se horários gerais podem ser usados como fallback
      if (!verificarDiasSelecionados() && _horarioAberturaController.text.isNotEmpty && _horarioFechamentoController.text.isNotEmpty) {
        print("Usando horários gerais para todos os dias");
        // Preencher horários de todos os dias com os horários gerais
        horariosFuncionamento = {
          'segunda-feira': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'terca-feira': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'quarta-feira': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'quinta-feira': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'sexta-feira': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'sábado': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
          'domingo': {'abertura': _horarioAberturaController.text, 'fechamento': _horarioFechamentoController.text},
        };
        // Marcar todos os dias como selecionados
        diasSelecionados = List.filled(7, true);
        update();
      } else if (!verificarDiasSelecionados()) {
        removerLoading();
        Get.snackbar(
          'Erro', 
          'Configure pelo menos um dia de funcionamento ou preencha os horários gerais',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      adcSucess = await myStoreRepository.adicionarBanca(
        _nomeBancaController.text,
        _horarioAberturaController.text,
        _horarioFechamentoController.text,
        _quantiaMinController.text,
        feira,
        _imagePath,
        isSelected,
        deliver,
        _pixController.text,
        horariosFuncionamento
      );
        
      // Remover loading
      removerLoading();
        
      if (adcSucess) {
        // Tenta atualizar o HomeScreenController se estiver disponível
        if (Get.isRegistered<HomeScreenController>()) {
          final homeController = Get.find<HomeScreenController>();
          homeController.reloadEverything(); // Recarregar tudo do zero
        }
        
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => DefaultAlertDialogOneButton(
            title: 'Sucesso',
            body: 'Sua banca foi criada',
            confirmText: 'Ok',
            onConfirm: () {
              Get.offAll(() => const HomeScreen());
            },
            buttonColor: kSuccessColor,
          )
        );
      } else {
        if (_nomeBancaController.text.isEmpty == true) {
          textoErro = "Insira um nome";
        } else if (!isSelected.contains(true)) {
          textoErro = "Adicione pelo menos um método de pagamento";
        } else if (isSelected[1] && _pixController.text.isEmpty) {
          textoErro = "Insira a chave PIX";
        } else {
          textoErro = "Ocorreu um erro ao adicionar a banca. Verifique os campos e tente novamente.";
          log("Ocorreu um erro, verifique os campos");
        }
        
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => DefaultAlertDialogOneButton(
            title: 'Erro',
            body: textoErro,
            confirmText: 'Ok',
            onConfirm: () {
              Get.back();
            },
            buttonColor: kAlertColor,
          )
        );
      }
    } catch (e) {
      removerLoading();
      log("Erro ao adicionar banca: $e");
      Get.dialog(
        AlertDialog(
          title: const Text('Erro'),
          content: Text("${e.toString()}\n Procure o suporte com a equipe LMTS"),
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

  bool verifySelectedFields() {
    // Verificamos se pelo menos uma forma de pagamento foi selecionada
    return isSelected.contains(true);
  }

  bool verifyFields() {

    // Verificar nome da banca
    if (nomeBancaController.text.isEmpty) {
      textoErro = 'Preencha o nome da banca';
      return false;
    }
    
    // Verificar se pelo menos um dia de funcionamento foi selecionado e configurado
    if (!verificarDiasSelecionados()) {
      // Se nenhum dia está configurado, então verificamos se os horários gerais estão preenchidos
      if (horarioAberturaController.text.isEmpty || horarioFechamentoController.text.isEmpty) {
        textoErro = 'Configure pelo menos um dia de funcionamento ou preencha os horários gerais';
        return false;
      }
    }
    
    // Verificar se forma de pagamento foi selecionada
    if (!isSelected.contains(true)) {
      textoErro = 'Selecione pelo menos uma forma de pagamento';
      return false;
    }
    
    // Verificar PIX se estiver selecionado
    if (isSelected[1] && pixController.text.isEmpty) {
      textoErro = 'Insira a chave PIX';
      return false;
    }
    
    return true;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    loadFeiras();
    update();
  }
}