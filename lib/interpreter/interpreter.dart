import 'dart:io';

import 'package:antlr4/antlr4.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:sapphire/antlr/SapphireLexer.dart';
import 'package:sapphire/antlr/SapphireParser.dart';
import 'package:sapphire/ast/ast.dart';
import 'package:sapphire/ast/builder.dart';
import 'package:sapphire/ast/visitor.dart';
import 'package:sapphire/interpreter/native/collection.dart';
import 'package:sapphire/interpreter/native/math.dart';
import 'package:sapphire/interpreter/native/native.dart';
import 'package:sapphire/interpreter/native/sdk.dart';
import 'package:sapphire/interpreter/storage.dart';
import 'package:sapphire/interpreter/utils.dart';
import 'package:sapphire/interpreter/value.dart';

class SapphireInterpreter extends SimpleVisitor {
  final Directory? directory;

  SapphireInterpreter(this.directory);

  late final Scope _rootScope = Scope({
    'native': NativeMethodProvider(
      interpreter: this,
      registries: {
        'sdk': sdkRegistry,
        'math': mathRegistry,
        'collection': collectionRegistry,
      },
    ),
  });
  late Scope _scope = _rootScope;

  static Future<SapphireInterpreter> interpretFile(File file) async {
    final InputStream input =
        await InputStream.fromPath(p.normalize(file.absolute.path));
    final SapphireLexer lexer = SapphireLexer(input);
    final CommonTokenStream tokens = CommonTokenStream(lexer);
    final SapphireParser parser = SapphireParser(tokens);

    final FileContext tree = parser.file();
    final FileNode fileNode = SapphireASTVisitor().visitFile(tree);
    final SapphireInterpreter interpreter =
        SapphireInterpreter(Directory(p.dirname(file.absolute.path)));
    await interpreter.visitFile(fileNode);

    return interpreter;
  }

  @override
  Future<void> visitFile(FileNode node) async {
    for (final HeaderNode node in node.headers) {
      await visitHeader(node);
    }

    for (final StatementNode node in node.statements) {
      final Value? value = visitStatement(node);

      if (value != null) return;
    }
  }

  @override
  Future<void> visitHeader(HeaderNode node) async {
    if (node is ImportHeaderNode) {
      await visitImportHeader(node);
    }
  }

  @override
  Future<void> visitImportHeader(ImportHeaderNode node) async {
    if (node.library.startsWith("./") && directory != null) {
      final String path = p.join(directory!.path, node.library);
      final SapphireInterpreter import =
          await SapphireInterpreter.interpretFile(File(path));

      final ScopeNative importedScope = Map.from(import._rootScope.data);
      importedScope.removeWhere((key, value) => !value.exported);

      if (node.alias != null) {
        _scope.set(node.alias!, ImportedLibrary(Scope(importedScope)));
      } else {
        for (final MapEntry<String, Storage> entry in importedScope.entries) {
          _scope.set(entry.key, entry.value);
        }
      }
    }
  }

  @override
  Value? visitStatement(StatementNode node) {
    if (node is DefineStatementNode) {
      visitDefineStatement(node);
    }

    if (node is UndefineStatementNode) {
      visitUndefineStatement(node);
    }

    if (node is AssignStatementNode) {
      visitAssignStatement(node);
    }

    if (node is IdentifierNode) {
      visitIdentifier(node);
    }

    if (node is ReturnStatementNode) {
      return visitReturnStatement(node);
    }

    if (node is ConditionalStatementNode) {
      return visitConditionalStatement(node);
    }

    if (node is WhileStatementNode) {
      return visitWhileStatement(node);
    }

    return null;
  }

