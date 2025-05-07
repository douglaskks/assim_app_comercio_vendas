import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thunderapp/components/forms/custom_text_form_field.dart';
import 'package:thunderapp/components/utils/vertical_spacer_box.dart';
import 'package:thunderapp/screens/forgot_password/forgot_password_controller.dart';
import 'package:thunderapp/shared/components/confirm_dialog/confirm_dialog.dart';
import 'package:thunderapp/shared/components/header_start_app/header_start_app.dart';
import 'package:thunderapp/shared/constants/app_enums.dart';
import 'package:thunderapp/shared/constants/app_number_constants.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  Future<void> _showSuccessMessage(BuildContext context) async {
    confirmDialog(
      context,
      'Email Enviado',
      'Um email de redefinição de senha foi enviado para o seu endereço de email.',
      'Cancelar',
      'Ok',
      onConfirm: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: Consumer<ForgotPasswordController>(
        builder: (context, controller, child) => Scaffold(
          backgroundColor: kPrimaryColor,
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 35),
                    child: Container(
                      child: const HeaderStartApp(),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    )
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Esqueceu a senha?',
                              style: kBody2.copyWith(color: kSecondaryColor, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const VerticalSpacerBox(size: SpacerSize.huge),
                            CustomTextFormField(
                              hintText: 'Informe o e-mail:',
                              icon: Icons.email,
                              controller: controller.emailController,
                              validatorError: (value) {
                                if (value.isEmpty) return 'Obrigatório';
                                if (value.contains(' ')) return "Digite um e-mail válido";
                                if (!value.contains('@')) return "Digite um e-mail válido";
                                return null;
                              },
                            ),
                            const VerticalSpacerBox(size: SpacerSize.huge),
                            ElevatedButton(
                              onPressed: controller.status == ForgotPasswordStatus.loading 
                                  ? null 
                                  : () async {
                                      if (controller.formKey.currentState!.validate()) {
                                        try {
                                          await controller.sendResetPasswordEmail();
                                          
                                          if (controller.status == ForgotPasswordStatus.done && context.mounted) {
                                            _showSuccessMessage(context);
                                          }
                                        } catch (e) {
                                          // O erro já está sendo tratado no controller
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                textStyle: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              child: const Text(
                                'Recuperar senha',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const VerticalSpacerBox(size: SpacerSize.medium),
                            if (controller.status == ForgotPasswordStatus.loading)
                              const Center(
                                child: CircularProgressIndicator(color: kPrimaryColor),
                              ),
                            const VerticalSpacerBox(size: SpacerSize.medium),
                            if (controller.errorMessage != null)
                              Text(
                                controller.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: kPrimaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}