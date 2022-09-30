import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/expression.dart';
import 'package:sapphire/ast/header.dart';
import 'package:sapphire/ast/type.dart';
import 'package:sapphire/ast/visitor.dart';

class FileNode extends Node {
  final List<HeaderNode> headers;
  final List<StatementNode> statements;

  const FileNode({
    required this.headers,
    required this.statements,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitFile(this);
}

abstract class StatementNode extends Node {
  const StatementNode({required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitStatement(this);
}

class DefineStatementNode extends StatementNode {
  final String identifier;
  final TypeNode type;
  final List<ArgumentNode>? parameters;
  final List<TypeArgumentNode>? typeParameters;
  final ExpressionNode assignedValue;
  final bool exported;

  const DefineStatementNode({
    required this.identifier,
    required this.type,
    this.parameters,
    this.typeParameters,
    required this.assignedValue,
    this.exported = false,
    required super.context,
    // ignore: avoid_bool_literals_in_conditional_expressions
  }) : assert(typeParameters != null ? parameters != null : true);

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitDefineStatement(this);
}

class ArgumentNode extends Node {
  final String id;
  final TypeNode type;

  const ArgumentNode({
    required this.id,
    required this.type,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitArgument(this);
}

class TypeArgumentNode extends Node {
  final String id;
  final TypeNode? baseType;

  const TypeArgumentNode({
    required this.id,
    required this.baseType,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitTypeArgument(this);
}

class ReturnStatementNode extends StatementNode {
  final ExpressionNode? value;

  const ReturnStatementNode({required this.value, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitReturnStatement(this);
}

class UndefineStatementNode extends StatementNode {
  final String id;

  const UndefineStatementNode({required this.id, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitUndefineStatement(this);
}

class AssignStatementNode extends StatementNode {
  final String id;
  final ExpressionNode value;

  const AssignStatementNode({
    required this.id,
    required this.value,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitAssignStatement(this);
}

class ConditionalStatementNode extends StatementNode {
  final Map<ExpressionNode, ScopeNode> conditions;
  final ScopeNode? elseScope;

  const ConditionalStatementNode({
    required this.conditions,
    required this.elseScope,
    required super.context,
  });

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitConditionalStatement(this);
}

class WhileStatementNode extends StatementNode {
  final ExpressionNode condition;
  final List<StatementNode> statements;

  const WhileStatementNode({
    required this.condition,
    required this.statements,
    required super.context,
  });
}
