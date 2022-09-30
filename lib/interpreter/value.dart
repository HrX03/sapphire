// ignore_for_file: avoid_positional_boolean_parameters

import 'package:collection/collection.dart';
import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/storage.dart';

typedef ScopeNative = Map<String, Storage>;

abstract class Value<T> {
  final T data;

  const Value(this.data);

  Type get type;

  @override
  int get hashCode => Object.hash(data, type);

  @override
  bool operator ==(Object? other) {
    if (other is Value) {
      return data == other.data && type == other.type;
    }

    return false;
  }
}

class Scope extends Value<ScopeNative> {
  final Scope? parentScope;
  final Scope? secondaryScope;

  Scope(
    super.data, {
    this.parentScope,
    this.secondaryScope,
  });

  bool hasStorage(String key, {bool checkParent = true}) {
    final bool thisHasStorage = data.containsKey(key);

    if (!thisHasStorage && parentScope != null && checkParent) {
      return parentScope!.hasStorage(key);
    }

    return thisHasStorage;
  }

  bool set(String key, Storage value, {bool update = false}) {
    if (!data.containsKey(key) && update) {
      return parentScope?.set(key, value, update: update) ?? false;
    }

    if (data.containsKey(key) && !update) return false;

    data[key] = value;
    return true;
  }

  bool delete(String key) {
    return data.remove(key) != null;
  }

  Storage? get(String key) {
    return data[key] ?? secondaryScope?.get(key) ?? parentScope?.get(key);
  }

  @override
  Type get type => const Type(TypeKind.scope);

  @override
  String toString() {
    return "{${data.entries.map((e) => "'${e.key}' = ${e.value}").join(", ")}}";
  }
}

class Number extends Value<num> {
  const Number(super.data);

  @override
  Type get type => const Type(TypeKind.number);

  @override
  String toString() => data.toString();
}

class Str extends Value<String> {
  const Str(super.data);

  @override
  Type get type => const Type(TypeKind.string);

  @override
  String toString() => data;
}

class Boolean extends Value<bool> {
  const Boolean(super.data);

  @override
  Type get type => const Type(TypeKind.boolean);

  @override
  String toString() => data.toString();
}

class None extends Value<void> {
  const None() : super(null);

  @override
  Type get type => const Type(TypeKind.none);

  @override
  String toString() => 'none';
}

class FunctionRef extends Value<Statements> {
  final Type returnType;
  final Map<String, Type> parameters;
  final Map<String, Type> typeParameters;
  final Scope parentScope;

  const FunctionRef(
    super.data, {
    this.returnType = const Type(TypeKind.any),
    this.parameters = const {},
    this.typeParameters = const {},
    required this.parentScope,
  });

  @override
  FunctionType get type => FunctionType(returnType, parameters.values.toList());

  @override
  String toString() {
    return 'fun(${parameters.entries.map((e) => "${e.key}: ${e.value}").join(", ")}): $returnType';
  }
}

abstract class ComplexValue<T> extends Value<T> {
  final List<Type> types;

  const ComplexValue(super.data, this.types);

  TypeKind get baseType;

  @override
  Type get type => ComplexType(baseType, types);
}

class Dict extends ComplexValue<Map<Value, Value>> {
  const Dict(super.data, super.types);

  @override
  TypeKind get baseType => TypeKind.dict;
}

class ListVal extends ComplexValue<List<Value>> {
  const ListVal(super.data, super.types);

  @override
  TypeKind get baseType => TypeKind.list;

  @override
  String toString() => '[${data.join(", ")}]';
}

class Tuple extends ComplexValue<List<Value>> {
  const Tuple(super.data, super.types);

  @override
  TypeKind get baseType => TypeKind.tuple;

  @override
  String toString() => '(${data.join(", ")})';
}

class Type extends Value<TypeKind> {
  const Type(super.data);

  @override
  Type get type => const Type(TypeKind.type);

  @override
  String toString() {
    return data.printableName;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object? other) {
    if (other is Type) {
      return data == other.data;
    }

    return false;
  }
}

class TypeReference extends Type {
  final String name;

  const TypeReference(this.name) : super(TypeKind.type);

  @override
  String toString() => name;
}

class ComplexType extends Type {
  final List<Type>? extraTypes;

  const ComplexType(super.data, [this.extraTypes]);

  @override
  String toString() {
    final StringBuffer result = StringBuffer(data.name);

    if (extraTypes != null) {
      result.write("<");
      final List<String> extraTypesStr = [];

      for (final Type type in extraTypes!) {
        extraTypesStr.add(type.toString());
      }

      if (extraTypesStr.isEmpty) {
        extraTypesStr.add("any");
      }

      result.write(extraTypesStr.join(", "));

      result.write(">");
    }

    return result.toString();
  }

  @override
  int get hashCode => Object.hash(data, type, extraTypes);

  @override
  bool operator ==(Object? other) {
    if (other is ComplexType) {
      return data == other.data &&
          type == other.type &&
          const ListEquality().equals(extraTypes, other.extraTypes);
    }

    return false;
  }
}

class FunctionType extends ComplexType {
  final Type returnType;

  const FunctionType(this.returnType, List<Type>? extraTypes)
      : super(TypeKind.function, extraTypes);

  @override
  String toString() {
    final StringBuffer result = StringBuffer(data.printableName);

    if (returnType.data != TypeKind.any) {
      result.write(":$returnType");
    }

    if (extraTypes != null) {
      result.write("<");
      final List<String> extraTypesStr = [];

      for (final Type type in extraTypes!) {
        extraTypesStr.add(type.toString());
      }

      if (extraTypesStr.isEmpty) {
        extraTypesStr.add("any");
      }

      result.write(extraTypesStr.join(", "));

      result.write(">");
    }

    return result.toString();
  }

  @override
  int get hashCode => Object.hash(data, type, returnType, extraTypes);

  @override
  bool operator ==(Object? other) {
    if (other is FunctionType) {
      return data == other.data &&
          type == other.type &&
          returnType == other.returnType &&
          const ListEquality().equals(extraTypes, other.extraTypes);
    }

    return false;
  }
}

class Statements extends Value<List<StatementNode>?> {
  const Statements(super.data);

  @override
  Type get type => const Type(TypeKind.none);
}

class SingleStatement extends Statements {
  SingleStatement(StatementNode statement) : super([statement]);

  const SingleStatement.empty() : super(null);

  @override
  Type get type => const Type(TypeKind.none);
}
