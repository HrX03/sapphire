import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/interpreter.dart';
import 'package:sapphire/interpreter/native/native.dart';
import 'package:sapphire/interpreter/storage.dart';
import 'package:sapphire/interpreter/utils.dart';
import 'package:sapphire/interpreter/value.dart';

const NativeMethodRegistry sdkRegistry = {
  'print': NativeMethod<None>(
    argumentSignature: [
      Type(TypeKind.any),
    ],
    callback: _printNative,
  ),
  'arithmetic_op': NativeMethod<Number>(
    argumentSignature: [
      Type(TypeKind.string),
      Type(TypeKind.number),
      Type(TypeKind.number),
    ],
    callback: _arithmeticOpNative,
  ),
  'concat': NativeMethod<Str>(
    argumentSignature: [
      ComplexType(TypeKind.list, [Type(TypeKind.string)]),
    ],
    callback: _concatNative,
  ),
  'reflect': NativeMethod<Value>(
    argumentSignature: [
      Type(TypeKind.scope),
      Type(TypeKind.string),
    ],
    callback: _reflectNative,
  ),
  'equals': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.any),
      Type(TypeKind.any),
    ],
    callback: _equalsNative,
  ),
  'is_int': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.number),
    ],
    callback: _isIntNative,
  ),
  'relational_test': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.string),
      Type(TypeKind.number),
      Type(TypeKind.number),
    ],
    callback: _relationalNumTestNative,
  ),
  'boolean_check': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.string),
      ComplexType(TypeKind.list, [Type(TypeKind.boolean)]),
    ],
    callback: _booleanCheckNative,
  ),
  'not': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.boolean),
    ],
    callback: _notNative,
  ),
  'type_of': NativeMethod<Type>(
    argumentSignature: [
      Type(TypeKind.any),
    ],
    callback: _typeOfNative,
  ),
  'type_match': NativeMethod<Boolean>(
    argumentSignature: [
      Type(TypeKind.any),
      Type(TypeKind.type),
    ],
    callback: _typeMatchNative,
  ),
  'call': NativeMethod<Value>(
    argumentSignature: [
      Type(TypeKind.function),
      ComplexType(TypeKind.list, [Type(TypeKind.any)]),
    ],
    callback: _callNative,
  ),
};

None _printNative(SapphireInterpreter interpreter, List<Value> arguments) {
  // ignore: avoid_print
  print(arguments.single);

  return const None();
}

Number _arithmeticOpNative(
  SapphireInterpreter interpreter,
  List<Value> arguments,
) {
  final Str opType = arguments[0] as Str;
  final Number firstValue = arguments[1] as Number;
  final Number secondValue = arguments[2] as Number;

  final num result;

  switch (opType.data) {
    case 'sum':
      result = firstValue.data + secondValue.data;
      break;
    case 'sub':
      result = firstValue.data - secondValue.data;
      break;
    case 'mul':
      result = firstValue.data * secondValue.data;
      break;
    case 'div':
      result = firstValue.data / secondValue.data;
      break;
    case 'mod':
      result = firstValue.data % secondValue.data;
      break;
    case 'intdiv':
      result = firstValue.data ~/ secondValue.data;
      break;
    default:
      throw Exception("Invalid arithmetic operation type ${opType.data}");
  }

  return Number(result);
}

Str _concatNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final ListVal values = arguments.first as ListVal;
  final List<Str> strings = values.data.cast<Str>();

  final StringBuffer result = StringBuffer();

  for (final Str val in strings) {
    result.write(val.data);
  }

  return Str(result.toString());
}

Value _reflectNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Scope scope = arguments.first as Scope;
  final Str name = arguments.last as Str;

  final Storage? storage = scope.get(name.data);
  if (storage == null) return const None();

  if (storage is FunctionDefinition) {
    return FunctionRef(
      storage.data,
      arguments: storage.arguments,
      returnType: storage.storedType.returnType,
      parentScope: scope,
    );
  }

  return storage.data;
}

Boolean _equalsNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Value firstVal = arguments.first;
  final Value secondVal = arguments.last;

  if (!typeCheck(firstVal.type, secondVal.type)) return const Boolean(false);

  return Boolean(firstVal.data == secondVal.data);
}

Boolean _isIntNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Number value = arguments.single as Number;

  return Boolean(isInteger(value.data));
}

Boolean _relationalNumTestNative(
  SapphireInterpreter interpreter,
  List<Value> arguments,
) {
  final Str testType = arguments[0] as Str;
  final Number firstVal = arguments[1] as Number;
  final Number secondVal = arguments[2] as Number;

  switch (testType.data) {
    case 'lss':
      return Boolean(firstVal.data < secondVal.data);
    case 'grt':
      return Boolean(firstVal.data > secondVal.data);
    case 'lsseq':
      return Boolean(firstVal.data <= secondVal.data);
    case 'grteq':
      return Boolean(firstVal.data >= secondVal.data);
  }

  throw Exception("Invalid test type ${testType.data}");
}

Boolean _booleanCheckNative(
  SapphireInterpreter interpreter,
  List<Value> arguments,
) {
  final Str checkType = arguments[0] as Str;
  // final Boolean firstVal = arguments[1] as Boolean;
  // final Boolean secondVal = arguments[2] as Boolean;
  final ListVal values = arguments[1] as ListVal;
  final List<Boolean> booleans = values.data.cast<Boolean>();

  bool result = booleans.removeAt(0).data;
  switch (checkType.data) {
    case 'and':
      for (final Boolean val in booleans) {
        result = result && val.data;
      }
      break;
    case 'or':
      for (final Boolean val in booleans) {
        result = result || val.data;
      }
      break;
    case 'xor':
      for (final Boolean val in booleans) {
        result = result ^ val.data;
      }
      break;
    default:
      throw Exception("Invalid check type ${checkType.data}");
  }

  return Boolean(result);
}

Boolean _notNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Boolean value = arguments.single as Boolean;

  return Boolean(!value.data);
}

Type _typeOfNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Value value = arguments.single;

  return value.type;
}

Boolean _typeMatchNative(
  SapphireInterpreter interpreter,
  List<Value> arguments,
) {
  final Value firstValue = arguments.first;
  final Type secondValue = arguments.last as Type;

  return Boolean(typeCheck(secondValue, firstValue.type));
}

Value _callNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final FunctionRef function = arguments.first as FunctionRef;
  final ListVal listVal = arguments.last as ListVal;
  final List<Value> providedArguments = listVal.data;

  return interpreter.callFunction(
    FunctionDefinition(
      function.data,
      arguments: function.arguments,
      explicitType: function.returnType,
      parentScope: function.parentScope,
    ),
    providedArguments,
  );
}