  @override
  void visitDefineStatement(DefineStatementNode node) {
    if (node.arguments != null) {
      final ExpressionNode value = node.assignedValue;
      final Type type = visitType(node.type);

      final Map<String, Type> arguments = Map.fromEntries(
        node.arguments!.map((e) => MapEntry(e.id, visitType(e.type))),
      );

      _scope.set(
        node.identifier,
        FunctionDefinition(
          value is ScopeNode
              ? Statements(value.statements)
              : SingleStatement(
                  ReturnStatementNode(
                    value: value,
                    context: value.context,
                  ),
                ),
          explicitType: type,
          arguments: arguments,
          exported: node.exported,
          parentScope: _scope,
        ),
      );
    } else {
      Value value = visitExpression(node.assignedValue);
      final Type type = visitType(node.type);

      if (value is Statements) {
        value = _evaluateStatements(value) ?? const None();
      }

      if (!typeCheck(type, value.type)) {
        throw Exception(
          "Can't assign a value of type ${value.type} to a variable of type $type",
        );
      }

      _scope.set(
        node.identifier,
        VariableDefinition(value, explicitType: type, exported: node.exported),
      );
    }
  }

  @override
  void visitAssignStatement(AssignStatementNode node) {
    final Value value = visitExpression(node.value);
    final Storage? current = _scope.get(node.id);

    if (current == null) {
      throw Exception(
        "The variable ${node.id} was not defined, can't assign",
      );
    }

    if (!typeCheck(current.storedType, value.type)) {
      throw Exception(
        "Can't assign a value of type ${value.type} to a variable of type ${current.storedType}",
      );
    }

    _scope.set(
      node.id,
      VariableDefinition(
        value,
        explicitType: current.storedType,
      ),
      update: true,
    );
  }

  @override
  void visitUndefineStatement(UndefineStatementNode node) {
    if (!_scope.hasStorage(node.id)) {
      throw Exception(
        "The variable ${node.id} does not exist in the current scope",
      );
    }

    _scope.delete(node.id);
  }

  @override
  Value visitReturnStatement(ReturnStatementNode node) {
    return node.value != null ? visitExpression(node.value!) : const None();
  }

  @override
  Value? visitConditionalStatement(ConditionalStatementNode node) {
    for (final MapEntry<ExpressionNode, ScopeNode> blocks
        in node.conditions.entries) {
      final Value evaluatedCondition = visitExpression(blocks.key);

      if (evaluatedCondition.type.data != TypeKind.boolean) {
        throw Exception(
          "Invalid type for condition: ${evaluatedCondition.type}",
        );
      }

      final Boolean boolean = evaluatedCondition as Boolean;

      if (boolean.data) {
        return _evaluateStatements(Statements(blocks.value.statements));
      }
    }

    if (node.elseScope != null) {
      return _evaluateStatements(Statements(node.elseScope!.statements));
    }

    return null;
  }

  @override
  Value? visitWhileStatement(WhileStatementNode node) {
    while (true) {
      final Value expression = visitExpression(node.condition);

      if (!typeCheck(const Type(TypeKind.boolean), expression.type)) {
        throw Exception("While conditions must be of type bool");
      }

      final Boolean condition = expression as Boolean;
      if (!condition.data) break;

      final Value? returnVal = _evaluateStatements(Statements(node.statements));

      if (returnVal != null) return returnVal;
    }

    return null;
  }

  @override
  Value visitExpression(ExpressionNode node) {
    if (node is IdentifierNode) {
      return visitIdentifier(node);
    }

    if (node is ScopeNode) {
      return Statements(node.statements);
    }

    if (node is StringNode) {
      return Str(node.contents);
    }

    if (node is NumberNode) {
      return Number(node.value);
    }

    if (node is BooleanNode) {
      return Boolean(node.value);
    }

    if (node is TupleNode) {
      return visitTuple(node);
    }

    if (node is ListNode) {
      return visitList(node);
    }

    if (node is DictNode) {
      return visitDict(node);
    }

    if (node is TypeNode) {
      return visitType(node);
    }

    if (node is RootNode) {
      return _rootScope;
    }

    if (node is ThisNode) {
      return _scope;
    }

    if (node is NoneNode) {
      return const None();
    }

    throw Exception("Should never happen but you can never be too sure");
  }

