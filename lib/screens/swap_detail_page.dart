import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/swap_history_bloc.dart';
import 'package:komodo_dex/model/coin.dart';
import 'package:komodo_dex/model/swap.dart';
import 'package:komodo_dex/model/uuid.dart';
import 'package:komodo_dex/utils/utils.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import 'package:flutter_svg/flutter_svg.dart';

class SwapDetailPage extends StatefulWidget {
  final Swap swap;

  SwapDetailPage({@required this.swap});

  @override
  _SwapDetailPageState createState() => _SwapDetailPageState();
}

class _SwapDetailPageState extends State<SwapDetailPage> {
  bool isAnimationStepFinalIsFinish = false;

  @override
  void initState() {
    swapHistoryBloc.updateSwap();
    if (widget.swap.status != null &&
        widget.swap.status == Status.SWAP_SUCCESSFUL)
      isAnimationStepFinalIsFinish = true;
    print(widget.swap.uuid.uuid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).backgroundColor,
      ),
      body: StreamBuilder<List<Swap>>(
          stream: swapHistoryBloc.outSwaps,
          builder: (context, snapshot) {
            Swap swapData = new Swap();

            if (snapshot.hasData && snapshot.data.length > 0) {
              snapshot.data.forEach((swap) {
                if (swap.uuid.uuid == widget.swap.uuid.uuid) swapData = swap;
              });
              if (swapData.status == Status.SWAP_SUCCESSFUL &&
                  isAnimationStepFinalIsFinish) {
                return FinalTradeSuccess(
                    uuid: widget.swap.uuid, swap: swapData);
              } else {
                return StepperTrade(
                    uuid: widget.swap.uuid,
                    swap: swapData,
                    onStepFinish: () {
                      setState(() {
                        isAnimationStepFinalIsFinish = true;
                      });
                    });
              }
            } else {
              return Container();
            }
          }),
    );
  }
}

class FinalTradeSuccess extends StatefulWidget {
  final Uuid uuid;
  final Swap swap;

  FinalTradeSuccess({@required this.swap, @required this.uuid});

  @override
  _FinalTradeSuccessState createState() => _FinalTradeSuccessState();
}

class _FinalTradeSuccessState extends State<FinalTradeSuccess>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    animation = Tween(begin: -0.5, end: 0.0).animate(CurvedAnimation(
        parent: animationController, curve: Curves.fastOutSlowIn));
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animationController.drive(CurveTween(curve: Curves.easeOut)),
      child: Center(
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 32,
            ),
            Container(
              height: 200,
              child: SvgPicture.asset("assets/trade_success.svg",
                  semanticsLabel: 'Trade Success'),
            ),
            SizedBox(
              height: 32,
            ),
            Column(
              children: <Widget>[
                Text("TRADE", style: Theme.of(context).textTheme.title),
                Text(
                  "COMPLETED!",
                  style: Theme.of(context)
                      .textTheme
                      .title
                      .copyWith(color: Theme.of(context).accentColor),
                ),
              ],
            ),
            SizedBox(
              height: 32,
            ),
            Container(
              color: Color.fromARGB(255, 52, 62, 76),
              height: 1,
              width: double.infinity,
            ),
            DetailSwap(
              uuid: widget.uuid,
              swap: widget.swap,
            )
          ],
        ),
      ),
    );
  }
}

class StepperTrade extends StatefulWidget {
  final Uuid uuid;
  final Swap swap;
  final Function onStepFinish;

  StepperTrade({@required this.uuid, this.swap, this.onStepFinish});

  @override
  _StepperTradeState createState() => _StepperTradeState();
}

class _StepperTradeState extends State<StepperTrade> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ProgressSwap(
            uuid: widget.uuid,
            swap: widget.swap,
            onStepFinish: widget.onStepFinish),
        DetailSwap(
          uuid: widget.uuid,
          swap: widget.swap,
        )
      ],
    );
  }
}

class ProgressSwap extends StatefulWidget {
  final Uuid uuid;
  final Swap swap;
  final Function onStepFinish;

  ProgressSwap({@required this.uuid, this.swap, this.onStepFinish});

  @override
  _ProgressSwapState createState() => _ProgressSwapState();
}

