import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' show File, Platform, Process, ProcessResult;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:komodo_dex/model/active_coin.dart';
import 'package:komodo_dex/model/balance.dart';
import 'package:komodo_dex/model/buy_response.dart';
import 'package:komodo_dex/model/coin.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/model/error_string.dart';
import 'package:komodo_dex/model/get_active_coin.dart';
import 'package:komodo_dex/model/get_balance.dart';
import 'package:komodo_dex/model/get_buy.dart';
import 'package:komodo_dex/model/get_orderbook.dart';
import 'package:komodo_dex/model/get_send_raw_transaction.dart';
import 'package:komodo_dex/model/get_withdraw.dart';
import 'package:komodo_dex/model/orderbook.dart';
import 'package:komodo_dex/model/send_raw_transaction_response.dart';
import 'package:komodo_dex/model/withdraw_response.dart';
import 'package:shared_preferences/shared_preferences.dart';


final mm2 = MarketMakerService();

class MarketMakerService {
  List<Balance> balances = new List<Balance>();
  Process mm2Process = null;
  List<Coin> coins = List<Coin>();
  bool activeCoinBool = true;
  bool ismm2Running = true;
  String url = 'http://10.0.2.2:7783';
  String userpass = "";


  MarketMakerService() {
    if (Platform.isAndroid) {
      url = 'http://localhost:7783';
    } else if (Platform.isIOS) {
      url = 'http://localhost:7783';
    }
  }

  Future<bool> runBin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String passphrase = prefs.getString('passphrase');

    await Process.run('killall', ['mm2']);

    ProcessResult checkmm2 = await Process.run(
        'ls', ['/data/data/com.komodoplatform.komododex/files/mm2']);

    if (checkmm2.stdout.toString().trim() !=
        "/data/data/com.komodoplatform.komododex/files/mm2") {
      ByteData resultmm2 = await rootBundle.load("assets/mm2");
      await writeData(resultmm2.buffer.asUint8List());
      await Process.run('chmod',
          ['777', '/data/data/com.komodoplatform.komododex/files/mm2']);
    }

    var bytes = utf8.encode(passphrase); // data being hashed
    userpass = sha256.convert(bytes).toString();

