import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/interpreter/interpreter.dart';
import 'package:sapphire/interpreter/storage.dart';
import 'package:sapphire/interpreter/utils.dart';
import 'package:sapphire/interpreter/value.dart';

typedef NativeMethodCallback<T extends Value> = T Function(
  SapphireInterpreter interpreter,
  List<Value> arguments,
);
typedef NativeMethodRegistry = Map<String, NativeMethod>;

class NativeMethodProvider extends FunctionDefinition {
  final SapphireInterpreter interpreter;
  final Map<String, NativeMethodRegistry> registries;

  const NativeMethodProvider({
    required this.interpreter,
    required this.registries,
  }) : super(
          const SingleStatement.empty(),
          explicitType: const Type(TypeKind.any),
          arguments: const {
            'name': Type(TypeKind.string),
            'values': ComplexType(TypeKind.list),
          },
        );

  @override
  Value invoke(List<Value> arguments) {
    if (arguments.length != 2) {
      throw Exception(
        "Method 'native' requires two arguments of type string and list",
      );
    }

    final Value nameArg = arguments.first;
    if (nameArg.type.data != TypeKind.string) {
      throw Exception(
        "Argument 'name' needs to be of type string",
      );
    }

    final Value valuesArg = arguments.last;
    if (valuesArg.type.data != TypeKind.list) {
      throw Exception(
        "Argument 'values' needs to be of type list",
      );
    }

    final Str name = nameArg as Str;
    final ListVal values = valuesArg as ListVal;

    final List<String> parts = name.data.split(":");

    if (parts.length != 2) {
      throw Exception("Invalid name syntax, must be <registry>:<method>");
    }

    final String registryName = parts[0];
    final String methodName = parts[1];

    final NativeMethodRegistry? registry = registries[registryName];

    if (registry == null) {
      throw Exception("Registry '$registry' was not found");
    }

    if (!registry.containsKey(methodName)) {
      throw Exception("Method '$methodName' not found");
    }

    return registry[methodName]!(interpreter, values.data);
  }
}

class NativeMethod<T extends Value> {
  final List<Type> argumentSignature;
  final NativeMethodCallback<T> callback;

  const NativeMethod({
    required this.argumentSignature,
    required this.callback,
  });

  Value call(SapphireInterpreter interpreter, List<Value> arguments) {
    signatureCheck(
      argumentSignature,
      arguments,
    );

    return callback(interpreter, arguments);
  }
}
