import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/expression.dart';
import 'package:sapphire/ast/visitor.dart';

class TypeNode extends Node implements ExpressionNode {
  final TypeKind kind;

  const TypeNode._({
    required this.kind,
    required super.context,
  });

  const TypeNode.any({
    required super.context,
  }) : kind = TypeKind.any;

  const TypeNode.none({
    required super.context,
  }) : kind = TypeKind.none;

  const TypeNode.string({
    required super.context,
  }) : kind = TypeKind.string;

  const TypeNode.number({
    required super.context,
  }) : kind = TypeKind.number;

  const TypeNode.boolean({
    required super.context,
  }) : kind = TypeKind.boolean;

  const TypeNode.scope({
    required super.context,
  }) : kind = TypeKind.scope;

  const TypeNode.type({
    required super.context,
  }) : kind = TypeKind.type;

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitType(this);
}

class ComplexTypeNode extends TypeNode {
  final TypeListNode? types;

  const ComplexTypeNode._({
    required this.types,
    required super.context,
    required super.kind,
  }) : super._();

  const ComplexTypeNode.list({
    required this.types,
    required super.context,
  }) : super._(kind: TypeKind.list);

  const ComplexTypeNode.dict({
    required this.types,
    required super.context,
  }) : super._(kind: TypeKind.dict);

  const ComplexTypeNode.tuple({
    required this.types,
    required super.context,
  }) : super._(kind: TypeKind.tuple);
}

class FunctionTypeNode extends ComplexTypeNode {
  final TypeNode returnType;

  const FunctionTypeNode({
    required this.returnType,
    required super.types,
    required super.context,
  }) : super._(kind: TypeKind.function);

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitFunctionType(this);
}

class TypeListNode extends Node {
  final List<TypeNode> types;

  const TypeListNode({required this.types, required super.context});

  @override
  T? accept<T>(Visitor<T> visitor) => visitor.visitTypeList(this);
}

enum TypeKind {
  any,
  none,
  string,
  number('num'),
  boolean('bool'),
  list,
  dict,
  tuple,
  scope,
  function('fun'),
  type;

  final String? _printableName;

  const TypeKind([this._printableName]);

  String get printableName => _printableName ?? name;
}
