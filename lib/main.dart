import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zoop_sdk_taponphone_flutter/components/zoop_qr_code_image.dart';
import 'package:zoop_sdk_taponphone_flutter/model/application_event.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/back_button_configuration.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/back_icon_configuration.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/beep_volume_config.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/card_animation_arrangement.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/card_animation_type.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/config_parameters.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/credentials.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/error_code_text_style.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/error_message_text_style.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/error_screen_configuration.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/header_text_content.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/message_event.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/messages_event_status.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/pinpad_type.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/sdk_config.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/tap_on_phone_theme.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/text_configuration.dart';
import 'package:zoop_sdk_taponphone_flutter/model/configuration/timeout_config.dart';
import 'package:zoop_sdk_taponphone_flutter/model/externall_seller.dart';
import 'package:zoop_sdk_taponphone_flutter/model/pay_request.dart';
import 'package:zoop_sdk_taponphone_flutter/model/payment_type.dart';
import 'package:zoop_sdk_taponphone_flutter/model/pix_request.dart';
import 'package:zoop_sdk_taponphone_flutter/zoop_sdk_taponphone_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env"); // Carrega o arquivo .env
  ZoopSdkTaponphoneFlutter().kernelInitialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _zoopSdkTaponphoneFlutterPlugin = ZoopSdkTaponphoneFlutter();
  String _message = "Tap on phone not Initialized";
  PaymentType? _paymentType =
      PaymentType.credit; // Tipo de pagamento selecionado
  final List<PaymentType> paymentTypes = [
    PaymentType.credit,
    PaymentType.debit,
    PaymentType.pix,
  ];
  int amount = 1; // Valor da transação em centavo
  int installments = 1; // Número total de parcelas
  bool showTimeoutConfig = false;
  int? discoveryTimeout;
  int? processingTimeout;
  int? networkTimeout;
  int? totalElapsedTimeout;
  bool showBeepConfig = false;
  int? beepVolume;

  final clientId = dotenv.env['CLIENT_ID'] ?? '';
  final clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';
  final marketplace = dotenv.env['MARKETPLACE'] ?? '';
  final seller = dotenv.env['SELLER'] ?? '';
  final accessKey = dotenv.env['API_KEY'] ?? '';
  final Map<String, dynamic> metadata = {
    "fee": "0.0455",
    "original_value": 140.0,
    "installments": 1,
    "message": "Test metadata Plugin Flutter",
  }; // Metadados adicionais (opcional)

  String _pixCode = "";

  // URL do código Pix (pode ser atualizado após o pagamento)

  @override
  void initState() {
    super.initState();
    getApplicationEvent();
  }

  Future<String?> loadImageAsTemporaryPath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  void getApplicationEvent() {
    _zoopSdkTaponphoneFlutterPlugin.getApplicationEvent().listen(
      (dynamic event) {
        debugPrint(
          "Event from native: ${ApplicationEvent.fromValue(event) ?? "Unknown event"}",
        );
      },
      onError: (dynamic error) {
        debugPrint("Error: $error");
      },
    );
  }

  Future<Null> _initialize() async {
    try {
      setState(() {
        _message = "Await Initialization...";
      });

      String result =
          await _zoopSdkTaponphoneFlutterPlugin.initialize() ??
          'SDK initialization failed';

      setState(() {
        _message = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Erro: ${e.message}";
      });
    }
  }

  Future<Null> _pay() async {
    try {
      setState(() {
        _message = "Await payment...";
      });

      final payRequest = PayRequest(
          amount: amount,
          paymentType: _paymentType!.value,
          installments: installments,
          metadata: metadata
      );
      String result =
          await _zoopSdkTaponphoneFlutterPlugin.pay(payRequest) ?? 'Payment failed';


      setState(() {
        _message = result;
        debugPrint(
          "applicationEvent[Flutter] called: ${ApplicationEvent.fromValue(result)}",
        );
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = e.message ?? "Payment error";
      });
    }
  }

  Future<Null> _setConfig() async {
    try {
      setState(() {
        _message = "Await SetConfig...";
      });
      final beepVolume = this.beepVolume;
      BeepVolumeConfig? beepVolumeConfig;
      Credentials credentials = Credentials(
        clientId,
        clientSecret,
        marketplace,
        seller,
        accessKey,
        null,
      );
      TimeoutConfig timeoutConfig = TimeoutConfig(
        discoveryTimeout: discoveryTimeout,
        processingTimeout: processingTimeout,
        networkTimeout: networkTimeout,
        totalElapsedTimeout: totalElapsedTimeout,
      );

      if (beepVolume != null) {
        beepVolumeConfig = BeepVolumeConfig(beepVolume: beepVolume.toDouble());
      }

      TapOnPhoneTheme theme = TapOnPhoneTheme(
        logo: "assets/images/android_24dp.png",
        backgroundColor: int.tryParse("0x00FFDAB9"),
        footerBackgroundColor: int.tryParse("0x7FFFCC80"),
        amountTextColor: int.tryParse("0x7FFB8C00"),
        paymentTypeTextColor: int.tryParse("0x7FFB8C00"),
        marginTopDPStatusMessages: 40.0,
        marginTopDPAmount: 0,
        marginTopDPPaymentType: 8.0,
        statusTextColor: int.tryParse("0x7FCC5500"),
        brandBackgroundColor: "F00000",
        cardAnimation: "assets/animations/card_animation.json",
        cardAnimationResources: {
          CardAnimationType.holdCard.name: "assets/animations/card_animation.json",
        },
        cardAnimationArrangement: Top(marginTop: 24),
        cardAnimationSize: 512,
        headerMessagesEventStatus: {
          MessagesEventStatus.startCardReading.name: MessageEvent(
            title: "Aproxime o cartão header",
            subtitle: "Aproxime o cartão no leitor header",
          ),
        },
        pinPadType: PinpadType.shifted,
        headerTextContent: HeaderTextContent(
          title: TextConfiguration(text: "Title"),
          subtitle: TextConfiguration(text: "Subtitle"),
          updateFromEvents: true,
        ),
        messagesEventStatus: {
          MessagesEventStatus.startActiveTerminal.name: MessageEvent(
            title: 'Ativando o terminal',
            subtitle: 'Por favor, aguarde...',
          ),
          MessagesEventStatus.startPaymentProcess.name: MessageEvent(
            title: "Iniciando pagamento",
            subtitle: "Aguarde...",
          ),
          MessagesEventStatus.startCardReading.name: MessageEvent(
            title: "Aproxime o cartão",
            subtitle: "Aproxime o cartão no leitor",
          ),
          MessagesEventStatus.startCardReadingAgain.name: MessageEvent(
            title: "Reaproxime o cartão, por favor",
            subtitle: "",
          ),
          MessagesEventStatus.completePaymentProcess.name: MessageEvent(
            title: "Processando pagamento",
            subtitle: "Aguarde um instante...",
          ),
          MessagesEventStatus.authorisingPleaseWait.name: MessageEvent(
            title: "Autorizando",
            subtitle: "Aguarde, por favor",
          ),
          MessagesEventStatus.startPinInput.name: MessageEvent(
            title: "Inserir a senha do cartão",
            subtitle: "",
          ),
        },
        errorScreenConfiguration: ErrorScreenConfiguration(
          backIconConfiguration: BackIconConfiguration(
            icon: null,
            isVisible: true,
          ),
          screenBackgroundColor: int.tryParse("0x7FFFFFFF"),
          errorAnimation: null,
          errorCodeTextStyle: ErrorCodeTextStyle(
            textColor: int.tryParse("0x7FFFFFFF"),
            fontSize: 16,
          ),
          errorMessageTextStyle: ErrorMessageTextStyle(
            text: "errorMessageTextStyle",
            textColor: int.tryParse("0x7FFFFFFF"),
            fontSize: 12,
          ),
          backButtonConfiguration: BackButtonConfiguration(
            text: "Tentar novamente",
            containerColor: int.tryParse("0x7FFFFFFF")!,
            contentColor: 0xFF0000,
            isVisible: true,
          ),
        ),
        topCancelIcon: "assets/images/close_24dp.png",
        statusBarColor: int.tryParse("0x7FFB8C00"),
      );

      SdkConfig sdkConfig = SdkConfig(
        theme: theme,
        timeoutConfig: timeoutConfig,
        beepVolumeConfig: beepVolumeConfig,
        showErrorScreen: true,
      );

      ConfigParameters configParameters = ConfigParameters(
        credentials: credentials,
        sdkConfig: sdkConfig
      );

      String result =
          await _zoopSdkTaponphoneFlutterPlugin.setConfig(configParameters) ??
          'SetupConfig failed';

      setState(() {
        _message = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Erro: ${e.message}";
      });
    }
  }

  Future<Null> _showTimeoutConfig() async {
    try {
      setState(() {
        showTimeoutConfig = !showTimeoutConfig;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Erro: ${e.message}";
      });
    }
  }

  Future<Null> _showBeepConfig() async {
    try {
      setState(() {
        showBeepConfig = !showBeepConfig;
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = "Erro: ${e.message}";
      });
    }
  }

  Future<Null> _payByPix() async {
    try {
      setState(() {
        _message = "Await payment by Pix...";
      });

      PixRequest pixRequest = PixRequest(
        amount: amount,
        referenceId: "1234567890",
        metadata: jsonEncode(metadata),
        pixNfc: true,
      );

      String result =
          await _zoopSdkTaponphoneFlutterPlugin.payByPix(pixRequest) ??
          'Payment by Pix failed';

      setState(() {
        _pixCode = result;
        _message = "";
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = e.message ?? "Payment error";
      });
    }
  }

  Future<Null> _cancelPix() async {
    try {
      _zoopSdkTaponphoneFlutterPlugin.cancelPix();
      setState(() {
        _message = "Operação cancelada";
        _pixCode = "";
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = e.message ?? "Cancel Pix error";
      });
    }
  }

  Future<Null> _payByGateway() async {
    try {
      setState(() {
        _message = "Await payment...";
      });

      final payRequest = PayRequest(
          amount: amount,
          paymentType: _paymentType!.value,
          installments: installments,
          metadata: metadata,
          externalSeller: ExternalSeller(
              addressLine: "addressLine",
              softDescriptor: "softDescriptor",
              cpfCnpj: "cpfCnpj",
              state: "state",
              city: "city",
              country: "country",
              phoneNumber: "phoneNumber",
              zipCode: "zipCode",
              subMerchantId: "subMerchantId",
              merchantCategoryCode: "merchantCategoryCode",
              name: "name"
          )
      );
      String result =
          await _zoopSdkTaponphoneFlutterPlugin.payByGateway(payRequest) ?? 'Payment failed';

      setState(() {
        _message = result;
        debugPrint(
          "applicationEvent[Flutter] called: ${ApplicationEvent.fromValue(result)}",
        );
      });
    } on PlatformException catch (e) {
      setState(() {
        _message = e.message ?? "Payment error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(), // rolagem suave
        padding: EdgeInsets.all(16.0), // padding externo
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  TextField(
                    onChanged: (value) => amount = int.tryParse(value) ?? 0,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<PaymentType>(
                    hint: Text('Select Payment Type'),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    initialValue: _paymentType,
                    items: paymentTypes.map((PaymentType value) {
                      return DropdownMenuItem<PaymentType>(
                        value: value,
                        child: Text(value.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _paymentType = value;
                    }),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    onChanged: (value) =>
                        installments = int.tryParse(value) ?? 1,
                    decoration: InputDecoration(
                      labelText: 'Installments',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showTimeoutConfig,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor:
                            Colors.blue, // Ajuste de tamanho do botão
                      ),
                      child: Text(
                        'Configurar Timeout',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (showTimeoutConfig)
                    TextField(
                      onChanged: (value) =>
                          discoveryTimeout = int.tryParse(value) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Discovery',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (showTimeoutConfig)
                    TextField(
                      onChanged: (value) =>
                          processingTimeout = int.tryParse(value) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Processing',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (showTimeoutConfig)
                    TextField(
                      onChanged: (value) =>
                          networkTimeout = int.tryParse(value) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Network',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (showTimeoutConfig)
                    TextField(
                      onChanged: (value) =>
                          totalElapsedTimeout = int.tryParse(value) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Total elapsed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showBeepConfig,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor:
                            Colors.blue, // Ajuste de tamanho do botão
                      ),
                      child: Text(
                        'Configurar Beep',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  if (showBeepConfig)
                    TextField(
                      onChanged: (value) =>
                          beepVolume = int.tryParse(value) ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Beep',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _setConfig,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor:
                            Colors.blue, // Ajuste de tamanho do botão
                      ),
                      child: Text(
                        'Aplicar configuração',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _initialize,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor:
                            Colors.blue, // Ajuste de tamanho do botão
                      ),
                      child: Text(
                        'Initialize',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _payByGateway,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Bordas arredondadas
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor:
                            Colors.blue, // Ajuste de tamanho do botão
                      ),
                      child: Text(
                        'Pay by Gateway',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_paymentType == PaymentType.pix) {
                          _payByPix();
                        } else {
                          _pay();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        foregroundColor: Colors.blue,
                      ),
                      child: Text(
                        'Pay',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ), // Cor do texto
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ZoopQRCodeImage(
                    data: _pixCode,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 40),
                  if (_pixCode.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _cancelPix,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          foregroundColor: Colors.blue,
                        ),
                        child: Text(
                          'Cancel Pix',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}
