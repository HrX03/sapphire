To generate the ANTLR4 parser download and install it by following [the guide here](https://github.com/antlr/antlr4/blob/master/doc/getting-started.md)

Then, run this command from the root of this folder:
```Shell
antlr4 -Dlanguage=Dart ./lib/antlr/SapphireParser.g4 ./lib/antlr/SapphireLexer.g4 -listener -visitor
```