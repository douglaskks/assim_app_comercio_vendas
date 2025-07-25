import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:thunderapp/shared/constants/app_text_constants.dart';
import 'package:thunderapp/shared/core/models/banca_model.dart';
import 'package:thunderapp/shared/core/user_storage.dart';
import '../../shared/core/models/feira_model.dart';
import 'dart:math' as math;

class MyStoreRepository {
  List<String> checkItems = [];
  bool? entrega;
  FormData body = FormData.fromMap({});
  String formasPagamento = '';
  UserStorage userStorage = UserStorage();
  final Dio _dio = Dio();
  List<FeiraModel> feiras = [];
  FeiraModel feira = FeiraModel();

  Future<List<FeiraModel>> getFeiras() async {
    Dio dio = Dio();
    UserStorage userStorage = UserStorage();
    feiras = []; // Limpar a lista antes de preencher

    String? userToken = await userStorage.getUserToken();

    try {
      var response =
      await dio.get('$kBaseURL/feiras',
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $userToken"
            },
          ));

      List<dynamic> responseData = response.data['feiras'];


      for (int i = 0; i < responseData.length; i++) {
        feira = FeiraModel(
            id: responseData[i]["id"],
            nome: responseData[i]["nome"],
            descricao: responseData[i]["descricao"],
            horariosFuncionamento: responseData[i]["horarios_funcionamento"],
            /*bairroId: responseData[i]["bairro_id"],*/
            associacaoId: responseData[i]["associacao_id"]);
        feiras.add(feira);
      }

