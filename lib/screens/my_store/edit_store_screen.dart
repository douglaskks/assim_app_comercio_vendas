// ignore_for_file: avoid_print
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:thunderapp/components/buttons/primary_button.dart';
import 'package:thunderapp/components/utils/vertical_spacer_box.dart';
import 'package:thunderapp/screens/home/home_screen.dart';
import 'package:thunderapp/screens/my_store/my_store_controller.dart';
import 'package:thunderapp/shared/constants/app_enums.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import '../../components/forms/custom_text_form_field.dart';
import '../../shared/components/dialogs/default_alert_dialog.dart';
import 'components/circle_image_profile.dart';
import 'dart:developer';

//TELA ASSIM - Edição de banca
class EditStoreScreen extends StatefulWidget {
  final BancaModel? bancaModel; // CORREÇÃO: final ao invés de variável

  const EditStoreScreen(this.bancaModel, {Key? key}) : super(key: key); // CORREÇÃO: const

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  String? startTime;
  String? endTime;

  @override
  void initState() {
    super.initState();

    final MyStoreController controller = Get.put(MyStoreController());
    
    if (widget.bancaModel != null) {
      // USAR O MÉTODO ESPECÍFICO para carregar todos os dados da banca
      controller.carregarDadosBancaParaEdicao(widget.bancaModel!);
    } else {
      // Valores padrão caso bancaModel seja nulo
      controller.nomeBancaController.clear();
      controller.horarioAberturaController.clear();
      controller.horarioFechamentoController.clear();
      controller.quantiaMinController.clear();
      controller.pixController.clear();
      
      controller.isSelected[0] = true; // Dinheiro habilitado por padrão
      controller.delivery[1] = true; // "Não" para entregas por padrão
      controller.pixBool = false;
      
      // Resetar dias e horários
      controller.diasSelecionados = List.filled(7, false);
      controller.horariosFuncionamento = {
        'segunda-feira': {'abertura': '', 'fechamento': ''},
        'terca-feira': {'abertura': '', 'fechamento': ''},
        'quarta-feira': {'abertura': '', 'fechamento': ''},
        'quinta-feira': {'abertura': '', 'fechamento': ''},
        'sexta-feira': {'abertura': '', 'fechamento': ''},
        'sábado': {'abertura': '', 'fechamento': ''},
        'domingo': {'abertura': '', 'fechamento': ''},
      };
    }
  }

