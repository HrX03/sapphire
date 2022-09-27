import 'package:antlr4/antlr4.dart';
import 'package:sapphire/antlr/SapphireParser.dart';
import 'package:sapphire/antlr/SapphireParserBaseVisitor.dart';
import 'package:sapphire/ast/base.dart';
import 'package:sapphire/ast/expression.dart';
import 'package:sapphire/ast/header.dart';
import 'package:sapphire/ast/statements.dart';
import 'package:sapphire/ast/type.dart';

class SapphireASTVisitor extends SapphireParserBaseVisitor<Node?> {
  @override
  FileNode visitFile(FileContext ctx) {
    final List<HeaderContext> headerContexts =
        ctx.headerList()?.headers() ?? [];
    final List<HeaderNode?> headers =
        headerContexts.map((e) => visitHeader(e)).toList();

    headers.removeWhere((e) => e == null);

    final List<StatementContext> statementContexts =
        ctx.statementList()?.statements() ?? [];
    final List<StatementNode?> statements =
        statementContexts.map((e) => visitStatement(e)).toList();

    statements.removeWhere((e) => e == null);

    return FileNode(
      headers: headers.cast<HeaderNode>(),
      statements: statements.cast<StatementNode>(),
      context: ctx,
    );
  }

  @override
  HeaderNode? visitHeader(HeaderContext ctx) {
    if (ctx.importHeader() != null) {
      return visitImportHeader(ctx.importHeader()!);
    }

    return null;
  }

  @override
  ImportHeaderNode? visitImportHeader(ImportHeaderContext ctx) {
    if (ctx.string() == null) return null;

    final String? library = visitString(ctx.string()!)?.contents;

    if (library == null) return null;

    final String? alias = ctx.simpleIdentifier()?.text;

    return ImportHeaderNode(library: library, alias: alias, context: ctx);
  }

  @override
  StatementNode? visitStatement(StatementContext ctx) {
    if (ctx.scope() != null) {
      return visitScope(ctx.scope()!);
    }

    if (ctx.defineStatement() != null) {
      return visitDefineStatement(ctx.defineStatement()!);
    }

    if (ctx.returnStatement() != null) {
      return visitReturnStatement(ctx.returnStatement()!);
    }

    if (ctx.undefineStatement() != null) {
      return visitUndefineStatement(ctx.undefineStatement()!);
    }

    if (ctx.identifier() != null) {
      return visitIdentifier(ctx.identifier()!);
    }

    if (ctx.assignStatement() != null) {
      return visitAssignStatement(ctx.assignStatement()!);
    }

    if (ctx.conditionalStatement() != null) {
      return visitConditionalStatement(ctx.conditionalStatement()!);
    }

    if (ctx.whileStatement() != null) {
      return visitWhileStatement(ctx.whileStatement()!);
    }

    return null;
  }

  @override
  ScopeNode? visitScope(ScopeContext ctx) {
    final List<StatementContext> statementContexts =
        ctx.statementList()?.statements() ?? [];
    final List<StatementNode?> statements =
        statementContexts.map((e) => visitStatement(e)).toList();

    statements.removeWhere((e) => e == null);

    return ScopeNode(
      statements: statements.cast<StatementNode>(),
      context: ctx,
    );
  }

  @override
  DefineStatementNode? visitDefineStatement(DefineStatementContext ctx) {
    final TypeNode? type = ctx.type() != null ? visitType(ctx.type()!) : null;

    final ExpressionNode? value = ctx.assignment()?.expression() != null
        ? visitExpression(ctx.assignment()!.expression()!)
        : null;

    final List<ArgumentContext>? argumentContexts =
        ctx.functionArguments()?.argumentList()?.arguments();
    final List<ArgumentNode?>? arguments =
        argumentContexts?.map((e) => visitArgument(e)).toList();

    arguments?.removeWhere((e) => e == null);

    return DefineStatementNode(
      identifier: ctx.simpleIdentifier()!.text,
      type: type ?? TypeNode.any(context: ctx),
      assignedValue: value ?? NoneNode(context: ctx),
      arguments: arguments?.cast<ArgumentNode>() ??
          (ctx.functionArguments() != null ? [] : null),
      exported: ctx.ExportKeyword() != null,
      context: ctx,
    );
  }