      log("Resposta da API feiras: ${response.data}");
      log("Feiras carregadas: ${feiras.length}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return feiras;
      }
    } catch (e) {
      log("Erro ao carregar feiras: $e");
    }
    return [];
  }

  Future<bool> editarBanca(
      String nome,
      String horarioAbertura,
      String horarioFechamento,
      String precoMin,
      String feiraId,
      String? imgPath,
      List<bool> isSelected,
      String pix,
      bool? entrega,
      BancaModel banca) async {
    
    // Resetar variáveis para nova edição
    formasPagamento = '';
    checkItems = [];
    
    // Verificar formas de pagamento selecionadas
    for (int i = 0; i < isSelected.length; i++) {
      if (isSelected[i] == true) {
        checkItems.add((i + 1).toString());
      }
    }
    
    // Se nenhuma forma de pagamento foi selecionada, retorna falso
    if (checkItems.isEmpty) {
      log("Erro: Nenhuma forma de pagamento selecionada");
      return false;
    }

    // Se nenhuma forma de pagamento for selecionada, considere dinheiro como padrão
    if (checkItems.isEmpty) {
      checkItems.add("1"); // Dinheiro como padrão
    }
    
    for (int i = 0; i < checkItems.length; i++) {
      formasPagamento += '${checkItems[i]},';
    }
    
    // Remove a última vírgula da string se existir alguma forma de pagamento
    if (formasPagamento.isNotEmpty) {
      formasPagamento = formasPagamento.substring(0, formasPagamento.length - 1);
    }

    String? userToken = await userStorage.getUserToken();
    if (userToken == null || userToken.isEmpty) {
      log("Erro: Token de usuário não encontrado");
      return false;
    }
    
    // Tratamento do preço mínimo (se fornecido)
    String precoMinimo = '';
    if (precoMin.isNotEmpty) {
      const find = "R\$";
      const replace = "";
      var pMinimo = precoMin.replaceAll(find, replace);
      precoMinimo = pMinimo.replaceAll(",", ".");
    }

    try {
      // Criamos um Map dinâmico para incluir apenas os campos que foram alterados
      Map<String, dynamic> formFields = {};
      
      // Adiciona campos somente se foram alterados
      if (nome.isNotEmpty) formFields["nome"] = nome;
      formFields["descricao"] = "loja"; // Campo obrigatório
      
      // Adiciona horários, usando o valor original se não for alterado
      formFields["horario_abertura"] = horarioAbertura.isNotEmpty 
          ? horarioAbertura 
          : banca.horarioAbertura;
      
      formFields["horario_fechamento"] = horarioFechamento.isNotEmpty 
          ? horarioFechamento 
          : banca.horarioFechamento;
      
      if (precoMin.isNotEmpty) formFields["preco_minimo"] = precoMinimo;
      
      // Adicionar formas de pagamento (obrigatório)
      formFields["formas_pagamento"] = formasPagamento;
      
      // Sempre enviar a entrega como boolean
      /*formFields["entrega"] = entrega == true ? "true" : "false";
      
      // Adicionar bairro de entrega apenas se entrega for true
      if (entrega == true) {
        // Corrigir formato do bairro_entrega
        formFields["bairro_entrega"] = {
          "1": "4.50"
        };
      }*/
      
      // Só envia pix se foi preenchido
      if (pix.isNotEmpty) formFields["pix"] = pix;
      
      // Adiciona imagem apenas se foi selecionada uma nova
      if (imgPath != null) {
        try {
          formFields["imagem"] = await MultipartFile.fromFile(
            imgPath,
            filename: imgPath.split(Platform.pathSeparator).last,
          );
        } catch (e) {
          log("Erro ao carregar imagem: $e");
          // Continuar sem a imagem se houver erro
        }
      }

      Map<String, dynamic> encodableFields = Map.from(formFields);
      encodableFields.removeWhere((key, value) => value is MultipartFile);

      log("Formato completo dos campos: ${jsonEncode(encodableFields)}");

      log("Campos para log: ${encodableFields.map((key, value) => MapEntry(key, value.toString()))}");

      // Cria o FormData apenas com os campos modificados
      body = FormData.fromMap(formFields);
      
      // Adicionar ID da feira 
      if (feiraId.isNotEmpty) {
        formFields["feira_id"] = int.tryParse(feiraId) ?? banca.feiraId;
      }
      
      // Cria o FormData apenas com os campos modificados
      body = FormData.fromMap(formFields);
      
      log("Campos a serem enviados: ${body.fields}");
      log("URL: $kBaseURL/bancas/${banca.getId}");

      // Enviar para a API
      Response response = await _dio.post('$kBaseURL/bancas/${banca.getId}',
        options: Options(
          headers: {
            "Authorization": "Bearer $userToken",
            "Content-Type": "multipart/form-data",
            "X-HTTP-Method-Override": "PATCH"
          },
        ),
        data: body);
          
      log("Status da resposta: ${response.statusCode}");
      log("Resposta: ${response.data}");
      
      if (response.statusCode == 200) {
        log('Banca editada com sucesso');
        return true;
      } else {
        var errorMessage = "Erro desconhecido";
        if (response.data is Map && response.data['errors'] != null) {
          errorMessage = response.data['errors'].toString();
        }
        log('Erro: $errorMessage');
        log('Erro ao editar a banca: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is DioError) {
        final dioError = e;
        if (dioError.response != null) {
          var errorData = dioError.response!.data;
          var errorMessage = "Erro desconhecido";
          
          if (errorData is Map && errorData['errors'] != null) {
            errorMessage = errorData['errors'].toString();
          }
          
          log('Erro da API: ${dioError.response!.statusCode}');
          log('Detalhes: $errorMessage');
        } else {
          log('Erro de comunicação: ${dioError.message}');
        }
      } else {
        log("Erro não tratado na edição: $e");
      }
      log("Erro completo na edição: $e");
      return false;
    }
  }

  Future<bool> editarBancaComHorarios(
    String nome,
    String horarioAbertura,
    String horarioFechamento,
    String precoMin,
    String feiraId,
    String? imgPath,
    List<bool> isSelected,
    String pix,
    bool? fazEntrega, // MUDANÇA: fazEntrega ao invés de entrega
    BancaModel banca,
    Map<String, Map<String, String>>? horariosFuncionamento) async {
  
  // Resetar variáveis para nova edição
  formasPagamento = '';
  checkItems = [];
  
  // Verificar formas de pagamento selecionadas
  for (int i = 0; i < isSelected.length; i++) {
    if (isSelected[i] == true) {
      checkItems.add((i + 1).toString());
    }
  }
  
  if (checkItems.isEmpty) {
    log("Erro: Nenhuma forma de pagamento selecionada");
    return false;
  }
  
  for (int i = 0; i < checkItems.length; i++) {
    formasPagamento += '${checkItems[i]},';
  }
  
  if (formasPagamento.isNotEmpty) {
    formasPagamento = formasPagamento.substring(0, formasPagamento.length - 1);
  }

  String? userToken = await userStorage.getUserToken();
  if (userToken == null || userToken.isEmpty) {
    log("Erro: Token de usuário não encontrado");
    return false;
  }

  String? userId = await userStorage.getUserId();
  log("=== DEBUG TOKEN ===");
  log("User ID: $userId");
  log("Token (primeiros 20 chars): ${userToken.substring(0, math.min(20, userToken.length))}...");
  log("Banca ID sendo editada: ${banca.getId}");
  log("Agricultor ID da banca: ${banca.agricultorId}");
  log("URL completa: $kBaseURL/bancas/${banca.getId}");
  
  // Verificar se o usuário é dono da banca
  if (userId != null && banca.agricultorId.toString() != userId) {
    log("⚠️ ALERTA: Usuário ($userId) tentando editar banca de outro agricultor (${banca.agricultorId})");
  }
  
  // Tratamento do preço mínimo
  String precoMinimo = '';
  if (precoMin.isNotEmpty) {
    const find = "R\$";
    const replace = "";
    var pMinimo = precoMin.replaceAll(find, replace);
    precoMinimo = pMinimo.replaceAll(",", ".");
  }

  try {
    Map<String, dynamic> formFields = {};
    
    // Adiciona campos somente se foram alterados
    if (nome.isNotEmpty) formFields["nome"] = nome;
    formFields["descricao"] = "loja";
    
    // Processar horários de funcionamento específicos
    // ✅ CORREÇÃO: Processar horários com validação rigorosa
    Map<String, List<String>> horariosFormatoAPI = {};

    if (horariosFuncionamento != null && horariosFuncionamento.isNotEmpty) {
      log("=== PROCESSANDO HORÁRIOS ESPECÍFICOS ===");
      
      horariosFuncionamento.forEach((dia, horarios) {
        String abertura = horarios['abertura'] ?? '';
        String fechamento = horarios['fechamento'] ?? '';
        
        log("Processando $dia: abertura='$abertura', fechamento='$fechamento'");
        
        // ✅ VALIDAÇÃO RIGOROSA: Verificar formato HH:MM
        if (_validarFormatoHorario(abertura) && _validarFormatoHorario(fechamento)) {
          horariosFormatoAPI[dia] = [abertura, fechamento];
          log("✅ Horário válido para $dia: [$abertura, $fechamento]");
        } else {
          log("❌ Horário inválido para $dia: abertura='$abertura', fechamento='$fechamento'");
        }
      });
      
      if (horariosFormatoAPI.isNotEmpty) {
        formFields["horarios_funcionamento"] = jsonEncode(horariosFormatoAPI);
        log("Horários específicos enviados: ${jsonEncode(horariosFormatoAPI)}");
        
        // Usar o primeiro horário válido como horário geral
        var primeiroHorario = horariosFormatoAPI.values.first;
        formFields["horario_abertura"] = primeiroHorario[0];
        formFields["horario_fechamento"] = primeiroHorario[1];
        log("Horários gerais definidos a partir do primeiro horário: ${primeiroHorario[0]} - ${primeiroHorario[1]}");
      } else {
        log("⚠️ Nenhum horário específico válido, usando horários gerais ou originais");
        _definirHorariosGerais(formFields, horarioAbertura, horarioFechamento, banca);
      }
    } else {
      log("=== USANDO HORÁRIOS GERAIS ===");
      _definirHorariosGerais(formFields, horarioAbertura, horarioFechamento, banca);
    }
    
    if (precoMin.isNotEmpty) formFields["preco_minimo"] = precoMinimo;
    
    formFields["formas_pagamento"] = formasPagamento;
    
    // MUDANÇA: usar fazEntrega
    formFields["entrega"] = fazEntrega == true ? "true" : "false";
    
    if (pix.isNotEmpty) formFields["pix"] = pix;
    
    if (imgPath != null) {
      try {
        formFields["imagem"] = await MultipartFile.fromFile(
          imgPath,
          filename: imgPath.split(Platform.pathSeparator).last,
        );
      } catch (e) {
        log("Erro ao carregar imagem: $e");
      }
    }

    // ADAPTADO: usar getter do seu modelo
    if (feiraId.isNotEmpty) {
      formFields["feira_id"] = int.tryParse(feiraId) ?? banca.getFeiraId;
    }
    
    body = FormData.fromMap(formFields);
    
    Map<String, dynamic> encodableFields = Map.from(formFields);
      encodableFields.removeWhere((key, value) => value is MultipartFile);
      log("Campos para edição: ${jsonEncode(encodableFields)}");
      log("URL: $kBaseURL/bancas/${banca.getId}"); // ADAPTADO: usar getter

      Response response = await _dio.post('$kBaseURL/bancas/${banca.getId}',
        options: Options(
          headers: {
            "Authorization": "Bearer $userToken",
            "Content-Type": "multipart/form-data",
            "X-HTTP-Method-Override": "PATCH"
          },
        ),
        data: body);
          
      log("Status da resposta: ${response.statusCode}");
      log("Resposta: ${response.data}");
      
      if (response.statusCode == 200) {
        log('Banca editada com sucesso');
        return true;
      } else {
        var errorMessage = "Erro desconhecido";
        if (response.data is Map && response.data['errors'] != null) {
          errorMessage = response.data['errors'].toString();
        }
        log('Erro: $errorMessage');
        log('Erro ao editar a banca: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e is DioError) {
        final dioError = e;
        if (dioError.response != null) {
          var errorData = dioError.response!.data;
          var errorMessage = "Erro desconhecido";
          
          if (errorData is Map && errorData['errors'] != null) {
            errorMessage = errorData['errors'].toString();
          }
          
          log('Erro da API: ${dioError.response!.statusCode}');
          log('Detalhes: $errorMessage');
        } else {
          log('Erro de comunicação: ${dioError.message}');
        }
      } else {
        log("Erro não tratado na edição: $e");
      }
      log("Erro completo na edição: $e");
      return false;
    }
  }

  // Método para validar formato de horário
  bool _validarFormatoHorario(String horario) {
    if (horario.isEmpty) return false;
    
    // Regex para formato HH:MM (exemplo: 08:00, 18:30)
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    bool valido = regex.hasMatch(horario);
    
    if (!valido) {
      log("❌ Formato inválido para horário: '$horario'");
    }
    
    return valido;
  }

  // Método para definir horários gerais com fallback
  void _definirHorariosGerais(Map<String, dynamic> formFields, String horarioAbertura, String horarioFechamento, BancaModel banca) {
    String aberturaFinal = '';
    String fechamentoFinal = '';
    
    // Tentar usar horários dos parâmetros primeiro
    if (_validarFormatoHorario(horarioAbertura) && _validarFormatoHorario(horarioFechamento)) {
      aberturaFinal = horarioAbertura;
      fechamentoFinal = horarioFechamento;
      log("Usando horários dos parâmetros: $aberturaFinal - $fechamentoFinal");
    } 
    // Fallback para horários originais da banca
    else if (_validarFormatoHorario(banca.horarioAbertura ?? '') && _validarFormatoHorario(banca.horarioFechamento ?? '')) {
      aberturaFinal = banca.horarioAbertura!;
      fechamentoFinal = banca.horarioFechamento!;
      log("Usando horários originais da banca: $aberturaFinal - $fechamentoFinal");
    }
    // Último recurso: horários padrão
    else {
      aberturaFinal = '08:00';
      fechamentoFinal = '18:00';
      log("⚠️ Usando horários padrão: $aberturaFinal - $fechamentoFinal");
    }
    
    formFields["horario_abertura"] = aberturaFinal;
    formFields["horario_fechamento"] = fechamentoFinal;
    
    log("Horários gerais definidos: abertura='$aberturaFinal', fechamento='$fechamentoFinal'");
  }

  // Adicione esta função ao MyStoreRepository
  Map<String, Map<String, String>> normalizarDiasSemana(Map<String, Map<String, String>> horarios) {
    Map<String, Map<String, String>> result = {};
    
    // Mapeamento de nomes de dias
    Map<String, String> diasCorretos = {
      'segunda': 'segunda-feira',
      'terca': 'terca-feira',
      'quarta': 'quarta-feira',
      'quinta': 'quinta-feira',
      'sexta': 'sexta-feira',
      'sabado': 'sábado',
      'domingo': 'domingo'
    };
    
    // Converter os dias para o formato correto
    horarios.forEach((dia, valores) {
      String diaCorreto = diasCorretos[dia] ?? dia;
      result[diaCorreto] = valores;
    });
    
    return result;
  }

  Future<bool> adicionarBanca(
  String nome,
  String horarioAbertura,
  String horarioFechamento,
  String precoMin,
  String feiraId,
  String? imgPath,
  List<bool> isSelected,
  bool? entrega,
  String? pix,
  Map<String, Map<String, String>>? horariosFuncionamento) async {
  formasPagamento = '';
  checkItems = [];
  
  if (isSelected.every((element) => element == false)) {
    log("Erro: Nenhuma forma de pagamento selecionada");
    return false;
  }
  
  // Tratamento do preço
  String preMinimo = "";
  if (precoMin.isNotEmpty) {
    const find = "R\$";
    const replace = "";
    var pMinimo = precoMin.replaceAll(find, replace);
    preMinimo = pMinimo.replaceAll(",", ".");
  }

  // Verificar formas de pagamento selecionadas
  for (int i = 0; i < isSelected.length; i++) {
    if (isSelected[i] == true) {
      checkItems.add((i + 1).toString());
    }
  }
  
  for (int i = 0; i < checkItems.length; i++) {
    formasPagamento += '${checkItems[i]},';
  }
  
  // Remove a última vírgula da string
  if (formasPagamento.isNotEmpty) {
    formasPagamento = formasPagamento.substring(0, formasPagamento.length - 1);
  }
  
  String? userToken = await userStorage.getUserToken();
  if (userToken == null || userToken.isEmpty) {
    log("Erro: Token de usuário não encontrado");
    return false;
  }
  
  String? userId = await userStorage.getUserId();
  if (userId == null || userId.isEmpty) {
    log("Erro: ID de usuário não encontrado");
    return false;
  }
  
  try {
    // Verificar e converter o ID da feira
    int? feiraIdNum;
    
    if (!RegExp(r'^[0-9]+$').hasMatch(feiraId)) {
      if (feiras.isEmpty) {
        await getFeiras();
        if (feiras.isEmpty) {
          log("Erro: Não foi possível carregar a lista de feiras");
          return false;
        }
      }
      
      bool feiraEncontrada = false;
      for (var f in feiras) {
        if (f.nome == feiraId) {
          feiraIdNum = f.id;
          feiraEncontrada = true;
          log("Feira encontrada: ID ${f.id} para nome '${f.nome}'");
          break;
        }
      }
      
      if (!feiraEncontrada) {
        log("Aviso: Feira não encontrada pelo nome '$feiraId'. Usando a primeira feira disponível.");
        if (feiras.isNotEmpty) {
          feiraIdNum = feiras.first.id;
        } else {
          log("Erro: Nenhuma feira disponível");
          return false;
        }
      }
    } else {
      feiraIdNum = int.tryParse(feiraId);
    }
    
    if (feiraIdNum == null) {
      log("Erro: Não foi possível obter um ID válido para a feira");
      return false;
    }
    
    // ✅ CORREÇÃO PRINCIPAL: Converter formato de horários para Array
    Map<String, List<String>> horariosFormatoAPI = {};
    
    if (horariosFuncionamento != null) {
      Map<String, Map<String, String>> horariosNormalizados = normalizarDiasSemana(horariosFuncionamento);
      
      horariosNormalizados.forEach((dia, horarios) {
        log("Processando dia $dia: ${horarios['abertura']} - ${horarios['fechamento']}");
        if (horarios['abertura']!.isNotEmpty && horarios['fechamento']!.isNotEmpty) {
          // ✅ FORMATO CORRETO: Array com [abertura, fechamento]
          horariosFormatoAPI[dia] = [horarios['abertura']!, horarios['fechamento']!];
          log("Dia $dia convertido para formato API: [${horarios['abertura']}, ${horarios['fechamento']}]");
        }
      });
    }
    
    // Se nenhum horário específico foi configurado, usar horário geral para todos os dias
    if (horariosFormatoAPI.isEmpty && horarioAbertura.isNotEmpty && horarioFechamento.isNotEmpty) {
      log("Usando horário geral para todos os dias: $horarioAbertura - $horarioFechamento");
      horariosFormatoAPI = {
        'segunda-feira': [horarioAbertura, horarioFechamento],
        'terca-feira': [horarioAbertura, horarioFechamento],
        'quarta-feira': [horarioAbertura, horarioFechamento],
        'quinta-feira': [horarioAbertura, horarioFechamento],
        'sexta-feira': [horarioAbertura, horarioFechamento],
        'sábado': [horarioAbertura, horarioFechamento],
        'domingo': [horarioAbertura, horarioFechamento],
      };
    }
    
    // Log dos horários sendo enviados no formato correto
    log("Horários no formato API: ${jsonEncode(horariosFormatoAPI)}");
    
    // Campos obrigatórios para adicionar banca
    Map<String, dynamic> formFields = {
      "nome": nome,
      "descricao": 'loja',
      "horario_abertura": horarioAbertura,
      "horario_fechamento": horarioFechamento,
      "formas_pagamento": formasPagamento,
      "agricultor_id": userId.toString(),
      "feira_id": feiraIdNum.toString(),
    };
    
    // ✅ ADICIONAR HORÁRIOS NO FORMATO CORRETO
    if (horariosFormatoAPI.isNotEmpty) {
      formFields["horarios_funcionamento"] = jsonEncode(horariosFormatoAPI);
      log("Horários adicionados ao formFields: ${jsonEncode(horariosFormatoAPI)}");
    } else {
      log("⚠️ Nenhum horário configurado - será enviado null");
    }
    
    // Adiciona imagem se foi fornecida
    if (imgPath != null) {
      try {
        String fileName = imgPath.split(Platform.pathSeparator).last;
        formFields["imagem"] = await MultipartFile.fromFile(
          imgPath,
          filename: fileName,
        );
        log("Imagem adicionada: $fileName");
      } catch (e) {
        log("Erro ao carregar imagem: $e");
      }
    }
    
    // Adiciona entrega como campo obrigatório
    formFields["entrega"] = entrega == true ? "true" : "false";
    
    // Adiciona preço mínimo se entrega estiver habilitada
    if (entrega == true && preMinimo.isNotEmpty) {
      formFields["preco_minimo"] = preMinimo;
    }
    
    // Adiciona PIX se fornecido
    if (pix != null && pix.isNotEmpty) {
      formFields["pix"] = pix;
    }

    body = FormData.fromMap(formFields);
    
    // Log detalhado dos campos sendo enviados
    Map<String, dynamic> logFields = Map.from(formFields);
    logFields.removeWhere((key, value) => value is MultipartFile);
    log("=== CAMPOS SENDO ENVIADOS PARA API ===");
    log(jsonEncode(logFields));

    Response response = await _dio.post(
      '$kBaseURL/bancas',
      options: Options(headers: {
        "Content-Type": "multipart/form-data",
        "Authorization": "Bearer $userToken"
      }),
      data: body,
    );

    log("Resposta da API: ${response.statusCode}");
    log("Dados da resposta: ${response.data}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      log('✅ Cadastro da banca bem sucedido');
      return true;
    } else {
      var errorMessage = "Erro desconhecido";
      if (response.data is Map && response.data['errors'] != null) {
        errorMessage = response.data['errors'].toString();
      }
      log('❌ Erro no cadastro da banca: ${response.statusCode}');
      log('Detalhes: $errorMessage');
      return false;
    }
  } catch (e) {
    if (e is DioError) {
      final dioError = e;
      if (dioError.response != null) {
        var errorData = dioError.response!.data;
        var errorMessage = "Erro desconhecido";
        
        if (errorData is Map && errorData['errors'] != null) {
          errorMessage = errorData['errors'].toString();
        }
        
        log('❌ Erro da API: ${dioError.response!.statusCode}');
        log('Detalhes: $errorMessage');
      } else {
        log('❌ Erro de comunicação: ${dioError.message}');
      }
    }
    log("❌ Erro ao adicionar banca: $e");
    return false;
  }
}
}