    String coins =
        '[{\"coin\":\"OOT\",\"asset\":\"OOT\",\"rpcport\":12467}, {\"coin\":\"ETH\",\"name\":\"ethereum\",\"etomic\":\"0x0000000000000000000000000000000000000000\",\"rpcport\":80}, {\"coin\":\"EOS\",\"name\":\"EOS\",\"etomic\":\"0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0\",\"rpcport\":80},{\"coin\":\"JST\", \"name\":\"JST\",\"etomic\":\"0xc0eb7AeD740E1796992A08962c15661bDEB58003\",\"rpcport\":80},{\"coin\":\"NODEC\",\"name\":\"NODEC\",\"etomic\":\"0x05beb0a9ead354283041a6d35f3b833450fb5680\",\"rpcport\":80,\"decimals\":18},{\"coin\":\"ZOI\",\"name\":\"zoin\",\"rpcport\":8255,\"pubtype\":80,\"p2shtype\":7,\"wiftype\":208,\"txfee\":1000}, {\"coin\": \"PIZZA\",\"asset\": \"PIZZA\",\"rpcport\": 11116},{\"coin\": \"BEER\",\"asset\": \"BEER\",\"rpcport\": 8923}, {\"coin\":\"GRS\",\"name\":\"groestlcoin\",\"rpcport\":1441,\"pubtype\":36,\"p2shtype\":5,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"BTCH\",\"asset\":\"BTCH\",\"rpcport\":8800},{\"coin\":\"ETOMIC\",\"asset\":\"ETOMIC\",\"rpcport\":10271},{\"coin\":\"AXO\",\"asset\":\"AXO\",\"rpcport\":12927},{\"coin\":\"CRC\",\"name\":\"crowdcoin\",\"confpath\":\"\${HOME#}/.crowdcoincore/crowdcoin.conf\",\"rpcport\":11998,\"pubtype\":28,\"p2shtype\":88,\"wiftype\":0,\"txfee\":10000}, {\"coin\":\"VOT\",\"name\":\"votecoin\",\"rpcport\":8232,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"INN\",\"name\":\"innova\",\"confpath\":\"\${HOME#}/.innovacore/innova.conf\",\"rpcport\":8818,\"pubtype\":102,\"p2shtype\":20,\"wiftype\":195,\"txfee\":10000}, {\"coin\":\"MOON\",\"name\":\"mooncoin\",\"rpcport\":44663,\"pubtype\":3,\"p2shtype\":22,\"wiftype\":131,\"txfee\":100000}, {\"coin\":\"CRW\",\"name\":\"crown\",\"rpcport\":9341,\"pubtype\":0,\"p2shtype\":28,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"EFL\",\"name\":\"egulden\",\"confpath\":\"\${HOME#}/.egulden/coin.conf\",\"rpcport\":21015,\"pubtype\":48,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"GBX\",\"name\":\"gobyte\",\"confpath\":\"\${HOME#}/.gobytecore/gobyte.conf\",\"rpcport\":12454,\"pubtype\":38,\"p2shtype\":10,\"wiftype\":198,\"txfee\":10000}, {\"coin\":\"BCO\",\"name\":\"bridgecoin\",\"rpcport\":6332,\"pubtype\":27,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"BLK\",\"name\":\"blackcoin\",\"confpath\":\"\${HOME#}/.lore/blackcoin.conf\",\"isPoS\":1,\"rpcport\":15715,\"pubtype\":25,\"p2shtype\":85,\"wiftype\":153,\"txfee\":100000}, {\"coin\":\"BTG\",\"name\":\"bitcoingold\",\"rpcport\":8332,\"pubtype\":38,\"p2shtype\":23,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"BCH\",\"name\":\"bch\",\"rpcport\":33333,\"pubtype\":0,\"p2shtype\":5,\"wiftype\":128,\"txfee\":1000}, {\"coin\":\"ABY\",\"name\":\"applebyte\",\"rpcport\":8607,\"pubtype\":23,\"p2shtype\":5,\"wiftype\":151,\"txfee\":100000}, {\"coin\":\"STAK\",\"name\":\"straks\",\"rpcport\":7574,\"pubtype\":63,\"p2shtype\":5,\"wiftype\":204,\"txfee\":10000}, {\"coin\":\"XZC\",\"name\":\"zcoin\",\"rpcport\":8888,\"pubtype\":82,\"p2shtype\":7,\"wiftype\":210,\"txfee\":10000}, {\"coin\":\"QTUM\",\"name\":\"qtum\",\"rpcport\":3889,\"pubtype\":58,\"p2shtype\":50,\"wiftype\":128,\"txfee\":400000}, {\"coin\":\"PURA\",\"name\":\"pura\",\"rpcport\":55555,\"pubtype\":55,\"p2shtype\":16,\"wiftype\":150,\"txfee\":10000}, {\"coin\":\"DSR\",\"name\":\"desire\",\"confpath\":\"\${HOME#}/.desirecore/desire.conf\",\"rpcport\":9918,\"pubtype\":30,\"p2shtype\":16,\"wiftype\":204,\"txfee\":10000}, {\"coin\":\"MNZ\",\"asset\":\"MNZ\",\"rpcport\":14337},{\"coin\":\"BTCZ\",\"name\":\"bitcoinz\",\"rpcport\":1979,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"MAGA\",\"name\":\"magacoin\",\"rpcport\":5332,\"pubtype\":23,\"p2shtype\":50,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"BSD\",\"name\":\"bitsend\",\"rpcport\":8800,\"pubtype\":102,\"p2shtype\":5,\"wiftype\":204,\"txfee\":10000}, {\"coin\":\"IOP\",\"name\":\"IoP\",\"rpcport\":8337,\"pubtype\":117,\"p2shtype\":174,\"wiftype\":49,\"txfee\":10000}, {\"coin\":\"BLOCK\",\"name\":\"blocknetdx\",\"rpcport\":41414,\"pubtype\":26,\"p2shtype\":28,\"wiftype\":154,\"txfee\":10000}, {\"coin\":\"CHIPS\", \"name\": \"chips\", \"rpcport\":57776,\"pubtype\":60, \"p2shtype\":85, \"wiftype\":188, \"txfee\":10000}, {\"coin\":\"888\",\"name\":\"octocoin\",\"rpcport\":22888,\"pubtype\":18,\"p2shtype\":5,\"wiftype\":176,\"txfee\":2000000}, {\"coin\":\"ARG\",\"name\":\"argentum\",\"rpcport\":13581,\"pubtype\":23,\"p2shtype\":5,\"wiftype\":151,\"txfee\":50000}, {\"coin\":\"GLT\",\"name\":\"globaltoken\",\"rpcport\":9320,\"pubtype\":38,\"p2shtype\":5,\"wiftype\":166,\"txfee\":10000}, {\"coin\":\"ZER\",\"name\":\"zero\",\"rpcport\":23801,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":1000}, {\"coin\":\"HODLC\",\"name\":\"hodlcoin\",\"rpcport\":11989,\"pubtype\":40,\"p2shtype\":5,\"wiftype\":168,\"txfee\":5000}, {\"coin\":\"UIS\",\"name\":\"unitus\",\"rpcport\":50604,\"pubtype\":68,\"p2shtype\":10,\"wiftype\":132,\"txfee\":2000000}, {\"coin\":\"HUC\",\"name\":\"huntercoin\",\"rpcport\":8399,\"pubtype\":40,\"p2shtype\":13,\"wiftype\":168,\"txfee\":100000}, {\"coin\":\"BDL\",\"name\":\"bitdeal\",\"rpcport\":9332,\"pubtype\":38,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"ARC\",\"name\":\"arcticcoin\",\"confpath\":\"\${HOME#}/.arcticcore/arcticcoin.conf\",\"rpcport\":7208,\"pubtype\":23,\"p2shtype\":8,\"wiftype\":176,\"txfee\":10000}, {\"coin\":\"ZCL\",\"name\":\"zclassic\",\"rpcport\":8023,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":1000}, {\"coin\":\"VIA\",\"name\":\"viacoin\",\"rpcport\":5222,\"pubtype\":71,\"p2shtype\":33,\"wiftype\":199,\"txfee\":100000}, {\"coin\":\"ERC\",\"name\":\"europecoin\",\"rpcport\":11989,\"pubtype\":33,\"p2shtype\":5,\"wiftype\":168,\"txfee\":10000},{\"coin\":\"FAIR\",\"name\":\"faircoin\",\"confpath\":\"\${HOME#}/.faircoin2/faircoin.conf\",\"rpcport\":40405,\"pubtype\":95,\"p2shtype\":36,\"wiftype\":223,\"txfee\":1000000}, {\"coin\":\"FLO\",\"name\":\"florincoin\",\"rpcport\":7313,\"pubtype\":35,\"p2shtype\":8,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"SXC\",\"name\":\"sexcoin\",\"rpcport\":9561,\"pubtype\":62,\"p2shtype\":5,\"wiftype\":190,\"txfee\":100000}, {\"coin\":\"CREA\",\"name\":\"creativecoin\",\"rpcport\":17711,\"pubtype\":28,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000}, {\"coin\":\"TRC\",\"name\":\"terracoin\",\"confpath\":\"\${HOME#}/.terracoincore/terracoin.conf\",\"rpcport\":13332,\"pubtype\":0,\"p2shtype\":5,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"BTA\",\"name\":\"bata\",\"rpcport\":5493,\"pubtype\":25,\"p2shtype\":5,\"wiftype\":188,\"txfee\":100000}, {\"coin\":\"SMC\",\"name\":\"smartcoin\",\"rpcport\":58583,\"pubtype\":63,\"p2shtype\":5,\"wiftype\":191,\"txfee\":1000000}, {\"coin\":\"NMC\",\"name\":\"namecoin\",\"rpcport\":8336,\"pubtype\":52,\"p2shtype\":13,\"wiftype\":180,\"txfee\":100000}, {\"coin\":\"NAV\",\"name\":\"navcoin\",\"isPoS\":1,\"confpath\":\"\${HOME#}/.navcoin4/navcoin.conf\",\"rpcport\":44444,\"pubtype\":53,\"p2shtype\":85,\"wiftype\":150,\"txfee\":10000}, {\"coin\":\"EMC2\",\"name\":\"einsteinium\",\"rpcport\":41879,\"pubtype\":33,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000},{\"coin\":\"SYS\",\"name\":\"syscoin\",\"rpcport\":8370,\"pubtype\":0,\"p2shtype\":5,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"I0C\",\"name\":\"i0coin\",\"rpcport\":7332,\"pubtype\":105,\"p2shtype\":5,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"DASH\",\"confpath\":\"\${HOME#}/.dashcore/dash.conf\",\"name\":\"dashcore\",\"rpcport\":9998,\"pubtype\":76,\"p2shtype\":16,\"wiftype\":204,\"txfee\":10000}, {\"coin\":\"STRAT\", \"name\": \"stratis\", \"active\":0, \"rpcport\":16174,\"pubtype\":63, \"p2shtype\":125, \"wiftype\":191, \"txfee\":10000}, {\"confpath\":\"\${HOME#}/.muecore/mue.conf\",\"coin\":\"MUE\",\"name\":\"muecore\",\"rpcport\":29683,\"pubtype\":16,\"p2shtype\":76,\"wiftype\":126,\"txfee\":10000}, {\"coin\":\"MONA\",\"name\":\"monacoin\",\"rpcport\":9402,\"pubtype\":50,\"p2shtype\":5,\"wiftype\":176,\"txfee\":100000},{\"coin\":\"XMY\",\"name\":\"myriadcoin\",\"rpcport\":10889,\"pubtype\":50,\"p2shtype\":9,\"wiftype\":178,\"txfee\":5000}, {\"coin\":\"MAC\",\"name\":\"machinecoin\",\"rpcport\":40332,\"pubtype\":50,\"p2shtype\":5,\"wiftype\":178,\"txfee\":100000}, {\"coin\":\"BTX\",\"name\":\"bitcore\",\"rpcport\":8556,\"pubtype\":0,\"p2shtype\":5,\"wiftype\":128,\"txfee\":50000}, {\"coin\":\"XRE\",\"name\":\"revolvercoin\",\"rpcport\":8775,\"pubtype\":0,\"p2shtype\":5,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"LBC\",\"name\":\"lbrycrd\",\"rpcport\":9245,\"pubtype\":85,\"p2shtype\":122,\"wiftype\":28,\"txfee\":10000}, {\"coin\":\"SIB\",\"name\":\"sibcoin\",\"rpcport\":1944,\"pubtype\":63,\"p2shtype\":40,\"wiftype\":128,\"txfee\":10000}, {\"coin\":\"VTC\", \"name\":\"vertcoin\", \"rpcport\":5888, \"pubtype\":71, \"p2shtype\":5, \"wiftype\":128, \"txfee\":100000 }, {\"coin\":\"REVS\",\"active\":0, \"asset\":\"REVS\",\"rpcport\":10196}, {\"coin\":\"JUMBLR\",\"active\":0, \"asset\":\"JUMBLR\",\"rpcport\":15106}, {\"coin\":\"DOGE\",\"name\":\"dogecoin\",\"rpcport\":22555,\"pubtype\":30,\"p2shtype\":22,\"wiftype\":158,\"txfee\":100000000}, {\"coin\":\"HUSH\",\"name\":\"hush\",\"rpcport\":8822,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":1000  }, {\"active\":0,\"coin\":\"ZEC\",\"name\":\"zcash\",\"rpcport\":8232,\"taddr\":28,\"pubtype\":184,\"p2shtype\":189,\"wiftype\":128,\"txfee\":10000,\"txversion\":3 }, {\"active\":0,\"coin\":\"ZECTEST\",\"name\":\"zcashtest\",\"rpcport\":8232,\"taddr\":29,\"pubtype\":37,\"p2shtype\":186,\"wiftype\":239,\"txfee\":10000,\"txversion\":4}, {\"coin\":\"DGB\",\"name\":\"digibyte\",\"rpcport\":14022,\"pubtype\":30,\"p2shtype\":5,\"wiftype\":128,\"txfee\":100000}, {\"coin\":\"ZET\", \"name\":\"zetacoin\", \"pubtype\":80, \"p2shtype\":9,\"rpcport\":8332, \"wiftype\":224, \"txfee\":10000}, {\"coin\":\"GAME\", \"rpcport\":40001, \"name\":\"gamecredits\", \"pubtype\":38, \"p2shtype\":5, \"wiftype\":166, \"txfee\":100000}, {\"coin\":\"LTC\", \"name\":\"litecoin\", \"rpcport\":9332, \"pubtype\":48, \"p2shtype\":5, \"wiftype\":176, \"txfee\":100000 }, {\"coin\":\"SUPERNET\",\"asset\":\"SUPERNET\",\"rpcport\":11341}, {\"coin\":\"WLC\",\"asset\":\"WLC\",\"rpcport\":12167}, {\"coin\":\"PANGEA\",\"asset\":\"PANGEA\",\"rpcport\":14068}, {\"coin\":\"DEX\",\"asset\":\"DEX\",\"rpcport\":11890}, {\"coin\":\"BET\",\"asset\":\"BET\",\"rpcport\":14250}, {\"coin\":\"CRYPTO\",\"asset\":\"CRYPTO\",\"rpcport\":8516}, {\"coin\":\"HODL\",\"asset\":\"HODL\",\"rpcport\":14431}, {\"coin\":\"MSHARK\",\"asset\":\"MSHARK\",\"rpcport\":8846}, {\"coin\":\"BOTS\",\"asset\":\"BOTS\",\"rpcport\":11964}, {\"coin\":\"MGW\",\"asset\":\"MGW\",\"rpcport\":12386}, {\"coin\":\"COQUI\",\"asset\":\"COQUI\",\"rpcport\":14276}, {\"coin\":\"KV\",\"asset\":\"KV\",\"rpcport\":8299}, {\"coin\":\"CEAL\",\"asset\":\"CEAL\",\"rpcport\":11116}, {\"coin\":\"MESH\",\"asset\":\"MESH\",\"rpcport\":9455}]';

