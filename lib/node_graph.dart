import 'dart:async';

import 'package:flutter/material.dart';
import 'package:satisfactory_calculator/node.dart';

final _onTick0Controller = StreamController.broadcast(sync: true);
final onTick0 = _onTick0Controller.stream;

final _onTick1Controller = StreamController.broadcast(sync: true);
final onTick1 = _onTick1Controller.stream;

final _onTick2Controller = StreamController.broadcast(sync: true);
final onTick2 = _onTick2Controller.stream;

final _onResetController = StreamController.broadcast(sync: true);
final onReset = _onResetController.stream;

class NodeGraph extends StatefulWidget {
  const NodeGraph({Key? key}) : super(key: key);

  @override
  State<NodeGraph> createState() => NodeGraphState();
}

class NodeGraphState extends State<NodeGraph> {
  late Timer _timer;

  final nodes = <Node>[];

  @override
  void initState() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      firstNode?.input(105);
      _onTick0Controller.add(null);
      _onTick1Controller.add(null);
      _onTick2Controller.add(null);
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) async {
        (await showMenu(context: context, position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy), items: [
          PopupMenuItem(child: Text('Split'), height: 36.0, value: () => nodes.add(Node(mode: NodeMode.split, graph: this, initialPosX: details.globalPosition.dx, initialPosY: details.globalPosition.dy, key: GlobalKey()))),
          PopupMenuItem(child: Text('Merge'), height: 36.0, value: () => nodes.add(Node(mode: NodeMode.merge, graph: this, initialPosX: details.globalPosition.dx, initialPosY: details.globalPosition.dy, key: GlobalKey()))),
        ]))
            ?.call();
        setState(() {});
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Lines(),
            ...nodes,
            Positioned(
              top: 20.0,
              right: 20.0,
              child: Row(
                children: [
                  ElevatedButton(
                    child: Text('Reset'),
                    onPressed: () => _onResetController.add(null),
                  ),
                  SizedBox(width: 14.0),
                  ElevatedButton(
                    child: Text('Clear'),
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () {
                      lines.clear();
                      setState(() => nodes.clear());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final lines = <Line>[];

class Line {
  Offset start;
  Offset end;

  Line(this.start, this.end);
}

void repaintLines() => _onRpaintLinesController.add(null);

final _onRpaintLinesController = StreamController();
final _onRepaintLines = _onRpaintLinesController.stream;

class Lines extends StatefulWidget {
  const Lines({Key? key}) : super(key: key);

  @override
  _LinesState createState() => _LinesState();
}

class _LinesState extends State<Lines> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = _onRepaintLines.listen((event) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: ((context, constraints) => CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: LinesPainter(),
            )));
  }
}

class LinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    lines.forEach((e) {
      canvas.drawLine(
        e.start,
        e.end,
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
    });
  }

  @override
  bool shouldRepaint(LinesPainter oldDelegate) {
    return true;
  }
}