  @override
  ArgumentNode? visitArgument(ArgumentContext ctx) {
    final TypeNode? type = ctx.type() != null ? visitType(ctx.type()!) : null;
    final String? id = ctx.simpleIdentifier()?.text;

    if (id == null) return null;

    return ArgumentNode(
      id: id,
      type: type ?? TypeNode.any(context: ctx),
      context: ctx,
    );
  }

  @override
  ReturnStatementNode? visitReturnStatement(ReturnStatementContext ctx) {
    final ExpressionNode? value =
        ctx.expression() != null ? visitExpression(ctx.expression()!) : null;

    return ReturnStatementNode(value: value, context: ctx);
  }

  @override
  UndefineStatementNode? visitUndefineStatement(UndefineStatementContext ctx) {
    final String? id = ctx.simpleIdentifier()?.text;

    if (id == null) return null;

    return UndefineStatementNode(id: id, context: ctx);
  }

  @override
  AssignStatementNode? visitAssignStatement(AssignStatementContext ctx) {
    if (ctx.assignment() == null) return null;

    final String? id = ctx.simpleIdentifier()?.text;
    final ExpressionNode? value = ctx.assignment()?.expression() != null
        ? visitExpression(ctx.assignment()!.expression()!)
        : null;

    if (id == null || value == null) return null;

    return AssignStatementNode(id: id, value: value, context: ctx);
  }

  @override
  ConditionalStatementNode? visitConditionalStatement(
    ConditionalStatementContext ctx,
  ) {
    final IfBlockContext? ifBlock = ctx.ifBlock();

    if (ifBlock == null) return null;

    final ExpressionNode? condition = ifBlock.condition()?.expression() != null
        ? visitExpression(ifBlock.condition()!.expression()!)
        : null;

    final ScopeNode? scope =
        ifBlock.scope() != null ? visitScope(ifBlock.scope()!) : null;

    if (condition == null || scope == null) return null;

    final Map<ExpressionNode, ScopeNode> conditions = {condition: scope};

    for (final ElifBlockContext elifBlock in ctx.elifBlocks()) {
      final ExpressionNode? condition =
          elifBlock.condition()?.expression() != null
              ? visitExpression(elifBlock.condition()!.expression()!)
              : null;

      final ScopeNode? scope =
          elifBlock.scope() != null ? visitScope(elifBlock.scope()!) : null;

      if (condition == null || scope == null) continue;

      conditions[condition] = scope;
    }

    ScopeNode? elseBlock;
    final ElseBlockContext? elseBlockCtx = ctx.elseBlock();

    if (elseBlockCtx != null) {
      final ScopeNode? scope = elseBlockCtx.scope() != null
          ? visitScope(elseBlockCtx.scope()!)
          : null;

      elseBlock = scope;
    }

    return ConditionalStatementNode(
      conditions: conditions,
      elseScope: elseBlock,
      context: ctx,
    );
  }

  @override
  WhileStatementNode? visitWhileStatement(WhileStatementContext ctx) {
    final ExpressionNode? condition = ctx.condition()?.expression() != null
        ? visitExpression(ctx.condition()!.expression()!)
        : null;

    if (condition == null) return null;
    if (ctx.scope() == null) return null;

    final List<StatementContext> statementContexts =
        ctx.scope()!.statementList()?.statements() ?? [];
    final List<StatementNode?> statements =
        statementContexts.map((e) => visitStatement(e)).toList();

    statements.removeWhere((e) => e == null);

    return WhileStatementNode(
      condition: condition,
      statements: statements.cast<StatementNode>(),
      context: ctx,
    );
  }

