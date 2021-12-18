import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pk_coin/slider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;
  bool data = false;
  final myAddress = "0xc248a8C193E603c175fD0DeBE201811B297564F8";
  int myAmount = 0;
  late var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://rinkeby.infura.io/v3/d4e3e94247254732ab9499d3acec2bb2",
        httpClient
    );
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async{
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0x152cFaDd011B2C4d7e8827A1f3da7aCc03e49bb4";
    
    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String funcName, List<dynamic> args) async{
    final contract = await loadContract();
    final ethFunction = contract.function(funcName);
    final result = await ethClient.call(
        contract: contract,
        function: ethFunction,
        params: args);
    return result;
  }

  Future<void> getBalance(String targetAddress) async{
    // EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance",[]);
    setState(() {
      myData = result[0];
      data = true;
    });

  }

  Future<String> submit(String funcName, List<dynamic> args) async{
    EthPrivateKey credentials = EthPrivateKey.fromHex("25be054aa90be65a9ebb58fb8f9ead5856a6e5f93d67d95ff67c12be11ec778d");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(funcName);

    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract,
            function: ethFunction,
            parameters: args,
        ),
      chainId: null,
      fetchChainIdFromNetworkId: true,
    );
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmt = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmt]);
    print("Deposited");
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmt = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmt]);
    print("Withdrawn");
    return response;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth,context.percentHeight*30)
            .make(),
        VStack([
          (context.percentHeight*10).heightBox,
          "\$PKCOIN".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight*5).heightBox,
          VxBox(
            child: VStack([
              "Balance".text.semiBold.xl2.gray700.makeCentered(),
              10.heightBox,
              data
                  ? "\$$myData".text.bold.xl6.makeCentered().shimmer()
                  : const CircularProgressIndicator().centered(),
            ])
          )
              .p16
              .white
              .size(context.screenWidth,context.percentHeight*18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          SliderWidget(
            min : 0,
            max: 100,
            finalVal: (val) {
              setState(() {
                myAmount = (val*100).round();
              });
              // print(myAmount);
            }
          ).centered(),
          HStack([
            FlatButton.icon(
                onPressed: () => getBalance(myAddress),
                color: Colors.blue,
                shape: Vx.roundedSm,
                icon: const Icon(Icons.refresh),
                label: "Refresh".text.white.make()
            ).h(50),
            FlatButton.icon(
                onPressed: sendCoin,
                color: Colors.green,
                shape: Vx.roundedSm,
                icon: const Icon(Icons.call_made_outlined),
                label: "Deposit".text.white.make()
            ).h(50),
            FlatButton.icon(
                onPressed: withdrawCoin,
                color: Colors.red,
                shape: Vx.roundedSm,
                icon: const Icon(Icons.call_received_outlined),
                label: "Withdraw".text.white.make()
            ).h(50),
          ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16()
        ])
      ])
    );
  }
}
