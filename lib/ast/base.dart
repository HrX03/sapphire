import 'package:antlr4/antlr4.dart';
import 'package:sapphire/ast/visitor.dart';

abstract class Node {
  final ParserRuleContext? context;

  const Node({required this.context});

  T? accept<T>(Visitor<T> visitor);
}