  @override
  ExpressionNode? visitExpression(ExpressionContext ctx) {
    if (ctx.scope() != null) {
      return visitScope(ctx.scope()!);
    }

    if (ctx.tuple() != null) {
      return visitTuple(ctx.tuple()!);
    }

    if (ctx.dict() != null) {
      return visitDict(ctx.dict()!);
    }

    if (ctx.list() != null) {
      return visitList(ctx.list()!);
    }

    if (ctx.literalConstant() != null) {
      return visitLiteralConstant(ctx.literalConstant()!);
    }

    if (ctx.string() != null) {
      return visitString(ctx.string()!);
    }

    if (ctx.type() != null) {
      return visitType(ctx.type()!);
    }

    if (ctx.identifier() != null) {
      return visitIdentifier(ctx.identifier()!);
    }

    return null;
  }

  @override
  TypeNode? visitType(TypeContext ctx) {
    if (ctx.complexType() != null) {
      return visitComplexType(ctx.complexType()!);
    }

    final TypeNode type;
    final ParseTree? child = ctx.getChild(0);

    if (child == null || child is! TerminalNode) return null;

    switch (child.symbol.type) {
      case SapphireParser.TOKEN_AnyKeyword:
        type = TypeNode.any(context: ctx);
        break;
      case SapphireParser.TOKEN_NoneKeyword:
        type = TypeNode.none(context: ctx);
        break;
      case SapphireParser.TOKEN_StringKeyword:
        type = TypeNode.string(context: ctx);
        break;
      case SapphireParser.TOKEN_NumberKeyword:
        type = TypeNode.number(context: ctx);
        break;
      case SapphireParser.TOKEN_BooleanKeyword:
        type = TypeNode.boolean(context: ctx);
        break;
      case SapphireParser.TOKEN_ScopeKeyword:
        type = TypeNode.scope(context: ctx);
        break;
      case SapphireParser.TOKEN_TypeKeyword:
        type = TypeNode.type(context: ctx);
        break;
      default:
        return null;
    }

    return type;
  }

  @override
  ComplexTypeNode? visitComplexType(ComplexTypeContext ctx) {
    if (ctx.complexTypeName() == null) return null;

    final TypeListNode? types =
        ctx.typeList() != null ? visitTypeList(ctx.typeList()!) : null;

    final ComplexTypeNode type;
    final ParseTree? child = ctx.complexTypeName()?.getChild(0);

    if (child == null || child is! TerminalNode) return null;

    switch (child.symbol.type) {
      case SapphireParser.TOKEN_ListKeyword:
        type = ComplexTypeNode.list(types: types, context: ctx);
        break;
      case SapphireParser.TOKEN_DictionaryKeyword:
        type = ComplexTypeNode.dict(types: types, context: ctx);
        break;
      case SapphireParser.TOKEN_TupleKeyword:
        type = ComplexTypeNode.tuple(types: types, context: ctx);
        break;
      case SapphireParser.TOKEN_FunctionKeyword:
        final TypeNode? returnType = ctx.complexTypeName()!.type() != null
            ? visitType(ctx.complexTypeName()!.type()!)
            : null;

        type = FunctionTypeNode(
          returnType: returnType ?? TypeNode.any(context: ctx),
          types: types,
          context: ctx,
        );
        break;
      default:
        return null;
    }

    return type;
  }

  @override
  TypeListNode? visitTypeList(TypeListContext ctx) {
    final List<TypeContext> typeContexts = ctx.types();
    final List<TypeNode?> types =
        typeContexts.map((e) => visitType(e)).toList();

    types.removeWhere((e) => e == null);

    return TypeListNode(types: types.cast<TypeNode>(), context: ctx);
  }

