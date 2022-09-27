import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/interpreter.dart';
import 'package:sapphire/interpreter/native/native.dart';
import 'package:sapphire/interpreter/utils.dart';
import 'package:sapphire/interpreter/value.dart';

const NativeMethodRegistry collectionRegistry = {
  'get': NativeMethod<Value>(
    argumentSignature: [
      ComplexType(TypeKind.any),
      Type(TypeKind.any),
    ],
    callback: _getNative,
  ),
  'lengthof': NativeMethod<Value>(
    argumentSignature: [
      ComplexType(TypeKind.any),
    ],
    callback: _lengthofNative,
  ),
};

Value _getNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Value collection = arguments[0];
  final Value key = arguments[1];

  switch (collection.type.data) {
    case TypeKind.list:
      _validateListTupleIndex(key);
      final ListVal list = collection as ListVal;

      return _accessList(list.data, key.data as int);
    case TypeKind.tuple:
      _validateListTupleIndex(key);
      final Tuple tuple = collection as Tuple;

      return _accessList(tuple.data, key.data as int);
    case TypeKind.dict:
      final Dict dict = collection as Dict;

      if (!typeCheck(dict.types.first, key.type)) {
        throw Exception(
          "Can't use key of type ${key.type} to access dict with key type ${dict.types.first}",
        );
      }

      return dict.data[key] ?? const None();
    default:
      break;
  }

  throw Exception("Object $collection isn't of type list, dict or tuple");
}

Number _lengthofNative(SapphireInterpreter interpreter, List<Value> arguments) {
  final Value collection = arguments.single;

  switch (collection.type.data) {
    case TypeKind.list:
      final ListVal list = collection as ListVal;

      return Number(list.data.length);
    case TypeKind.tuple:
      final Tuple tuple = collection as Tuple;

      return Number(tuple.data.length);
    case TypeKind.dict:
      final Dict dict = collection as Dict;

      return Number(dict.data.length);
    default:
      break;
  }

  throw Exception("Object $collection isn't of type list, dict or tuple");
}

Value _accessList(List<Value> list, int index) {
  final bool withinBounds =
      index.isNegative ? index.abs() <= list.length : list.length > index;

  if (!withinBounds) {
    throw Exception(
      "Accessing collection out of bounds, tried index $index on list with length ${list.length}",
    );
  }

  final int wrappedIndex = wrapInt(index, 0, list.length);
  return list[index.isNegative ? wrappedIndex - 1 : wrappedIndex];
}

void _validateListTupleIndex(Value value) {
  if (!typeCheck(const Type(TypeKind.number), value.type)) {
    throw Exception(
      "When accessing lists only number keys are allowed to access elements",
    );
  }

  if (!isInteger(value.data as num)) {
    throw Exception("List and tuple indexes must be integers");
  }
}