  @override
  Value visitIdentifier(IdentifierNode node) {
    final Scope refScope;

    if (node.libraryId != null) {
      final Storage? importedScope = _scope.get(node.libraryId!);
      if (importedScope == null || importedScope is! ImportedLibrary) {
        throw Exception(
          "Aliased library ${node.libraryId} was not found. Did you forget an import or an alias?",
        );
      }

      refScope = importedScope.data;
    } else {
      refScope = _scope;
    }

    final Storage? storage = refScope.get(node.identifier);
    if (storage == null) {
      throw Exception("Variable ${node.identifier} not found");
    }

    if (storage is FunctionDefinition) {
      // We aren't calling this function, just return the reference
      if (node.arguments == null) {
        return FunctionRef(
          storage.data,
          arguments: storage.arguments,
          returnType: storage.storedType.returnType,
          parentScope: _scope,
        );
      }

      return callFunction(
        storage,
        node.arguments!.map((e) => visitExpression(e)).toList(),
      );
    }

    final Value data = storage.data;

    if (data is FunctionRef) {
      if (node.arguments == null) return data;

      return callFunction(
        FunctionDefinition(
          data.data,
          arguments: data.arguments,
          explicitType: data.returnType,
          parentScope: data.parentScope,
        ),
        node.arguments!.map((e) => visitExpression(e)).toList(),
      );
    }

    if (node.arguments != null) {
      throw Exception("Can't call a non function value");
    }

    return data;
  }

  Value callFunction(FunctionDefinition storage, List<Value> arguments) {
    final Value? customInvoke = storage.invoke(arguments);

    if (customInvoke != null) return customInvoke;

    if (storage.data.data == null) return const None();

    signatureCheck(
      storage.arguments.values.toList(),
      arguments,
    );

    final Value? result = _evaluateStatements(
      storage.data,
      initialData: Map.fromIterables(
        storage.arguments.keys,
        arguments.mapIndexed(
          (index, e) => VariableDefinition(
            e,
            explicitType: storage.arguments.values.toList()[index],
          ),
        ),
      ),
      secondaryScope: storage.parentScope,
    );

    return result ?? const None();
  }

  Value? _evaluateStatements(
    Statements statements, {
    ScopeNative? initialData,
    Scope? secondaryScope,
  }) {
    _scope = Scope(
      initialData ?? {},
      parentScope: _scope,
      secondaryScope: secondaryScope,
    );

    Value? returnValue;
    for (final StatementNode statement in statements.data ?? []) {
      returnValue = visitStatement(statement);

      if (returnValue != null) break;
    }

    _scope = _scope.parentScope!;

    return returnValue;
  }

  @override
  Tuple visitTuple(TupleNode node) {
    final List<Value> values =
        node.values.map((e) => visitExpression(e)).toList();
    return Tuple(values, values.map((e) => e.type).toList());
  }

  @override
  ListVal visitList(ListNode node) {
    final List<Value> values =
        node.values.map((e) => visitExpression(e)).toList();

    return ListVal(values, [getListType(values)]);
  }

  @override
  Dict visitDict(DictNode node) {
    final List<Value> keys =
        node.values.keys.map((e) => visitExpression(e)).toList();
    final List<Value> values =
        node.values.values.map((e) => visitExpression(e)).toList();

    return Dict(
      Map.fromIterables(keys, values),
      [getListType(keys), getListType(values)],
    );
  }

  @override
  Type visitType(TypeNode node) {
    if (node is ComplexTypeNode) {
      if (node is FunctionTypeNode) {
        return FunctionType(
          visitType(node.returnType),
          node.types?.types.map((e) => visitType(e)).toList(),
        );
      }

      if (node.types != null) {
        switch (node.kind) {
          case TypeKind.list:
            if (node.types!.types.length > 1) {
              throw Exception("Lists can define only one type parameter");
            }
            break;
          case TypeKind.dict:
            if (node.types!.types.isEmpty) break;

            if (node.types!.types.length != 2) {
              throw Exception("Dicts can define only two type parameters");
            }
            break;
          default:
            break;
        }
      }

      return ComplexType(
        node.kind,
        node.types?.types.map((e) => visitType(e)).toList(),
      );
    }

    return Type(node.kind);
  }
}
