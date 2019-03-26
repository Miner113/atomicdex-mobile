import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komodo_dex/blocs/coins_bloc.dart';
import 'package:komodo_dex/localizations.dart';
import 'package:komodo_dex/model/balance.dart';
import 'package:komodo_dex/model/coin.dart';
import 'package:komodo_dex/model/coin_balance.dart';
import 'package:komodo_dex/screens/coin_detail.dart';
import 'package:komodo_dex/services/market_maker_service.dart';
import 'package:komodo_dex/widgets/photo_widget.dart';

class BlocCoinsPage extends StatefulWidget {
  @override
  _BlocCoinsPageState createState() => _BlocCoinsPageState();
}

class _BlocCoinsPageState extends State<BlocCoinsPage> {
  ScrollController _scrollController;
  double _heightFactor = 7;
  BuildContext contextMain;
  NumberFormat f = new NumberFormat("###,##0.0#");

  _scrollListener() {
    setState(() {
      _heightFactor = (exp(-_scrollController.offset / 60) * 6) + 1;
    });
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    coinsBloc.updateBalanceForEachCoin(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _heightScreen = MediaQuery.of(context).size.height;
    double _widthScreen = MediaQuery.of(context).size.width;
    contextMain = context;

    return Scaffold(
      body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                leading: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _buildDialogSelectCoin();
                  },
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      coinsBloc.updateBalanceForEachCoin(true);
                    },
                  )
                ],
                backgroundColor: Theme.of(context).backgroundColor,
                expandedHeight: _heightScreen * 0.35,
                pinned: true,
                flexibleSpace: Builder(
                  builder: (context) {
                    return FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        centerTitle: true,
                        title: Container(
                          width: _widthScreen * 0.5,
                          child: Center(
                            heightFactor: _heightFactor,
                            child: StreamBuilder<List<CoinBalance>>(
                                initialData: coinsBloc.coinBalance,
                              stream: coinsBloc.outCoins,
                              builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    double totalBalanceUSD = 0;
                                    snapshot.data.forEach((coinBalance){
                                      totalBalanceUSD += coinBalance.balanceUSD;
                                    });
                                    return AutoSizeText(
                                      "\$${f.format(totalBalanceUSD)} USD",
                                      maxFontSize: 18,
                                      minFontSize: 12,
                                      style: Theme.of(context).textTheme.title,
                                      maxLines: 1,
                                    );
                                  } else {
                                    return Center(child: Container(child: CircularProgressIndicator(),));
                                  }
                                }
                            ),
                          ),
                        ),
                        background: Container(
                          child: Padding(
                            padding: EdgeInsets.only(top: _heightScreen * 0.23),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                LoadAsset(),
                                SizedBox(
                                  height: 14,
                                ),
                                BarGraph()
                              ],
                            ),
                          ),
                          height: _heightScreen * 0.35,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                stops: [0.01, 1],
                                colors: [
                                  Color.fromRGBO(39, 71, 110, 1),
                                  Theme
                                      .of(context)
                                      .accentColor,
                                ],
                              )),
                        ));
                  },
                ),
              ),
            ];
          },
          body: Container(
              color: Theme.of(context).backgroundColor, child: ListCoins())),
    );
  }

  void _buildDialogSelectCoin() async {
    var coins = await mm2.loadJsonCoins(await mm2.loadElectrumServersAsset());
    var coinsBalance = await coinsBloc.readJsonCoin();

    showDialog<List<Coin>>(
        context: context,
        builder: (BuildContext context) {
          List<SimpleDialogOption> listDialog = new List<SimpleDialogOption>();
          coins.forEach((coin) {
            bool isAlreadyAdded = false;
            coinsBalance.forEach((coinsBalance) {
              if (coin.abbr == coinsBalance.abbr) {
                isAlreadyAdded = true;
              }
            });
            if (!isAlreadyAdded) {
              SimpleDialogOption dialogItem = SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  coinsBloc.addCoin(coin).then((data) {
                    Scaffold.of(contextMain).showSnackBar(new SnackBar(
                      content: new Text(
                          AppLocalizations.of(contextMain).addingCoinSuccess(
                              coin.name)),
                    ));
                  });
                },
                child: Text(coin.abbr),
              );
              listDialog.add(dialogItem);
            }
          });
          return Theme(
            data: ThemeData(
                textTheme: Theme
                    .of(context)
                    .textTheme,
                dialogBackgroundColor: Theme
                    .of(context)
                    .dialogBackgroundColor),
            child: SimpleDialog(
              title: Text(AppLocalizations
                  .of(context)
                  .addCoin),
              children: listDialog,
            ),
          );
        });
  }
}

