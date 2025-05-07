import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thunderapp/components/forms/custom_text_form_field.dart';
import 'package:thunderapp/components/utils/vertical_spacer_box.dart';
import 'package:thunderapp/screens/forgot_password/forgot_password_screen.dart';
import 'package:thunderapp/screens/signin/sign_in_controller.dart';
import 'package:thunderapp/shared/components/header_start_app/header_start_app.dart';
import 'package:thunderapp/shared/constants/style_constants.dart';
import '../../shared/constants/app_enums.dart';
import '../../shared/constants/app_number_constants.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignInController(),
      child: Consumer<SignInController>(
        builder: (context, controller, child) => Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: kPrimaryColor,
          body: Column(
            children: [
              // Header (Parte superior verde)
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
              
              // Formulário (Parte inferior branca)
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
                              'Entrar',
                              style: kBody2.copyWith(color: kSecondaryColor, fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const VerticalSpacerBox(size: SpacerSize.huge),
                            
                            // Campo de e-mail
                            CustomTextFormField(
                              hintText: 'E-mail',
                              icon: Icons.email,
                              controller: controller.emailController,
                              validatorError: (value) {
                                if (value.isEmpty) return 'Obrigatório';
                                if (value.contains(' ')) return "Digite um e-mail válido";
                                if (!value.contains('@')) return "Digite um e-mail válido";
                                return null;
                              },
                            ),
                            
                            const VerticalSpacerBox(size: SpacerSize.small),
                            
                            // Campo de senha
                            CustomTextFormField(
                              hintText: 'Senha',
                              icon: Icons.lock,
                              isPassword: true,
                              controller: controller.passwordController,
                              validatorError: (value) {
                                if (value.isEmpty) return 'Obrigatório';
                                return null;
                              },
                            ),
                            
                            // Botão "Esqueceu a senha?"
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(color: kPrimaryColor),
                                ),
                              ),
                            ),
                            
                            const VerticalSpacerBox(size: SpacerSize.medium),
                            
                            // Botão de login
                            if (controller.status == SignInStatus.loading)
                              const Center(
                                child: CircularProgressIndicator(color: kPrimaryColor),
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  if (controller.formKey.currentState!.validate()) {
                                    controller.signIn(context);
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
                                  'Entrar',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                            const VerticalSpacerBox(size: SpacerSize.medium),
                            
                            // Mensagem de erro (se houver)
                            if (controller.errorMessage != null)
                              Text(
                                controller.errorMessage!,
                                style: kCaption1,
                                textAlign: TextAlign.center,
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