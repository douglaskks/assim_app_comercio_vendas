import 'package:flutter/material.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../shared/core/models/list_banca_model.dart';
import '../home_screen_controller.dart';

// ignore: must_be_immutable
class DropDownBanca extends StatefulWidget {
  late HomeScreenController controller;

  DropDownBanca(this.controller, {Key? key}) : super(key: key);

  @override
  State<DropDownBanca> createState() => _DropDownAddProductState();
}

class _DropDownAddProductState extends State<DropDownBanca> with SingleTickerProviderStateMixin {
  final dropValue = ValueNotifier('');
  late AnimationController _animationController;
  Animation<double>? _rotationAnimation;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar o controller de animação
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Inicializar a animação de rotação
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // Meio giro (180 graus)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificação de segurança para garantir que a animação está inicializada
    if (_rotationAnimation == null) {
      _rotationAnimation = Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    }
    
    var idScreen = 0;
    Size size = MediaQuery.of(context).size;
    return Container(
      alignment: Alignment.topCenter,
      width: size.width * 0.2,
      child: DropdownButton2<ListBancaModel>(
        isExpanded: true,
        customButton: RotationTransition(
          turns: _rotationAnimation!,
          child: Icon(
            Icons.keyboard_arrow_up,
            color: kPrimaryColor,
            size: size.width * 0.1,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          width: size.width,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          offset: const Offset(0, 8),
        ),
        onMenuStateChange: (isOpen) {
          setState(() {
            _isDropdownOpen = isOpen;
            if (isOpen) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }
          });
        },
        value: null,
        items: widget.controller.bancas.map((obj) {
          return DropdownMenuItem<ListBancaModel>(
            value: obj,
            child: Text(obj.nome.toString()),
          );
        }).toList(),
        onChanged: (selectedObj) {
          int selectedIndex = widget.controller.bancas
              .indexWhere((banca) => banca.id == selectedObj!.id);
          setState(() {
            widget.controller.setBanca(selectedIndex);
            idScreen = widget.controller.banca.value;
          });
        },
      ),
    );
  }
}