class _ProgressSwapState extends State<ProgressSwap>
    with SingleTickerProviderStateMixin {
  AnimationController _radialProgressAnimationController;
  Animation<double> _progressAnimation;
  final Duration fadeInDuration = Duration(milliseconds: 500);
  final Duration fillDuration = Duration(seconds: 1);

  double progressDegrees = 0;
  var count = 0;
  Swap swapTmp = new Swap();

  @override
  void initState() {
    super.initState();
    swapTmp = widget.swap;
    _radialProgressAnimationController =
        AnimationController(vsync: this, duration: fillDuration);
    _initAnimation(0.0);
  }

  _initAnimation(double begin) {
    _progressAnimation = null;
    _progressAnimation = Tween(begin: begin, end: 360.0).animate(
        CurvedAnimation(
            parent: _radialProgressAnimationController, curve: Curves.easeIn))
      ..addListener(() {
        setState(() {
          progressDegrees =
              (swapHistoryBloc.getStepStatusNumber(widget.swap.status) /
                      swapHistoryBloc.getNumberStep()) *
                  _progressAnimation.value;
          if (progressDegrees == 360) widget.onStepFinish();
        });
      });

    _radialProgressAnimationController.forward();
  }

  @override
  void dispose() {
    _radialProgressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (swapTmp.status != widget.swap.status) {
      swapTmp = widget.swap;
      _radialProgressAnimationController.value = 0;
      _radialProgressAnimationController.reset();
      if (swapHistoryBloc.getNumberStep() ==
          swapHistoryBloc.getStepStatusNumber(widget.swap.status)) {
        _initAnimation(((360 / swapHistoryBloc.getNumberStep()) *
                swapHistoryBloc.getStepStatusNumber(widget.swap.status)) -
            (360 / swapHistoryBloc.getNumberStep()));
      } else {
        _initAnimation((360 / swapHistoryBloc.getNumberStep()) *
            swapHistoryBloc.getStepStatusNumber(widget.swap.status));
      }
    }

    return Expanded(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          CustomPaint(
            painter: RadialPainter(
                context: context, progressInDegrees: progressDegrees),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Step ",
                    style: Theme.of(context).textTheme.subtitle,
                  ),
                  Text(
                    swapHistoryBloc
                        .getStepStatusNumber(widget.swap.status)
                        .toString(),
                    style: Theme.of(context)
                        .textTheme
                        .subtitle
                        .copyWith(color: Theme.of(context).accentColor),
                  ),
                  Text('/${swapHistoryBloc.getNumberStep().toInt().toString()}',
                      style: Theme.of(context).textTheme.subtitle)
                ],
              ),
            ),
          ),
          Positioned(
              bottom: MediaQuery.of(context).size.height * 0.06,
              child: Text(
                swapHistoryBloc.getSwapStatusString(
                    context, widget.swap.status),
                style: Theme.of(context).textTheme.body1.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.5)),
              ))
        ],
      ),
    );
  }
}

class DetailSwap extends StatefulWidget {
  final Uuid uuid;
  final Swap swap;

  DetailSwap({@required this.uuid, @required this.swap});

  @override
  _DetailSwapState createState() => _DetailSwapState();
}

class _DetailSwapState extends State<DetailSwap> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          color: Color.fromARGB(255, 52, 62, 76),
          height: 1,
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32, left: 24, right: 24),
          child: Text(
            'TRADE DETAIL:',
            style: Theme.of(context).textTheme.subtitle.copyWith(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 4),
          child: Text(
            "Requested Trade:",
            style: Theme.of(context)
                .textTheme
                .body2
                .copyWith(fontWeight: FontWeight.w400),
          ),
        ),
        _buildAmountSwap(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: InkWell(
            onTap: (){
              copyToClipBoard(context, widget.swap.uuid.uuid);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Swap ID:',
                      style: Theme.of(context).textTheme.body2,
                    ),
                  ),
                  Text(
                    widget.swap.uuid.uuid,
                    style: Theme.of(context)
                        .textTheme
                        .body1
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 32,
        )
      ],
    );
  }

  _buildAmountSwap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextAmount(
                  widget.swap.uuid.rel, widget.uuid.amountToBuy.toString()),
              Text(
                "Sell",
                style: Theme.of(context)
                    .textTheme
                    .body2
                    .copyWith(fontWeight: FontWeight.w400),
              )
            ],
          ),
          Expanded(
            child: Container(),
          ),
          _buildIcon(widget.swap.uuid.rel),
          Icon(
            Icons.sync,
            size: 20,
            color: Colors.white,
          ),
          _buildIcon(widget.swap.uuid.base),
          Expanded(
            child: Container(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _buildTextAmount(widget.swap.uuid.base,
                  widget.swap.uuid.amountToGet.toString()),
              Text(
                "Receive",
                style: Theme.of(context)
                    .textTheme
                    .body2
                    .copyWith(fontWeight: FontWeight.w400),
              )
            ],
          ),
        ],
      ),
    );
  }

  _buildTextAmount(Coin coin, String amount) {
    return Text(
      '${(double.parse(amount) % 1) == 0 ? double.parse(amount) : double.parse(amount).toStringAsFixed(4)} ${coin.abbr}',
      style: Theme.of(context)
          .textTheme
          .body1
          .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  _buildIcon(Coin coin) {
    return Container(
      height: 25,
      width: 25,
      child: Image.asset(
        "assets/${coin.abbr.toLowerCase()}.png",
        fit: BoxFit.cover,
      ),
    );
  }
}

class RadialPainter extends CustomPainter {
  final double progressInDegrees;
  final BuildContext context;

  RadialPainter({@required this.context, this.progressInDegrees});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Color.fromARGB(255, 52, 62, 76)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0;

    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);

    Paint progressPaint = Paint()
      ..shader = LinearGradient(colors: [
        Color.fromARGB(255, 40, 80, 114),
        Theme.of(context).accentColor
      ]).createShader(Rect.fromCircle(center: center, radius: size.width / 2))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width / 2),
        math.radians(-90),
        math.radians(progressInDegrees),
        false,
        progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}