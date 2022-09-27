import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/visitor.dart';

abstract class HeaderNode extends Node {
  const HeaderNode({required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitHeader(this);
}

class ImportHeaderNode extends HeaderNode {
  final String library;
  final String? alias;

  const ImportHeaderNode({
    required this.library,
    this.alias,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitImportHeader(this);
}