class BarGraph extends StatefulWidget {
  @override
  BarGraphState createState() {
    return new BarGraphState();
  }
}

class BarGraphState extends State<BarGraph> {
  @override
  Widget build(BuildContext context) {
    double _widthScreen = MediaQuery.of(context).size.width;
    double _widthBar = _widthScreen - 32;

    return StreamBuilder<List<CoinBalance>>(
      initialData: coinsBloc.coinBalance,
      stream: coinsBloc.outCoins,
      builder: (context, snapshot) {
        bool _isVisible = true;

        if (snapshot.hasData) {
          _isVisible = true;
        } else {
          _isVisible = false;
        }

        List<Container> barItem = List<Container>();

        if (snapshot.hasData) {
          double sumOfAllBalances = 0;

          snapshot.data.forEach((coinBalance) {
            sumOfAllBalances += coinBalance.balanceUSD;
          });

          snapshot.data.forEach((coinBalance) {
            if (coinBalance.balanceUSD > 0) {
              barItem.add(Container(
                color: Color(int.parse(coinBalance.coin.colorCoin)),
                width: _widthBar *
                    (((coinBalance.balanceUSD * 100) / sumOfAllBalances) /
                        100),
              ));
            }
          });
        }

        return AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Container(
              width: _widthBar,
              height: 16,
              child: Row(
                children: barItem,
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadAsset extends StatefulWidget {
  const LoadAsset({
    Key key,
  }) : super(key: key);

  @override
  LoadAssetState createState() {
    return new LoadAssetState();
  }
}

class LoadAssetState extends State<LoadAsset> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoinBalance>>(
      initialData: coinsBloc.coinBalance,
      stream: coinsBloc.outCoins,
      builder: (context, snapshot) {
        List<Widget> listRet = List<Widget>();
        if (snapshot.hasData) {
          int assetNumber = 0;

          snapshot.data.forEach((coinBalance) {
            if (coinBalance.balance.balance > 0) {
              assetNumber++;
            }
          });

          listRet.add(Icon(
            Icons.show_chart,
            color: Colors.white.withOpacity(0.8),
          ));
          listRet.add(Text(
            AppLocalizations.of(context).numberAssets(assetNumber.toString()),
            style: Theme.of(context).textTheme.caption,
          ));
          listRet.add(Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.8),
          ));
        } else {
          listRet.add(Container(
              height: 10,
              width: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.0,
              )));
        }
        return Container(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: listRet,
          ),
        );
      },
    );
  }
}

class ListCoins extends StatefulWidget {
  const ListCoins({
    Key key,
  }) : super(key: key);

  @override
  ListCoinsState createState() {
    return new ListCoinsState();
  }
}

class ListCoinsState extends State<ListCoins> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CoinBalance>>(
      initialData: coinsBloc.coinBalance,
      stream: coinsBloc.outCoins,
      builder: (context, snapshot) {
          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                if (snapshot.hasData && snapshot.data.length > 0) {
                  return ItemCoin(index: index, listCoinBalances: snapshot.data);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              }
          );
      },
    );
  }
}

class ItemCoin extends StatelessWidget {
  const ItemCoin(
      {Key key, @required this.listCoinBalances, @required this.index})
      : super(key: key);

  final List<CoinBalance> listCoinBalances;
  final int index;

  @override
  Widget build(BuildContext context) {
    double _heightScreen = MediaQuery.of(context).size.height;
    Coin coin = listCoinBalances[index].coin;
    CoinBalance coinbalance =listCoinBalances[index];
    Balance balance = listCoinBalances[index].balance;
    NumberFormat f = new NumberFormat("###,##0.########");

    return Card(
      elevation: 8,
      color: Theme.of(context).primaryColor,
      margin: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CoinDetail(listCoinBalances[index])),
          );
        },
        child: Container(
          height: _heightScreen * 0.15,
          child: Row(
            children: <Widget>[
              SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Builder(builder: (context) {
                    String coinStr = balance.coin.toLowerCase();
                      return PhotoHero(
                        radius: 28,
                        tag: "assets/${balance
                            .coin.toLowerCase()}.png",
                      );
                  }),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        coin.name.toUpperCase(),
                        style: Theme
                            .of(context)
                            .textTheme
                            .caption,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        "${f.format(balance.balance)} ${coin.abbr}",
                        style: Theme
                            .of(context)
                            .textTheme
                            .subtitle,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                         Builder(
                           builder: (context) {
                             NumberFormat f = new NumberFormat("###,##0.##");
                             return Text(
                                "\$${f.format(coinbalance.balanceUSD)} USD",
                                style: Theme.of(context).textTheme.body2,
                              );
                           }
                         )
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6)),
                child: Container(
                  color: Color(int.parse(coin.colorCoin)),
                  width: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}