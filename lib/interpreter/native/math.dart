import 'dart:math' as math;
import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/interpreter.dart';
import 'package:sapphire/interpreter/native/native.dart';
import 'package:sapphire/interpreter/value.dart';

const NativeMethodRegistry mathRegistry = {
  'min': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number), Type(TypeKind.number)],
    callback: _minNative,
  ),
  'max': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number), Type(TypeKind.number)],
    callback: _maxNative,
  ),
  'atan2': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number), Type(TypeKind.number)],
    callback: _atan2Native,
  ),
  'pow': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number), Type(TypeKind.number)],
    callback: _powNative,
  ),
  'sin': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _sinNative,
  ),
  'cos': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _cosNative,
  ),
  'tan': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _tanNative,
  ),
  'asin': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _asinNative,
  ),
  'acos': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _acosNative,
  ),
  'atan': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _atanNative,
  ),
  'sqrt': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _sqrtNative,
  ),
  'exp': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _expNative,
  ),
  'log': NativeMethod<Number>(
    argumentSignature: [Type(TypeKind.number)],
    callback: _logNative,
  ),
};

Number _minNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number firstValue = values.first as Number;
  final Number secondValue = values.last as Number;

  return Number(math.min(firstValue.data, secondValue.data));
}

Number _maxNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number firstValue = values.first as Number;
  final Number secondValue = values.last as Number;

  return Number(math.max(firstValue.data, secondValue.data));
}

Number _atan2Native(SapphireInterpreter interpreter, List<Value> values) {
  final Number firstValue = values.first as Number;
  final Number secondValue = values.last as Number;

  return Number(math.atan2(firstValue.data, secondValue.data));
}

Number _powNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number firstValue = values.first as Number;
  final Number secondValue = values.last as Number;

  return Number(math.pow(firstValue.data, secondValue.data));
}

Number _sinNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.sin(value.data));
}

Number _cosNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.cos(value.data));
}

Number _tanNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.tan(value.data));
}

Number _asinNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.asin(value.data));
}

Number _acosNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.acos(value.data));
}

Number _atanNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.atan(value.data));
}

Number _sqrtNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.sqrt(value.data));
}

Number _expNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.exp(value.data));
}

Number _logNative(SapphireInterpreter interpreter, List<Value> values) {
  final Number value = values.single as Number;

  return Number(math.log(value.data));
}
