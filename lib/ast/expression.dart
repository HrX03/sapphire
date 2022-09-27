import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/statements.dart';
import 'package:sapphire/ast/visitor.dart';

abstract class ExpressionNode extends Node {
  const ExpressionNode({required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitExpression(this);
}

class IdentifierNode extends ExpressionNode implements StatementNode {
  final String? libraryId;
  final String identifier;
  final List<ExpressionNode>? arguments;

  const IdentifierNode({
    required this.identifier,
    this.libraryId,
    this.arguments,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitIdentifier(this);
}

class ScopeNode extends ExpressionNode implements StatementNode {
  final List<StatementNode> statements;

  const ScopeNode({required this.statements, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitScope(this);
}

class StringNode extends ExpressionNode {
  final String contents;

  const StringNode({required this.contents, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitString(this);
}

class TupleNode extends ExpressionNode {
  final List<ExpressionNode> values;

  const TupleNode({required this.values, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitTuple(this);
}

class ListNode extends ExpressionNode {
  final List<ExpressionNode> values;

  const ListNode({required this.values, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitList(this);
}

class DictNode extends ExpressionNode {
  final Map<ExpressionNode, ExpressionNode> values;

  const DictNode({required this.values, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitDict(this);
}

abstract class LiteralNode<T> extends ExpressionNode {
  final T value;

  const LiteralNode({required this.value, required super.context});

  @override
  V? accept<V>(Visitor<V> visitor) => visitor.visitLiteral(this);
}

class NumberNode extends LiteralNode<num> {
  const NumberNode({required super.value, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitNumber(this);
}

class BooleanNode extends LiteralNode<bool> {
  const BooleanNode({required super.value, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitBoolean(this);
}

class ThisNode extends LiteralNode<void> {
  const ThisNode({required super.context}) : super(value: null);

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitThis(this);
}

class RootNode extends LiteralNode<void> {
  const RootNode({required super.context}) : super(value: null);

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitRoot(this);
}

class NoneNode extends LiteralNode<void> {
  const NoneNode({required super.context}) : super(value: null);

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitNone(this);
}
