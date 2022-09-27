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

    if (!typeCheck(type, argument.type)) {
      throw Exception(
        "Type mismatch for argument n${i + 1}, expected $type found ${argument.type}",
      );
    }
  }
}

bool typeCheck(Type reference, Type request) {
  if (reference.data == TypeKind.any) return true;

  if (request.data == TypeKind.none) return true;

  if (reference.data == TypeKind.none) return request.data == TypeKind.none;

  if (reference.data != request.data) return false;

  if (reference is ComplexType) {
    if (request is! ComplexType) return false;

    if (reference.extraTypes == null) return true;
    if (request.extraTypes == null) return false;

    if (reference.extraTypes!.length != request.extraTypes!.length) {
      return false;
    }

    for (int i = 0; i < reference.extraTypes!.length; i++) {
      final Type referenceType = reference.extraTypes![i];
      final Type requestType = request.extraTypes![i];

      if (!typeCheck(referenceType, requestType)) return false;
    }

    if (reference is FunctionType) {
      if (request is! FunctionType) return false;

      if (!typeCheck(reference.returnType, request.returnType)) return false;
    }
  }

  return true;
}

bool isInteger(num value) => value is int || value == value.roundToDouble();
int wrapInt(int value, int lower, int upper) {
  return (value - lower) % (upper - lower + 1) + lower;
}

Type getListType(List<Value> values) {
  Type refType =
      values.isNotEmpty ? values.first.type : const Type(TypeKind.any);

  if (values.isNotEmpty) {
    for (final Value val in values) {
      if (!typeCheck(refType, val.type)) {
        refType = const Type(TypeKind.any);
      }
    }
  }

  return refType;
}
