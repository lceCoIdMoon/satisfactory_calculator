import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:satisfactory_calculator/node_graph.dart';

_NodeState? firstNode;

class Node extends StatefulWidget {
  const Node({required this.mode, required this.graph, required this.initialPosX, required this.initialPosY, Key? key}) : super(key: key);

  final NodeMode mode;

  final double initialPosX;
  final double initialPosY;

  final NodeGraphState graph;

  @override
  State<Node> createState() => _NodeState();
}

class _NodeState extends State<Node> {
  late StreamSubscription _onResetSubscription;
  late StreamSubscription _onTick2Subscription;

  double value = 0.0;
  int outputs = 0;

  late NodePort leftPort;
  late NodePort topPort;
  late NodePort rightPort;
  late NodePort bottomPort;

  double posX = 0.0;
  double posY = 0.0;

  double size = 100.0;

  final StreamController _onRemoveController = StreamController.broadcast();
  late Stream onRemove;

  final StreamController _onMoveController = StreamController.broadcast();
  late Stream onMove;

  @override
  void initState() {
    firstNode ??= this;

    posX = widget.initialPosX;
    posY = widget.initialPosY;

    onRemove = _onRemoveController.stream;
    onMove = _onMoveController.stream;

    if (widget.mode == NodeMode.merge) {
      leftPort = NodePort(parent: this, mode: PortMode.input, facing: 0);
      topPort = NodePort(parent: this, mode: PortMode.input, facing: 1);
      rightPort = NodePort(parent: this, mode: PortMode.output, facing: 2);
      bottomPort = NodePort(parent: this, mode: PortMode.input, facing: 3);
    } else {
      leftPort = NodePort(parent: this, mode: PortMode.input, facing: 0);
      topPort = NodePort(parent: this, mode: PortMode.output, facing: 1);
      rightPort = NodePort(parent: this, mode: PortMode.output, facing: 2);
      bottomPort = NodePort(parent: this, mode: PortMode.output, facing: 3);
    }

    _onResetSubscription = onReset.listen((event) => setState(() => value = 0.0));
    _onTick2Subscription = onTick2.listen((event) => tick2());

    super.initState();
  }

  double toBeAdded = 0.0;
  void input(double amount) => toBeAdded += amount;

  void tick2() {
    outputs = 0;
    setState(() {
      value = toBeAdded;
      toBeAdded = 0.0;
    });
  }

  void remove() {
    _onRemoveController.add(null);
    widget.graph.setState(() => widget.graph.nodes.remove(widget));
  }

  @override
  void dispose() {
    _onResetSubscription.cancel();
    _onTick2Subscription.cancel();
    if (firstNode == this) firstNode = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.mode == NodeMode.merge ? Colors.redAccent : Colors.green;

    return Positioned(
      top: posY,
      left: posX,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            posX += details.delta.dx;
            posY += details.delta.dy;
          });
          _onMoveController.add(null);
        },
        onSecondaryTapUp: (details) async {
          (await showMenu(context: context, position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy), items: [
            PopupMenuItem(child: Text('Remove'), height: 36.0, value: () => remove()),
          ]))
              ?.call();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.mode == NodeMode.merge ? Text('Merge') : Text('Split'),
                  Text(value.toStringAsFixed(1)),
                ],
              ),
              Positioned(top: 0.0, right: 4.0, child: Text(outputs.toString())),
              Positioned(left: 6.0, child: leftPort),
              Positioned(top: 6.0, child: topPort),
              Positioned(right: 6.0, child: rightPort),
              Positioned(bottom: 6.0, child: bottomPort),
            ],
          ),
        ),
      ),
    );
  }
}

enum PortMode {
  input,
  output,
}

enum NodeMode {
  split,
  merge,
}

const radToDeg = 180 / pi;
const degToRad = pi / 180;

class NodePort extends StatefulWidget {
  const NodePort({required this.parent, required this.mode, required this.facing, Key? key}) : super(key: key);

  final _NodeState parent;

  final PortMode mode;
  final int facing;

  @override
  State<NodePort> createState() => _NodePortState();
}

class _NodePortState extends State<NodePort> {
  late StreamSubscription _onTick0Subscription;
  late StreamSubscription _onTick1Subscription;
  late StreamSubscription _onRemoveSubscription;
  late StreamSubscription _onMoveSubscription;

  bool isLineStart = false;
  Line? line;
  _NodePortState? connection;

  Offset get pos {
    const dist = 54.0;
    final offset = Offset(widget.parent.posX, widget.parent.posY) + Offset(widget.parent.size, widget.parent.size) / 2;
    switch (widget.facing) {
      case 0:
        return offset + Offset(-dist, 0.0);
      case 1:
        return offset + Offset(0.0, -dist);
      case 2:
        return offset + Offset(dist, 0.0);
      case 3:
        return offset + Offset(0.0, dist);
    }
    return offset;
  }

  @override
  void initState() {
    if (widget.mode == PortMode.output) {
      _onTick0Subscription = onTick0.listen((event) => tick0());
      _onTick1Subscription = onTick1.listen((event) => tick1());
    }
    _onRemoveSubscription = widget.parent.onRemove.listen((event) => remove());
    _onMoveSubscription = widget.parent.onMove.listen((event) {
      if (line != null) {
        if (isLineStart)
          line!.start = pos;
        else
          line!.end = pos;
      }
      repaintLines();
    });
    super.initState();
  }

  void tick0() {
    if (connection != null) widget.parent.outputs++;
  }

  void tick1() {
    if (connection == null) return;
    final amount = widget.parent.value / widget.parent.outputs;
    connection!.widget.parent.input(amount);
  }

  @override
  void dispose() {
    if (widget.mode == PortMode.output) {
      _onTick0Subscription.cancel();
      _onTick1Subscription.cancel();
    }
    _onRemoveSubscription.cancel();
    _onMoveSubscription.cancel();
    super.dispose();
  }

  void disconnect() {
    connection = null;
    lines.remove(line);
    line = null;
  }

  void remove() {
    connection?.disconnect();
    disconnect();
    repaintLines();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () {
        remove();
      },
      child: DragTarget(
          onWillAccept: (data) {
            final port = data as _NodePortState;
            return port != this && port.widget.parent != widget.parent && port.widget.mode != widget.mode;
          },
          onAccept: (other) {
            connection?.disconnect();
            connection = other as _NodePortState;

            connection!.connection?.disconnect();
            connection!.connection = this;

            connection!.isLineStart = true;
            isLineStart = false;

            connection!.line = line = Line(connection!.pos, pos);
            lines.add(line!);

            repaintLines();
          },
          builder: (context, candidateData, rejectedData) => Draggable(
            dragAnchorStrategy:(draggable, context, position) => Offset(2.5, 2.5),
                data: this,
                feedback: Container(
                  width: 5.0,
                  height: 5.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(4.0),
                    color: Colors.black54,
                  ),
                  child: Transform.rotate(angle: (widget.facing - 1 + (widget.mode == PortMode.input ? 2 : 0)) * 90 * degToRad, child: Icon(Icons.arrow_upward, size: 14.0, color: widget.mode == PortMode.input ? Colors.green : Colors.orange)),
                ),
              )),
    );
  }
}
