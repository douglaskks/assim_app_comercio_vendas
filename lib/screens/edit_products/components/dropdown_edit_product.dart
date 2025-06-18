import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:thunderapp/screens/add_products/add_products_controller.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:thunderapp/shared/core/models/products_model.dart';
import 'package:thunderapp/shared/core/models/table_products_model.dart';

import '../edit_products_controller.dart';

// ignore: must_be_immutable
class DropDownEditProduct extends StatefulWidget {
  late EditProductsController controller;
  late ProductsModel model;

  DropDownEditProduct(this.controller, this.model, {Key? key}) : super(key: key);

  @override
  State<DropDownEditProduct> createState() => _DropDownEditProductState();
}

class _DropDownEditProductState extends State<DropDownEditProduct> {
  final dropValue = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    // ✅ PROTEÇÃO: Verificar se a lista não está vazia
    if (widget.controller.tableProducts.isEmpty) {
      log('⚠️ Lista de produtos tabelados vazia - exibindo loading');
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            width: size.width,
            height: size.height * 0.06,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Carregando produtos...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: size.height * 0.016,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ✅ CORREÇÃO: Buscar o produto tabelado correto
    TableProductsModel? produtoTabeladoCorreto;
    if (widget.model.produtoTabeladoId != null) {
      produtoTabeladoCorreto = widget.controller.search(widget.model.produtoTabeladoId);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topCenter,
          width: size.width,
          height: size.height * 0.06,
          child: DropdownButtonFormField<TableProductsModel>(
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: kPrimaryColor,
              size: size.width * 0.05,
            ),
            // ✅ CORREÇÃO: Mostrar o nome do produto tabelado, não a descrição
            hint: Text(produtoTabeladoCorreto?.nome ?? 'Selecione um produto'),
            value: produtoTabeladoCorreto,
            // ✅ PROTEÇÃO: Lista garantidamente não está vazia aqui
            items: widget.controller.tableProducts.map((obj) {
              return DropdownMenuItem<TableProductsModel>(
                value: obj,
                child: Text(obj.nome?.toString() ?? 'Produto sem nome'),
              );
            }).toList(),
            onChanged: (selectedObj) {
              if (selectedObj != null) {
                // ✅ Atualizar o produto tabelado selecionado
                widget.controller.setProductId(selectedObj.id);
                setState(() {
                  // Atualizar a interface
                });
              }
            },
          ),
        ),
      ],
    );
  }
}