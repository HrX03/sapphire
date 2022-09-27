import 'dart:io';

import 'package:antlr4/antlr4.dart';
import 'package:sapphire/antlr/SapphireLexer.dart';
import 'package:sapphire/antlr/SapphireParser.dart';
import 'package:sapphire/ast/builder.dart';
import 'package:sapphire/ast/statements.dart';
import 'package:sapphire/interpreter/interpreter.dart';

Future main(List<String> arguments) async {
  if (arguments.isEmpty) {
    return interpreter();
  } else if (arguments.length == 1) {
    return SapphireInterpreter.interpretFile(File(arguments.first));
  }
}

Future<void> interpreter() async {
  final List<String> accumulator = [];
  final SapphireInterpreter interpreter =
      SapphireInterpreter(Directory.current);

  while (true) {
    stdout.write("> ");
    final String? line = stdin.readLineSync();

    if (line != null && line.isNotEmpty) {
      if (accumulator.isEmpty) {
        accumulator.add(line);
      } else {
        accumulator.add(line);
      }

      continue;
    }

    final InputStream input = InputStream.fromString(accumulator.join("\n"));
    final SapphireLexer lexer = SapphireLexer(input);
    final CommonTokenStream tokens = CommonTokenStream(lexer);
    final SapphireParser parser = SapphireParser(tokens);

    final FileContext tree = parser.file();
    final FileNode file = SapphireASTVisitor().visitFile(tree);
    await interpreter.visitFile(file);

    //print(file.statements.map((e) => e).toList());

    accumulator.clear();
  }
}
