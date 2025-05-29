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
    // ✅ Inicializar com valor do produto se existir
    if (widget.model?.tipoMedida != null && 
        dropOpcoes.contains(widget.model!.tipoMedida)) {
      dropValue.value = widget.model!.tipoMedida!;
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
                      // ✅ Usar o valor do controller se disponível
                      String? currentValue;
                      if (controller.measure.isNotEmpty && dropOpcoes.contains(controller.measure)) {
                        currentValue = controller.measure;
                      } else if (value.isNotEmpty) {
                        currentValue = value;
                      } else if (widget.model?.tipoMedida != null && 
                                dropOpcoes.contains(widget.model!.tipoMedida!)) {
                        currentValue = widget.model!.tipoMedida!;
                      }

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: kDetailColor,
                          size: size.width * 0.05,
                        ),
                        hint: Text(
                          widget.model?.tipoMedida?.toString() ?? 'Selecionar',
                          style: TextStyle(fontSize: size.height * 0.018),
                        ),
                        value: currentValue,
                        onChanged: (escolha) {
                          setState(() {
                            dropValue.value = escolha.toString();
                            widget.controller.setMeasure(escolha.toString());
                          });
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
                          // ✅ CORREÇÃO: Validação inteligente
                          // Se o produto já tem uma unidade de medida, não é obrigatório selecionar novamente
                          if (dropValue == null || dropValue.isEmpty) {
                            // Se não tem valor selecionado E não tem valor original, então é obrigatório
                            if (widget.model?.tipoMedida == null || 
                                widget.model!.tipoMedida!.isEmpty) {
                              return 'Obrigatório';
                            }
                            // Se tem valor original, usar ele (não é erro)
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