import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/value.dart';

void signatureCheck(List<Type> signature, List<Value> arguments) {
  if (signature.length != arguments.length) {
    throw Exception(
      "Argument number mismatch, expected ${signature.length}, found ${arguments.length}",
    );
  }

  for (int i = 0; i < signature.length; i++) {
    final Type type = signature[i];
    final Value argument = arguments[i];

    if (!strongTypeCheck(type, argument)) {
      throw Exception(
        "Type mismatch for argument n${i + 1}, expected $type found ${argument.type}",
      );
    }
  }
}

void typeSignatureCheck(List<Type> signature, List<Type> arguments) {
  if (arguments.length > signature.length) {
    throw Exception(
      "Type arguments number exceeded max expected amount of ${signature.length}, found ${arguments.length}",
    );
  }

  for (int i = 0; i < signature.length; i++) {
    final Type type = signature[i];
    final Type? argument = arguments.get(i);

    if (argument == null) return;

    if (!typeOnlyCheck(type, argument)) {
      throw Exception(
        "Type argument $argument is not compatible with type $type",
      );
    }
  }
}

bool weakTypeCheck(Type destination, Type request) {
  // any is always allowed, both in destination and request
  // def a: any = 0 < allowed
  // def b: string = a < allowed, but will fail with a tighter type check
  if (destination.data == TypeKind.any || request.data == TypeKind.any) {
    return true;
  }

  // none can always be assigned to any type (for now)
  if (request.data == TypeKind.none) {
    return true;
  }

  if (destination.data == TypeKind.none) {
    return request.data == TypeKind.none;
  }

  return destination.data == request.data;
}

bool strongTypeCheck(Type destination, Value request) {
  // None is always allowed in any destination
  if (request.type.data == TypeKind.none) return true;

  // assigning anything to any is always allowed
  if (destination.data == TypeKind.any) return true;

  if (destination is ComplexType) {
    if (request.type is! ComplexType) return false;

    switch (destination.data) {
      case TypeKind.list:
        if (request is! ListVal) return false;

        if (destination.extraTypes == null || destination.extraTypes!.isEmpty) {
          // list<any> or list always allows another list
          return true;
        }

        // empty lists are always allowed on any list type
        if (request.data.isEmpty) return true;

        final Type destinationListType =
            destination.extraTypes?.get(0) ?? const Type(TypeKind.any);
        final Type listType =
            evaluateListType(request.data, destinationListType);
        if (!typeOnlyCheck(destinationListType, listType)) return false;

        break;
      case TypeKind.tuple:
        if (request is! Tuple) return false;

        // a tuple with no type parameters should not be allowed but we can never
        // be too sure
        if (destination.extraTypes == null) return false;

        if (destination.extraTypes!.length != request.types.length) {
          return false;
        }

        for (int i = 0; i < destination.extraTypes!.length; i++) {
          if (!typeOnlyCheck(destination.extraTypes![i], request.types[i])) {
            return false;
          }
        }

        break;
      case TypeKind.dict:
        if (request is! Dict) return false;

        if (destination.extraTypes == null || destination.extraTypes!.isEmpty) {
          // dict always allows another list
          return true;
        }

        // empty dicts are always allowed on any list type
        if (request.data.isEmpty) return true;

        final Type destinationKeysType =
            destination.extraTypes?.get(0) ?? const Type(TypeKind.any);
        final Type keysType =
            evaluateListType(request.data.keys, destinationKeysType);
        if (!typeOnlyCheck(destinationKeysType, keysType)) return false;

        final Type destinationValuesType =
            destination.extraTypes?.get(1) ?? const Type(TypeKind.any);
        final Type valuesType =
            evaluateListType(request.data.values, destinationValuesType);
        if (!typeOnlyCheck(destinationValuesType, valuesType)) return false;

        break;
      case TypeKind.function:
        if (destination is! FunctionType) return false;
        if (request is! FunctionRef) return false;

        if (!typeOnlyCheck(destination.returnType, request.returnType)) {
          return false;
        }

        if (destination.extraTypes == null || destination.extraTypes!.isEmpty) {
          // fun:* always allows a function with any argument
          return true;
        }

        for (int i = 0; i < destination.extraTypes!.length; i++) {
          if (!typeOnlyCheck(
            destination.extraTypes![i],
            request.parameters.values.toList()[i],
            allowAnyForReference: true,
          )) {
            return false;
          }
        }

        break;
      default:
        throw Exception("Invalid complex type ${destination.data}");
    }
  }

  return destination.data == request.type.data;
}

Type evaluateListType(
  Iterable<Value> values, [
  Type requestedType = const Type(TypeKind.any),
]) {
  final Type refType = values.isNotEmpty ? values.first.type : requestedType;

  if (values.isNotEmpty) {
    for (final Value val in values) {
      if (!strongTypeCheck(refType, val)) {
        return const Type(TypeKind.any);
      }
    }
  }

  return refType;
}

bool typeOnlyCheck(
  Type reference,
  Type destination, {
  bool allowAnyForReference = false,
}) {
  if (reference.data == TypeKind.any ||
      (destination.data == TypeKind.any && allowAnyForReference)) {
    return true;
  }

  if (destination.data == TypeKind.none) return true;

  if (reference.data == TypeKind.none) return destination.data == TypeKind.none;

  if (reference.data != destination.data) return false;

  if (reference is ComplexType) {
    if (destination is! ComplexType) return false;

    if (reference.extraTypes == null) return true;
    if (destination.extraTypes == null) return false;

    if (reference.extraTypes!.length != destination.extraTypes!.length) {
      return false;
    }

    for (int i = 0; i < reference.extraTypes!.length; i++) {
      final Type referenceType = reference.extraTypes![i];
      final Type requestType = destination.extraTypes![i];

      if (!typeOnlyCheck(referenceType, requestType)) return false;
    }

    if (reference is FunctionType) {
      if (destination is! FunctionType) return false;

      if (!typeOnlyCheck(reference.returnType, destination.returnType)) {
        return false;
      }
    }
  }

  return true;
}

bool isInteger(num value) => value is int || value == value.roundToDouble();
int wrapInt(int value, int lower, int upper) {
  return (value - lower) % (upper - lower + 1) + lower;
}

extension GetNullable<T> on List<T> {
  T? get(int index) {
    try {
      return this[index];
    } catch (e) {
      return null;
    }
  }
}
