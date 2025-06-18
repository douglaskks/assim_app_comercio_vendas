import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/products_model.dart';

import '../edit_products_controller.dart';
import 'stock_edit_product.dart';

class DropDownQtdEditProduct extends StatefulWidget {
  final EditProductsController controller;
  ProductsModel? model;

  DropDownQtdEditProduct(this.controller, this.model, {Key? key})
      : super(key: key);

  @override
  State<DropDownQtdEditProduct> createState() =>
      _DropDownQtdEditProductState();
}

class _DropDownQtdEditProductState extends State<DropDownQtdEditProduct> {
  final dropValue = ValueNotifier('');

  final dropOpcoes = [
    'Unidade',
    'Peso',
    'Molho',
    'Kg',
    'Litro',
    'Pote',
    'Dúzia',
    'Mão',
    'Arroba',
    'Bandeja',
  ];

  @override
  void initState() {
    super.initState();
    // ✅ CORREÇÃO: Verificação segura com null check
    String? tipoMedida = widget.model?.tipoMedida;
    if (tipoMedida != null && dropOpcoes.contains(tipoMedida)) {
      dropValue.value = tipoMedida;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Unidade de medida',
                style: TextStyle(
                  fontSize: size.height * 0.018,
                  color: kSecondaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              alignment: AlignmentDirectional.centerStart,
              width: size.width * 0.4,
              child: GetBuilder<EditProductsController>(
                builder: (controller) {
                  return ValueListenableBuilder(
                    valueListenable: dropValue,
                    builder: (BuildContext context, String value, _) {
                      // ✅ CORREÇÃO: Verificação segura sem null check operator
                      String? currentValue;
                      
                      // Prioridade 1: Valor do controller se válido
                      if (controller.measure.isNotEmpty && dropOpcoes.contains(controller.measure)) {
                        currentValue = controller.measure;
                      } 
                      // Prioridade 2: Valor do dropdown se válido
                      else if (value.isNotEmpty && dropOpcoes.contains(value)) {
                        currentValue = value;
                      } 
                      // Prioridade 3: Valor original do modelo se válido
                      else {
                        String? modelTipoMedida = widget.model?.tipoMedida;
                        if (modelTipoMedida != null && dropOpcoes.contains(modelTipoMedida)) {
                          currentValue = modelTipoMedida;
                        }
                      }

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: kDetailColor,
                          size: size.width * 0.05,
                        ),
                        hint: Text(
                          widget.model?.tipoMedida ?? 'Selecionar',
                          style: TextStyle(fontSize: size.height * 0.018),
                        ),
                        value: currentValue,
                        onChanged: (escolha) {
                          if (escolha != null) {
                            setState(() {
                              dropValue.value = escolha;
                              widget.controller.setMeasure(escolha);
                            });
                          }
                        },
                        items: dropOpcoes
                            .map(
                              (op) => DropdownMenuItem(
                                value: op,
                                child: Text(op),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          errorStyle: TextStyle(fontSize: 12),
                        ),
                        validator: (dropValue) {
                          // ✅ CORREÇÃO: Validação mais segura
                          if (dropValue == null || dropValue.isEmpty) {
                            String? originalMedida = widget.model?.tipoMedida;
                            // Se não tem valor selecionado E não tem valor original válido
                            if (originalMedida == null || originalMedida.isEmpty) {
                              return 'Obrigatório';
                            }
                            // Se tem valor original válido, não é erro
                            return null;
                          }
                          return null;
                        },
                      );
                    }
                  );
                }
              ),
            ),
          ],
        ),
        StockEditProduct(widget.controller, widget.model),
      ],
    );
  }
}