  @override
  LiteralNode? visitLiteralConstant(LiteralConstantContext ctx) {
    final LiteralNode literal;
    final ParseTree? child = ctx.getChild(0);

    if (child == null || child is! TerminalNode) return null;

    switch (child.symbol.type) {
      case SapphireParser.TOKEN_Number:
        String text;
        final int radix;

        if (ctx.text.toLowerCase().startsWith('0x')) {
          text = ctx.text.substring(2);
          radix = 16;
        } else if (ctx.text.toLowerCase().startsWith('0b')) {
          text = ctx.text.substring(2);
          radix = 2;
        } else {
          text = ctx.text;
          radix = 10;
        }

        text = text.replaceAll("_", "");

        final num? value =
            int.tryParse(text, radix: radix) ?? double.tryParse(text);

        if (value == null) return null;

        literal = NumberNode(value: value, context: ctx);
        break;
      case SapphireParser.TOKEN_Boolean:
        literal = BooleanNode(value: ctx.text == "true", context: ctx);
        break;
      case SapphireParser.TOKEN_ThisKeyword:
        literal = ThisNode(context: ctx);
        break;
      case SapphireParser.TOKEN_RootKeyword:
        literal = RootNode(context: ctx);
        break;
      case SapphireParser.TOKEN_NoneKeyword:
        literal = NoneNode(context: ctx);
        break;
      default:
        return null;
    }

    return literal;
  }

  @override
  StringNode? visitString(StringContext ctx) {
    final StringContentsContext? contentsCtx = ctx.stringContents(0);

    if (contentsCtx == null) return null;

    return StringNode(contents: contentsCtx.text, context: ctx);
  }

  @override
  TupleNode? visitTuple(TupleContext ctx) {
    final List<ExpressionNode?>? expressions =
        ctx.exprList()?.expressions().map((e) => visitExpression(e)).toList();

    expressions?.removeWhere((e) => e == null);

    return TupleNode(
      values: expressions?.cast<ExpressionNode>() ?? [],
      context: ctx,
    );
  }

  @override
  ExpressionNode? visitList(ListContext ctx) {
    final List<ExpressionNode?>? expressions =
        ctx.exprList()?.expressions().map((e) => visitExpression(e)).toList();

    expressions?.removeWhere((e) => e == null);

    return ListNode(
      values: expressions?.cast<ExpressionNode>() ?? [],
      context: ctx,
    );
  }

  @override
  ExpressionNode? visitDict(DictContext ctx) {
    final List<ExprDictEntryContext>? entryContexts =
        ctx.exprDict()?.exprDictEntrys();
    final List<MapEntry<ExpressionNode, ExpressionNode>?>? entries =
        entryContexts?.map(
      (e) {
        if (e.expression(0) == null || e.expression(1) == null) return null;

        final ExpressionNode? key = visitExpression(e.expression(0)!);
        final ExpressionNode? value = visitExpression(e.expression(1)!);

        if (key == null || value == null) return null;

        return MapEntry(key, value);
      },
    ).toList();

    entries?.removeWhere((e) => e == null);

    return DictNode(
      values: Map.fromEntries(
        entries?.cast<MapEntry<ExpressionNode, ExpressionNode>>() ?? [],
      ),
      context: ctx,
    );
  }

  @override
  IdentifierNode? visitIdentifier(IdentifierContext ctx) {
    final List<String> parts = ctx.Identifiers().map((e) => e.text!).toList();
    final List<ExpressionNode?>? expressions = ctx
        .functionCall()
        ?.exprList()
        ?.expressions()
        .map((e) => visitExpression(e))
        .toList();

    expressions?.removeWhere((e) => e == null);

    if (parts.length == 1) {
      return IdentifierNode(
        identifier: parts.single,
        arguments: expressions?.cast<ExpressionNode>() ??
            (ctx.functionCall() != null ? [] : null),
        context: ctx,
      );
    } else {
      return IdentifierNode(
        libraryId: parts.first,
        identifier: parts.last,
        arguments: expressions?.cast<ExpressionNode>(),
        context: ctx,
      );
    }
  }
}
