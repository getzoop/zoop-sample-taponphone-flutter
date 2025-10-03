import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zoop_sdk_taponphone_flutter/zoop_sdk_taponphone_library.dart';

void main() async {
  await dotenv.load(fileName: ".env"); // Carrega o arquivo .env

  if(Platform.isAndroid) {
    ZoopSdkTaponphone().kernelInitialize();
  }
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _zoopSdkTaponphonePlugin = ZoopSdkTaponphone();
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

    if (Platform.isIOS) {
      paymentTypes.remove(PaymentType.pix);
    }

    getApplicationEvent();
  }

  void getApplicationEvent() {
    _zoopSdkTaponphonePlugin.getApplicationEvent().listen(
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

      ZoopSdkInitializationStatus? result = await _zoopSdkTaponphonePlugin.initialize();

      setState(() {
        _message = result?.name  ??
            'SDK initialization failed';
      });
    } on ZoopSdkException catch (e) {
      debugPrint("ZoopSdkException: ${e.code} - ${e.message}");
      setState(() {
        _message = "${e.code} - ${e.message}";
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

      final ZoopSdkResult? result = await _zoopSdkTaponphonePlugin.pay(payRequest);
      print("LETICIA Payment $result");
      print("LETICIA Payment successful, transactionId: ${result!.transactionId}");

      setState(() {
        _message = "Payment successful, transactionId: ${result!.transactionId}";
      });
    } on ZoopSdkException catch (e) {
      print("LETICIA ZoopSdkException: ${e.code} - ${e.message}");
      setState(() {
        _message = "${e.code} - ${e.message}";
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
      Attestation attestation = Attestation(clientId: clientId, clientSecret: clientSecret);
      Credentials credentials = Credentials(
        clientId: clientId,
        clientSecret: clientSecret,
        marketplace: marketplace,
        seller: seller,
        accessKey: accessKey,
        attestation: attestation,
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

      var gradientStops = List<GradientStop>.of([
        GradientStop(
          color: "7FFF0000",
          location: 0.0,
          opacity: 1.0,
        ),
        GradientStop(
          color: "7FFFFFFF",
          location: 1.0,
          opacity: 1.0,
        )
      ]);

      TapOnPhoneTheme theme = TapOnPhoneTheme(
        logo: "assets/images/zoop.png",
        backgroundColor: "#00FFDAB9",
        footerBackgroundColor: "#FFFF5722",
        amountTextColor: "#FFFFFFFF",
        paymentTypeTextColor: "#FFFFFFFF",
        marginTopDPStatusMessages: 40.0,
        marginTopDPPaymentType: 8.0,
        statusTextColor: "#FF0A0A0A",
        brandBackgroundColor: "#FFF00000",
        cardAnimation: "assets/animations/card_animation.json",
        cardAnimationResources: {
          CardAnimationType.terminalActivationStarted.name: "assets/animations/start_activate_terminal.json",
          CardAnimationType.terminalActivationFinished.name: "assets/animations/complete_activate_terminal.json",
          CardAnimationType.paymentProcessStarted.name: "assets/animations/start_payment_process.json",
          CardAnimationType.startContactlessReading.name: "assets/animations/start_contactless_reading.json",
          CardAnimationType.authorisingPleaseWait.name: "assets/animations/authorising_please_wait.json",
          CardAnimationType.cardReadingStarted.name: "assets/animations/start_card_reading.json",
          CardAnimationType.cardReadingRetry.name: "assets/animations/start_card_reading_again.json",
          CardAnimationType.tryAnotherCard.name: "assets/animations/try_another_card.json",
          CardAnimationType.holdCardSteady.name: "assets/animations/card_animation.json"
        },
        cardAnimationArrangement: Bottom(marginBottom: 500),
        cardAnimationSize: 512,
        // headerMessagesEventStatus: {
        //   MessagesEventStatus.cardReadingStarted.name: MessageEvent(
        //     title: "Aproxime o cartão header",
        //     subtitle: "Aproxime o cartão no leitor header",
        //   ),
        // },
        pinPadType: PinpadType.shifted,
        headerTextContent: HeaderTextContent(
          title: TextConfiguration(text: "Title"),
          subtitle: TextConfiguration(text: "Subtitle"),
          updateFromEvents: true,
        ),
        messagesEventStatus: {
          MessagesEventStatus.terminalActivationStarted.name: MessageEvent(
            title: 'Ativando o terminal',
            subtitle: 'Por favor, aguarde...',
          ),
          MessagesEventStatus.paymentProcessStarted.name: MessageEvent(
            title: "Iniciando pagamento",
            subtitle: "Aguarde...",
          ),
          MessagesEventStatus.cardReadingStarted.name: MessageEvent(
            title: "Aproxime o cartão",
            subtitle: "Aproxime o cartão no leitor",
          ),
          MessagesEventStatus.cardReadingRetry.name: MessageEvent(
            title: "Reaproxime o cartão, por favor",
            subtitle: "",
          ),
          MessagesEventStatus.paymentProcessStarted.name: MessageEvent(
            title: "Processando pagamento",
            subtitle: "Aguarde um instante...",
          ),
          MessagesEventStatus.authorisingPleaseWait.name: MessageEvent(
            title: "Autorizando",
            subtitle: "Aguarde, por favor",
          ),
          MessagesEventStatus.pinInputStarted.name: MessageEvent(
            title: "Inserir a senha do cartão",
            subtitle: "",
          ),
        },
        errorScreenConfiguration: ErrorScreenConfiguration(
          backIconConfiguration: BackIconConfiguration(
            icon: null,
            isVisible: true,
          ),
          screenBackgroundColor: "#7FFFFFFF",
          errorAnimation: null,
          errorCodeTextStyle: ErrorCodeTextStyle(
            textColor: "#FF0A0A0A",
            fontSize: 24,
          ),
          errorMessageTextStyle: ErrorMessageTextStyle(
            // text: "errorMessageTextStyle",
            textColor: "#FF0A0A0A",
            fontSize: 24,
          ),
          backButtonConfiguration: BackButtonConfiguration(
            text: "Tentar novamente",
            containerColor: "#FFB90505",
            contentColor: "#FFFFFFFF",
            isVisible: true,
          ),
        ),
        topCancelIcon: "assets/images/cancel.png",
        statusBarColor: "#FFFF5722",

        //IOS
        textColor: "#7FFF0000",
        loadingColor: "#7FFF0000",
        gradientStops: gradientStops,
      );

      SdkConfig sdkConfig = SdkConfig(
        theme: theme,
        timeoutConfig: timeoutConfig,
        beepVolumeConfig: beepVolumeConfig,
        showErrorScreen: true,
      );

      ConfigParameters configParameters = ConfigParameters(
        credentials: credentials,
        sdkConfig: sdkConfig,
        environment: TapOnPhoneEnvironment(type: Environment.staging),
        logLevel: TapOnPhoneLogLevel(level: LogLevel.debug),
      );

      bool? result = await _zoopSdkTaponphonePlugin.setConfig(configParameters);

      setState(() {
        _message = result == true ? 'SetConfig successfully' : 'SetConfig failed';
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

      ZoopSdkPixResult? result = await _zoopSdkTaponphonePlugin.payByPix(
        pixRequest,
      );

      setState(() {
        _pixCode = result?.qrcode ?? "";
        _message = "";
      });
    } on ZoopSdkException catch (e) {
      debugPrint("ZoopSdkException: ${e.code} - ${e.message}");
      setState(() {
        _message = "${e.code} - ${e.message}";
      });
    }
  }

  Future<Null> _cancelPix() async {
    try {
      _zoopSdkTaponphonePlugin.cancelPix();
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

  Future<Null> payByGateway() async {
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
      ZoopSdkResult? result = await _zoopSdkTaponphonePlugin.payByGateway(payRequest);

      setState(() {
        _message = result!.transactionId;
      });
    } on ZoopSdkException catch (e) {
      debugPrint("ZoopSdkException: ${e.code} - ${e.message}");
      setState(() {
        _message = "${e.code} - ${e.message}";
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
                      onPressed: payByGateway,
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
