import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/value.dart';

abstract class Storage<T extends Value> {
  final Type? explicitType;
  final T data;
  final bool exported;

  const Storage(
    this.data, {
    this.explicitType,
    this.exported = false,
  });

  Type get storedType => explicitType ?? data.type;
}

class VariableDefinition extends Storage {
  const VariableDefinition(
    super.data, {
    super.explicitType,
    super.exported = false,
  });

  @override
  String toString() => data.toString();
}

class FunctionDefinition extends Storage<Statements> {
  final Map<String, Type> arguments;
  final Scope? parentScope;

  const FunctionDefinition(
    super.data, {
    super.explicitType,
    this.arguments = const {},
    super.exported = false,
    this.parentScope,
  });

  Value? invoke(List<Value> arguments) => null;

  @override
  FunctionType get storedType => FunctionType(
        explicitType ?? const Type(TypeKind.any),
        arguments.values.toList(),
      );

  @override
  String toString() {
    return 'fun(${arguments.entries.map((e) => "${e.key}: ${e.value}").join(", ")}): ${storedType.returnType}';
  }
}

class ImportedLibrary extends Storage<Scope> {
  const ImportedLibrary(super.data);

  @override
  Type? get explicitType => null;

  @override
  String toString() => data.toString();
}