  String _formatTimeOfDayTo24Hour(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final double? doubleFrete =
        double.tryParse(widget.bancaModel?.precoMin ?? '0');
    final String freteCorreto =
        doubleFrete != null ? doubleFrete.toStringAsFixed(2) : '0.00';
    Size size = MediaQuery.of(context).size;

    return GetBuilder<MyStoreController>(
        init: MyStoreController(),
        builder: (controller) => GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: kPrimaryColor,
                    iconTheme: const IconThemeData(color: Colors.white),
                    centerTitle: true,
                    title: Text(
                      'Editar banca',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: size.height * 0.030
                      ),
                    ),
                    automaticallyImplyLeading: true,
                  ),
                  body: SingleChildScrollView(
                    child: Form(
                      key: controller.formKey,
                      child: Container(
                          padding: const EdgeInsets.only(
                              top: 20,
                              left: 26,
                              right: 26,
                              bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagem do perfil
                              Center(
                                child: CircleImageProfile(controller),
                              ),
                              Divider(
                                height: size.height * 0.016,
                                color: Colors.transparent,
                              ),
                              
                              const VerticalSpacerBox(size: SpacerSize.small),
                              
                              // Nome da banca
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nome da banca',
                                    style: TextStyle(
                                        color: kSecondaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: size.height * 0.018),
                                  ),
                                  SizedBox(
                                    width: size.width,
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      elevation: 0,
                                      child: ClipPath(
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: CustomTextFormField(
                                            autoValidate: AutovalidateMode.onUserInteraction,
                                            // ✅ CORREÇÃO: Não usar hintText para dados existentes, o controller já tem o valor
                                            hintText: controller.nomeBancaController.text.isEmpty 
                                                ? 'Digite o nome da banca' 
                                                : null,
                                            erroStyle: const TextStyle(fontSize: 12),
                                            validatorError: (value) {
                                              if (value.isNotEmpty && value.length < 3) {
                                                return 'O nome deve ter no mínimo 3 caracteres';
                                              }
                                              return null;
                                            },
                                            controller: controller.nomeBancaController,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const VerticalSpacerBox(size: SpacerSize.small),
                              Divider(
                                height: size.height * 0.01,
                                color: Colors.transparent,
                              ),
                              
                              // Seção de Dias de Funcionamento
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    height: size.height * 0.025,
                                    color: Colors.transparent,
                                  ),
                                  Text(
                                    'Dias de Funcionamento',
                                    style: TextStyle(
                                      fontSize: size.height * 0.018,
                                      color: kSecondaryColor,
                                      fontWeight: FontWeight.w700
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                                    child: Text(
                                      'Selecione os dias em que a banca funciona e configure horários específicos',
                                      style: TextStyle(
                                        fontSize: size.height * 0.014,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: List.generate(
                                      controller.diasSemana.length,
                                      (index) => FilterChip(
                                        selectedColor: kPrimaryColor.withOpacity(0.2),
                                        checkmarkColor: kPrimaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                          side: BorderSide(
                                            color: controller.diasSelecionados[index] 
                                                ? kPrimaryColor 
                                                : Colors.grey,
                                            width: 1.0,
                                          ),
                                        ),
                                        label: Text(
                                          controller.diasSemana[index],
                                          style: TextStyle(
                                            color: controller.diasSelecionados[index] 
                                                ? kPrimaryColor 
                                                : kSecondaryColor,
                                          ),
                                        ),
                                        selected: controller.diasSelecionados[index],
                                        onSelected: (_) {
                                          if (!controller.diasSelecionados[index]) {
                                            // Se o dia está sendo selecionado
                                            _mostrarDialogConfiguracaoHorarioEdicao(context, controller, index);
                                          } else {
                                            // Se o dia está sendo desmarcado
                                            controller.toggleDiaSemana(index);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              Divider(
                                height: size.height * 0.018,
                                color: Colors.transparent,
                              ),
                              
                              // Formas de Pagamento
                              Text('Formas de Pagamento',
                                  style: kTitle1.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: size.height * 0.018,
                                      color: kSecondaryColor)),
                              SizedBox(
                                width: size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Dinheiro
                                    Flexible(
                                      child: ListTileTheme(
                                        horizontalTitleGap: 0,
                                        child: CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: kPrimaryColor,
                                          value: controller.isSelected[0],
                                          title: Text(
                                            controller.checkItems[0],
                                            style: TextStyle(fontSize: size.height * 0.016),
                                          ),
                                          checkboxShape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          onChanged: (value) => controller.onItemTapped(0),
                                        ),
                                      ),
                                    ),
                                    
                                    // PIX
                                    Flexible(
                                      child: ListTileTheme(
                                        horizontalTitleGap: 0,
                                        child: CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: kPrimaryColor,
                                          value: controller.isSelected[1],
                                          title: Text(
                                            controller.checkItems[1],
                                            style: TextStyle(fontSize: size.height * 0.016),
                                          ),
                                          checkboxShape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          onChanged: (value) {
                                            controller.onItemTapped(1);
                                            controller.setPixBool(controller.isSelected[1]);
                                            print("valor do pix: ${controller.pixBool}");
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Chave PIX (exibida apenas se PIX estiver selecionado)
                              Visibility(
                                visible: controller.pixBool,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const VerticalSpacerBox(size: SpacerSize.small),
                                    Text(
                                      'Chave Pix',
                                      style: TextStyle(
                                          fontSize: size.height * 0.018,
                                          color: kSecondaryColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    IntrinsicWidth(
                                      stepWidth: size.width,
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: 0,
                                        child: ClipPath(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: CustomTextFormField(
                                              autoValidate: AutovalidateMode.onUserInteraction,
                                              enabled: controller.pixBool,
                                              erroStyle: const TextStyle(fontSize: 12),
                                              validatorError: (value) {
                                                if (controller.pixBool == true) {
                                                  if (value.isEmpty) {
                                                    return 'Obrigatório';
                                                  }
                                                }
                                                return null;
                                              },
                                              // ✅ CORREÇÃO: Só usar hintText se o campo estiver vazio
                                              hintText: controller.pixController.text.isEmpty 
                                                  ? "Digite a chave PIX" 
                                                  : null,
                                              controller: controller.pixController,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const VerticalSpacerBox(size: SpacerSize.small),
                              
                              // Valor mínimo para frete (exibido apenas se entregas estiver ativo)
                              Visibility(
                                visible: controller.delivery[0],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      height: size.height * 0.025,
                                      color: Colors.transparent,
                                    ),
                                    Text('Valor mínimo para frete',
                                        style: kTitle1.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: size.height * 0.018,
                                            color: kSecondaryColor)),
                                    SizedBox(
                                      width: size.width,
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: 0,
                                        child: ClipPath(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: CustomTextFormFieldCurrency(
                                              autoValidate: AutovalidateMode.onUserInteraction,
                                              enabled: controller.delivery[0],
                                              erroStyle: const TextStyle(fontSize: 12),
                                              validatorError: (value) {
                                                if (controller.delivery[0] == true) {
                                                  if (value.isEmpty) {
                                                    return 'Obrigatório';
                                                  }
                                                }
                                                return null;
                                              },
                                              hintText: "R\$ $freteCorreto",
                                              currencyFormatter: <TextInputFormatter>[
                                                CurrencyTextInputFormatter.currency(
                                                  locale: 'pt_BR',
                                                  symbol: 'R\$',
                                                  decimalDigits: 2,
                                                ),
                                                LengthLimitingTextInputFormatter(8),
                                              ],
                                              keyboardType: TextInputType.number,
                                              controller: controller.quantiaMinController,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const VerticalSpacerBox(size: SpacerSize.large),
                              
                              // Botão Salvar
                              SizedBox(
                                width: size.width,
                                height: size.height * 0.06,
                                child: PrimaryButton(
                                  text: 'Salvar',
                                  onPressed: () async {
                                    log("=== INICIANDO PROCESSO DE SALVAMENTO ===");
                                    log("Validando formulário...");
                                    
                                    if (controller.formKey.currentState?.validate() ?? false) {
                                      log("✅ Formulário validado com sucesso.");
                                      
                                      // ✅ CORREÇÃO: Validação mais robusta
                                      if (controller.verifySelectedFields()) {
                                        log("✅ Campos selecionados válidos.");
                                        
                                        // Mostrar loading
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(child: CircularProgressIndicator()),
                                        );
                                        
                                        try {
                                          // ✅ CORREÇÃO: Usar o método corrigido
                                          bool success = await controller.editBancaComHorarios(context, widget.bancaModel!);
                                          
                                          // Fechar loading se ainda montado
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                            
                                            if (success) {
                                              log("✅ Edição realizada com sucesso!");
                                              showDialog(
                                                context: context,
                                                builder: (context) => DefaultAlertDialogOneButton(
                                                  title: 'Sucesso',
                                                  body: 'Suas informações foram alteradas com sucesso',
                                                  confirmText: 'Ok',
                                                  onConfirm: () {
                                                    Get.offAll(() => const HomeScreen());
                                                  },
                                                  buttonColor: kSuccessColor, // ✅ CORREÇÃO: Usar cor de sucesso
                                                ),
                                              );
                                            } else {
                                              log("❌ Falha na edição da banca");
                                              _showSnackbar(context, "Nenhuma alteração foi feita ou ocorreu um erro. Verifique os campos e tente novamente.");
                                            }
                                          }
                                        } catch (e) {
                                          log("❌ Erro durante o salvamento: $e");
                                          if (mounted) {
                                            Navigator.of(context).pop(); // Fechar loading
                                            _showSnackbar(context, "Erro inesperado. Tente novamente.");
                                          }
                                        }
                                      } else {
                                        log("❌ Validação de campos falhou: ${controller.textoErro}");
                                        showDialog(
                                          context: context,
                                          builder: (context) => DefaultAlertDialogOneButton(
                                            title: 'Erro',
                                            body: controller.textoErro,
                                            confirmText: 'Voltar',
                                            onConfirm: () => Get.back(),
                                            buttonColor: kAlertColor,
                                          ),
                                        );
                                      }
                                    } else {
                                      log("❌ Formulário não validado.");
                                      _showSnackbar(context, "Por favor, corrija os erros nos campos destacados.");
                                    }
                                  }
                                ),
                              ),
                              
                              // Botão Voltar
                              Divider(height: size.height * 0.015, color: Colors.transparent),
                              SizedBox(
                                width: size.width,
                                height: size.height * 0.06,
                                child: OutlinedButton(
                                  onPressed: () => Get.off(() => const HomeScreen()),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: kPrimaryColor, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                    'Voltar',
                                    style: TextStyle(
                                        color: kPrimaryColor,
                                        fontSize: size.height * 0.024,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          )),
                    ),
                  )),
            ));
  }

  void _mostrarDialogConfiguracaoHorarioEdicao(
    BuildContext context, MyStoreController controller, int index) {
    // Valores padrão para os horários
    TimeOfDay horarioAbertura = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay horarioFechamento = const TimeOfDay(hour: 18, minute: 0);
    
    // Verificar se já existem horários configurados para este dia
    String nomeDia = controller.convertIndexToDiaSemana(index);
    if (controller.horariosFuncionamento[nomeDia]?['abertura']?.isNotEmpty == true) {
      final aberturaParts = controller.horariosFuncionamento[nomeDia]!['abertura']!.split(':');
      if (aberturaParts.length >= 2) {
        horarioAbertura = TimeOfDay(
          hour: int.tryParse(aberturaParts[0]) ?? 8, 
          minute: int.tryParse(aberturaParts[1]) ?? 0
        );
      }
    }
    
    if (controller.horariosFuncionamento[nomeDia]?['fechamento']?.isNotEmpty == true) {
      final fechamentoParts = controller.horariosFuncionamento[nomeDia]!['fechamento']!.split(':');
      if (fechamentoParts.length >= 2) {
        horarioFechamento = TimeOfDay(
          hour: int.tryParse(fechamentoParts[0]) ?? 18, 
          minute: int.tryParse(fechamentoParts[1]) ?? 0
        );
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Horário para ${controller.diasSemana[index]}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Horário de abertura'),
                subtitle: Text(_formatTimeOfDayTo24Hour(horarioAbertura)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    cancelText: "Cancelar",
                    confirmText: "Confirmar",
                    hourLabelText: "Horas",
                    minuteLabelText: "Minutos",
                    helpText: "Insira o horário:",
                    initialTime: horarioAbertura,
                    initialEntryMode: TimePickerEntryMode.inputOnly,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: kPrimaryColor,
                            onPrimary: Colors.white,
                            onSurface: kPrimaryColor,
                          ),
                        ),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                    },
                  );
                  
                  if (selectedTime != null) {
                    setState(() {
                      horarioAbertura = selectedTime;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Horário de fechamento'),
                subtitle: Text(_formatTimeOfDayTo24Hour(horarioFechamento)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    cancelText: "Cancelar",
                    confirmText: "Confirmar",
                    hourLabelText: "Horas",
                    minuteLabelText: "Minutos",
                    helpText: "Insira o horário:",
                    initialTime: horarioFechamento,
                    initialEntryMode: TimePickerEntryMode.inputOnly,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: kPrimaryColor,
                            onPrimary: Colors.white,
                            onSurface: kPrimaryColor,
                          ),
                        ),
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                              alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                    },
                  );
                  
                  if (selectedTime != null) {
                    setState(() {
                      horarioFechamento = selectedTime;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final formattedAbertura = _formatTimeOfDayTo24Hour(horarioAbertura);
                final formattedFechamento = _formatTimeOfDayTo24Hour(horarioFechamento);
                
                // Verificar se o horário de fechamento é maior que o de abertura
                if (_isClosingTimeInvalid(formattedAbertura, formattedFechamento)) {
                  _showSnackbar(context, "O horário de fechamento deve ser maior que o de abertura.");
                  return;
                }
                
                controller.definirHorarioDia(
                  index, 
                  formattedAbertura, 
                  formattedFechamento
                );
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  // Funções auxiliares
  bool _isClosingTimeInvalid(String abertura, String fechamento) {
    if (abertura.isEmpty || fechamento.isEmpty) return false;

    try {
      final aberturaParts = abertura.split(":").map(int.parse).toList();
      final fechamentoParts = fechamento.split(":").map(int.parse).toList();

      if (aberturaParts.length < 2 || fechamentoParts.length < 2) return false;

      final aberturaMinutes = aberturaParts[0] * 60 + aberturaParts[1];
      final fechamentoMinutes = fechamentoParts[0] * 60 + fechamentoParts[1];

      return fechamentoMinutes <= aberturaMinutes;
    } catch (e) {
      print("Erro ao validar horários: $e");
      return false;
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}