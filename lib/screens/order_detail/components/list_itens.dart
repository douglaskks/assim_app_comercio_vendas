import 'package:flutter/material.dart';
import 'package:thunderapp/screens/orders/orders_controller.dart';

class ItensPedidoWidget extends StatelessWidget {
  final int pedidoId;
  final OrdersController controller; // Modificado: agora recebe o controller como parâmetro

  // Modificado: controller adicionado como parâmetro obrigatório
  ItensPedidoWidget({
    super.key, 
    required this.pedidoId,
    required this.controller
  });

  @override
  Widget build(BuildContext context) {
    var itens = controller.getItensDoPedido(pedidoId);

    return itens.isEmpty
        ? const Center(
            child: Text('Nenhum item encontrado'),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: itens.length,
            itemBuilder: (context, index) {
              var item = itens[index];
              return ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(  // Adicionado Expanded para evitar overflow
                      child: Text(
                        '${item.quantidade} ${item.tipoUnidade} x ${item.titulo}',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8), // Espaço entre o texto e o preço
                    Text(
                      'R\$ ${item.preco?.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          );
  }
}