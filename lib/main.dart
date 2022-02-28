import 'package:flutter/material.dart';
import 'package:satisfactory_calculator/node_graph.dart';

void main(List<String> args) {
  runApp(MaterialApp(home: NodeGraph(), debugShowCheckedModeBanner: false, theme: ThemeData(brightness: Brightness.dark, visualDensity: VisualDensity(horizontal: VisualDensity.maximumDensity, vertical: VisualDensity.maximumDensity))));
}