    mm2Process = await Process.start(
        './mm2',
        [
          '{\"gui\":\"MM2GUI\",\"netid\":9999,\"client\":1,\"userhome\":\"/data/data/com.komodoplatform.komododex/files/\",\"passphrase\":\"$passphrase\",\"rpc_password\":\"$userpass\",\"coins\":$coins}',
        ],
        workingDirectory: '/data/data/com.komodoplatform.komododex/files');

    final Completer<int> completer = new Completer<int>();

    mm2Process.stdout.firstWhere((List<int> event) {
      print("mm2: " + utf8.decoder.convert(event).trim());
      if (utf8.decoder.convert(event).trim().contains(
          "DEX stats API enabled at")) {
        print("OKOKOKOKOKOKOKOKOK----------------");
        return true;
      }
    });

  }

  void killmm2() {
    if (mm2Process != null) {
      mm2Process.kill();
      this.coins = List<Coin>();
      activeCoinBool = true;
      ismm2Running = true;
    }
  }

  Future<File> get _localFile async {
    return File('/data/data/com.komodoplatform.komododex/files/mm2');
  }

  Future<File> writeData(List<int> data) async {
    final file = await _localFile;
    return file.writeAsBytes(data);
  }

  Future<Orderbook> getOrderbook(Coin coinBase, Coin coinRel) async {
    GetOrderbook getOrderbook = new GetOrderbook(
        userpass: userpass,
        method: 'orderbook',
        base: coinBase.abbr,
        rel: coinRel.abbr);
    final response = await http.post(url, body: json.encode(getOrderbook));
    print(response.body.toString());
    return orderbookFromJson(response.body);
  }

  Future<List<Coin>> loadJsonCoins() async {
    print("loadJsonCoins");
    String jsonString = await this.loadElectrumServersAsset();
    Iterable l = json.decode(jsonString);
    List<Coin> coins = l.map((model) => Coin.fromJson(model)).toList();
    this.coins = coins;
    return coins;
  }

  Future<Balance> getBalance(Coin coin) async {
    GetBalance getBalance = new GetBalance(
        userpass: userpass, method: "my_balance", coin: coin.abbr);
    final response = await http.post(url, body: json.encode(getBalance));
    print(response.body.toString());
    return balanceFromJson(response.body);
  }

  Future<List<Balance>> getAllBalances(bool forceUpdate) async {
    if (this.balances.isEmpty || forceUpdate) {
      List<Balance> balances = new List<Balance>();
      List<Future<Balance>> futureBalances = new List<Future<Balance>>();

      for (var coin in coins) {
        futureBalances.add(getBalance(coin));
      }
      balances = await Future.wait(futureBalances);

      this.balances = balances;
      return this.balances;
    } else {
      return this.balances;
    }
  }

  Future<dynamic> postBuy(Coin base, Coin rel, double relVolume, double price) async {
    GetBuy getBuy = new GetBuy(
        userpass: userpass,
        method: "buy",
        base: base.abbr,
        rel: rel.abbr,
        relvolume: relVolume,
        price: price);
    final response = await http.post(url, body: json.encode(getBuy));

    print(response.body.toString());
    try {
      return buyResponseFromJson(response.body);
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> postRawTransaction(Coin coin, String txHex) async {
    GetSendRawTransaction getSendRawTransaction = new GetSendRawTransaction(
        userpass: userpass,
        method: 'send_raw_transaction',
        coin: coin.abbr,
        txHex: txHex
    );

    final response = await http.post(
        url, body: json.encode(getSendRawTransaction));
    try {
      return sendRawTransactionResponseFromJson(response.body);
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> postWithdraw(Coin coin, String addressTo,
      double amount) async {
    GetWithdraw getWithdraw = new GetWithdraw(
      userpass: userpass,
      method: "withdraw",
      coin: coin.abbr,
      to: addressTo,
      amount: amount,
    );
    print(json.encode(getWithdraw));
    final response = await http.post(url, body: json.encode(getWithdraw));
    print("response.body postWithdraw" + response.body.toString());
    try {
      return withdrawResponseFromJson(response.body);
    } catch (e) {
      return e;
    }
  }

  Future<dynamic> activeCoin(Coin coin) async {
    GetActiveCoin getActiveCoin = new GetActiveCoin(
        userpass: userpass,
        method: "electrum",
        coin: coin.abbr,
        urls: coin.serverList);

    final response = await http.post(url, body: json.encode(getActiveCoin));
    print(response.body.toString());
    try {
      return activeCoinFromJson(response.body);
    } catch (e) {
      return errorFromJson(response.body);
    }
  }

  Future<String> loadElectrumServersAsset() async {
    return await rootBundle.loadString('assets/coins_config.json');
  }

  Future<List<CoinBalance>> loadCoins(bool forceUpdate) async {
    if (ismm2Running) {
      ismm2Running = false;
      await runBin().then((onValue){
        print("---------------------------");
        print(onValue);
        print("---------------------------");
      });
      List<Future<dynamic>> futureActiveCoins = new List<Future<dynamic>>();

      if (this.coins.isEmpty) {
        this.activeCoinBool = false;
        await this.loadJsonCoins();
      }

      for (var coin in this.coins) {
        if (!coin.isActive) {
          futureActiveCoins.add(this.activeCoin(coin));
          coin.isActive = true;
        }
      }
      await Future.wait(futureActiveCoins);
    }

    List<CoinBalance> listCoinElectrum = new List<CoinBalance>();
    List<Balance> balances = await getAllBalances(forceUpdate);

    for (var coin in this.coins) {
      for (var balance in balances) {
        if (coin.abbr == balance.coin)
          listCoinElectrum.add(CoinBalance(coin, balance));
      }
    }

    listCoinElectrum
        .sort((a, b) => a.balance.balance.compareTo(b.balance.balance));
    return listCoinElectrum.reversed.toList();
  }
}
