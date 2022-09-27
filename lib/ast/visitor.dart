import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/expression.dart';
import 'package:sapphire/ast/header.dart';
import 'package:sapphire/ast/statements.dart';
import 'package:sapphire/ast/type.dart';

abstract class Visitor<T> {
  const Visitor();

  T? visit(Node node) => node.accept(this);

  T? visitFile(FileNode node);

  T? visitHeader(HeaderNode node);
  T? visitImportHeader(ImportHeaderNode node);

  T? visitStatement(StatementNode node);
  T? visitDefineStatement(DefineStatementNode node);
  T? visitReturnStatement(ReturnStatementNode node);
  T? visitUndefineStatement(UndefineStatementNode node);
  T? visitAssignStatement(AssignStatementNode node);
  T? visitConditionalStatement(ConditionalStatementNode node);
  T? visitWhileStatement(WhileStatementNode node);

  T? visitArgument(ArgumentNode node);

  T? visitExpression(ExpressionNode node);
  T? visitIdentifier(IdentifierNode node);
  T? visitScope(ScopeNode node);
  T? visitString(StringNode node);
  T? visitTuple(TupleNode node);
  T? visitList(ListNode node);
  T? visitDict(DictNode node);
  T? visitLiteral(LiteralNode node);
  T? visitNumber(NumberNode node);
  T? visitBoolean(BooleanNode node);
  T? visitThis(ThisNode node);
  T? visitRoot(RootNode node);
  T? visitNone(NoneNode node);

  T? visitType(TypeNode node);
  T? visitComplexType(ComplexTypeNode node);
  T? visitFunctionType(FunctionTypeNode node);
  T? visitTypeList(TypeListNode node);
}

class SimpleVisitor<T> extends Visitor<T> {
  const SimpleVisitor();

  @override
  T? visitFile(FileNode node) => null;

  @override
  T? visitHeader(HeaderNode node) => null;

  @override
  T? visitImportHeader(ImportHeaderNode node) => null;

  @override
  T? visitStatement(StatementNode node) => null;

  @override
  T? visitDefineStatement(DefineStatementNode node) => null;

  @override
  T? visitReturnStatement(ReturnStatementNode node) => null;

  @override
  T? visitUndefineStatement(UndefineStatementNode node) => null;

  @override
  T? visitAssignStatement(AssignStatementNode node) => null;

  @override
  T? visitConditionalStatement(ConditionalStatementNode node) => null;

  @override
  T? visitWhileStatement(WhileStatementNode node) => null;

  @override
  T? visitArgument(ArgumentNode node) => null;

  @override
  T? visitExpression(ExpressionNode node) => null;

  @override
  T? visitIdentifier(IdentifierNode node) => null;

  @override
  T? visitScope(ScopeNode node) => null;

  @override
  T? visitString(StringNode node) => null;

  @override
  T? visitTuple(TupleNode node) => null;

  @override
  T? visitList(ListNode node) => null;

  @override
  T? visitDict(DictNode node) => null;

  @override
  T? visitLiteral(LiteralNode node) => null;

  @override
  T? visitNumber(NumberNode node) => null;

  @override
  T? visitBoolean(BooleanNode node) => null;

  @override
  T? visitThis(ThisNode node) => null;

  @override
  T? visitRoot(RootNode node) => null;

  @override
  T? visitNone(NoneNode node) => null;

  @override
  T? visitType(TypeNode node) => null;

  @override
  T? visitComplexType(ComplexTypeNode node) => null;

  @override
  T? visitTypeList(TypeListNode node) => null;

  @override
  T? visitFunctionType(FunctionTypeNode node) => null;
}

class RecursiveVisitor<T> extends SimpleVisitor<T> {
  const RecursiveVisitor();

  void _visitList(Iterable<Node>? nodes) {
    if (nodes == null) return;

    for (final Node node in nodes) {
      node.accept(this);
    }
  }

  @override
  T? visitFile(FileNode node) {
    _visitList(node.headers);
    _visitList(node.statements);

    return null;
  }

  @override
  T? visitDefineStatement(DefineStatementNode node) {
    node.type.accept(this);
    _visitList(node.arguments);
    node.assignedValue.accept(this);

    return null;
  }

  @override
  T? visitReturnStatement(ReturnStatementNode node) {
    node.value?.accept(this);

    return null;
  }

  @override
  T? visitAssignStatement(AssignStatementNode node) {
    node.value.accept(this);

    return null;
  }

  @override
  T? visitConditionalStatement(ConditionalStatementNode node) {
    node.conditions.forEach((key, value) {
      key.accept(this);
      value.accept(this);
    });
    node.elseScope?.accept(this);

    return null;
  }

  @override
  T? visitWhileStatement(WhileStatementNode node) {
    node.condition.accept(this);
    _visitList(node.statements);

    return null;
  }

  @override
  T? visitArgument(ArgumentNode node) {
    node.type.accept(this);

    return null;
  }

  @override
  T? visitScope(ScopeNode node) {
    _visitList(node.statements);

    return null;
  }

  @override
  T? visitTuple(TupleNode node) {
    _visitList(node.values);

    return null;
  }

  @override
  T? visitList(ListNode node) {
    _visitList(node.values);

    return null;
  }

  @override
  T? visitDict(DictNode node) {
    _visitList(node.values.entries.expand((e) => [e.key, e.value]));
    return null;
  }

  @override
  T? visitComplexType(ComplexTypeNode node) {
    node.types?.accept(this);

    return null;
  }

  @override
  T? visitTypeList(TypeListNode node) {
    _visitList(node.types);
    return null;
  }

  @override
  T? visitFunctionType(FunctionTypeNode node) {
    node.returnType.accept(this);
    node.types?.accept(this);

    return null;
  }
}
