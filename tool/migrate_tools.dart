#!/usr/bin/env dart
/// Automated migration script for pilot tools from annotations to DSL.
///
/// Usage: dart tool/migrate_tools.dart
///
/// This script:
/// 1. Scans all @PilotService annotated files
/// 2. Extracts @PilotTool methods and their signatures
/// 3. Generates corresponding *_tools.dart files with the new DSL
/// 4. Outputs a migration report

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('🚀 DioPilot Tool Migration Script\n');

  final projectRoot = Directory.current;
  final libDir = Directory(path.join(projectRoot.path, 'lib'));

  // Find all service files with @PilotService
  final serviceFiles = await _findServiceFiles(libDir);
  print('📁 Found ${serviceFiles.length} service files to migrate:\n');

  for (final file in serviceFiles) {
    print('  - ${path.relative(file.path, from: projectRoot.path)}');
  }
  print('');

  int totalToolsMigrated = 0;
  final List<String> generatedFiles = [];

  for (final serviceFile in serviceFiles) {
    print('🔄 Processing ${path.basename(serviceFile.path)}...');

    try {
      final result = await _migrateServiceFile(serviceFile, projectRoot);
      totalToolsMigrated += result.toolCount;
      generatedFiles.add(result.outputFile);

      print('   ✅ Generated ${result.toolCount} tools → ${path.basename(result.outputFile)}');
    } catch (e, stack) {
      print('   ❌ Error: $e');
      print('   Stack: $stack');
    }
  }

  print('\n✨ Migration Complete!');
  print('   📊 Total tools migrated: $totalToolsMigrated');
  print('   📝 Generated files: ${generatedFiles.length}');
  print('\nNext steps:');
  print('  1. Review generated *_tools.dart files');
  print('  2. Run: fvm dart format lib/');
  print('  3. Run: fvm dart analyze lib/');
  print('  4. Test the migrated tools');
  print('  5. Update all_pilot_tools.dart to import these files');
}

Future<List<File>> _findServiceFiles(Directory dir) async {
  final serviceFiles = <File>[];

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('_service.dart')) {
      final content = await entity.readAsString();
      if (content.contains('@PilotService')) {
        serviceFiles.add(entity);
      }
    }
  }

  return serviceFiles;
}

Future<MigrationResult> _migrateServiceFile(
  File serviceFile,
  Directory projectRoot,
) async {
  final content = await serviceFile.readAsString();
  final serviceName = path.basenameWithoutExtension(serviceFile.path);
  final outputPath = serviceFile.path.replaceAll('_service.dart', '_tools.dart');

  // Parse the service
  final parser = ServiceParser(content, serviceName);
  final serviceInfo = parser.parse();

  // Generate the tools file
  final generator = ToolFileGenerator(serviceInfo, serviceName);
  final generatedCode = generator.generate();

  // Write the output file
  final outputFile = File(outputPath);
  await outputFile.writeAsString(generatedCode);

  return MigrationResult(
    toolCount: serviceInfo.tools.length,
    outputFile: outputPath,
  );
}

class MigrationResult {
  final int toolCount;
  final String outputFile;

  MigrationResult({required this.toolCount, required this.outputFile});
}

class ServiceInfo {
  final String className;
  final String scope;
  final List<ToolInfo> tools;
  final Set<String> imports;

  ServiceInfo({
    required this.className,
    required this.scope,
    required this.tools,
    required this.imports,
  });
}

class ToolInfo {
  final String methodName;
  final String toolName;
  final String safety;
  final String returnType;
  final List<Parameter> parameters;
  final bool isAsync;

  ToolInfo({
    required this.methodName,
    required this.toolName,
    required this.safety,
    required this.returnType,
    required this.parameters,
    required this.isAsync,
  });
}

class Parameter {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;

  Parameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    this.defaultValue,
  });
}

class ServiceParser {
  final String content;
  final String serviceName;

  ServiceParser(this.content, this.serviceName);

  ServiceInfo parse() {
    final className = _extractClassName();
    final scope = _extractScope();
    final tools = _extractTools();
    final imports = _extractImports();

    return ServiceInfo(
      className: className,
      scope: scope,
      tools: tools,
      imports: imports,
    );
  }

  String _extractClassName() {
    final match = RegExp(r'class\s+(\w+)').firstMatch(content);
    return match?.group(1) ?? 'UnknownService';
  }

  String _extractScope() {
    final match = RegExp(r'@PilotService\s*\(\s*scope:\s*PilotScope\.(\w+)').firstMatch(content);
    return match?.group(1) ?? 'global';
  }

  Set<String> _extractImports() {
    final imports = <String>{};
    // Simple string-based extraction instead of complex regex
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        final match = RegExp("import\\s+['\"]([^'\"]+)['\"];").firstMatch(line);
        if (match != null) {
          final importPath = match.group(1)!;
          if (!importPath.contains('pilot_annotations') &&
              !importPath.endsWith('.pilot_refs.g.dart')) {
            imports.add(importPath);
          }
        }
      }
    }
    return imports;
  }

  List<ToolInfo> _extractTools() {
    final tools = <ToolInfo>[];

    // Find all @PilotTool annotations - use simple string matching
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('@PilotTool')) {
        // Extract safety
        final safetyMatch = RegExp(r'PilotToolSafety\.(\w+)').firstMatch(line);
        if (safetyMatch == null) continue;
        final safety = safetyMatch.group(1)!;

        // Extract optional name
        String? toolName;
        final nameMatch = RegExp("name:\\s*[\"']([^\"']+)[\"']").firstMatch(line);
        if (nameMatch != null) {
          toolName = nameMatch.group(1);
        }

        // Find the method signature on next non-empty line
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final methodLine = lines[j].trim();
          if (methodLine.isEmpty || methodLine.startsWith('//')) continue;

          // Match: ReturnType methodName(
          final methodMatch = RegExp(r'(Future<[^>]+>|[\w<>?]+)\s+(\w+)\s*\(').firstMatch(methodLine);
          if (methodMatch != null) {
            final returnType = methodMatch.group(1)!;
            final methodName = methodMatch.group(2)!;

            final parameters = _extractMethodParameters(methodName);

            tools.add(ToolInfo(
              methodName: methodName,
              toolName: toolName ?? _camelToSnake(methodName),
              safety: safety,
              returnType: returnType,
              parameters: parameters,
              isAsync: returnType.startsWith('Future'),
            ));
            break;
          }
        }
      }
    }

    return tools;
  }

  List<Parameter> _extractMethodParameters(String methodName) {
    // Find the method signature - look for the entire signature including opening brace
    final lines = content.split('\n');
    int methodLineIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('$methodName(')) {
        methodLineIndex = i;
        break;
      }
    }
    
    if (methodLineIndex == -1) return [];
    
    // Collect lines until we find the closing parenthesis
    final signatureLines = <String>[];
    bool foundCloseParen = false;
    
    for (int i = methodLineIndex; i < lines.length && i < methodLineIndex + 20; i++) {
      signatureLines.add(lines[i]);
      if (lines[i].contains(')')) {
        foundCloseParen = true;
        break;
      }
    }
    
    if (!foundCloseParen) return [];
    
    final signature = signatureLines.join(' ');
    
    // Extract parameter section between parentheses
    final parenMatch = RegExp(r'\(([^)]*)\)').firstMatch(signature);
    if (parenMatch == null) return [];
    
    final paramsString = parenMatch.group(1) ?? '';
    if (paramsString.trim().isEmpty) return [];

    final parameters = <Parameter>[];
    
    // Split by comma but be careful with generics
    final paramParts = _splitParameters(paramsString);
    
    for (final part in paramParts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty || trimmed == 'this') continue;

      // Parse: [final] [required] Type name [= default]
      final paramMatch = RegExp(
        r'(?:final\s+)?(?:required\s+)?([\w<>?,\s]+?)\s+(\w+)(?:\s*=\s*(.+))?$',
      ).firstMatch(trimmed);

      if (paramMatch != null) {
        final type = paramMatch.group(1)!.trim();
        final name = paramMatch.group(2)!;
        final defaultValue = paramMatch.group(3);

        parameters.add(Parameter(
          name: name,
          type: type,
          isRequired: trimmed.contains('required'),
          isNamed: !trimmed.startsWith('final') && (trimmed.contains('required') || defaultValue != null || paramsString.contains('{')),
          defaultValue: defaultValue?.trim(),
        ));
      }
    }

    return parameters;
  }
  
  List<String> _splitParameters(String params) {
    final parts = <String>[];
    int depth = 0;
    int start = 0;
    
    for (int i = 0; i < params.length; i++) {
      final char = params[i];
      if (char == '<' || char == '{' || char == '[') {
        depth++;
      } else if (char == '>' || char == '}' || char == ']') {
        depth--;
      } else if (char == ',' && depth == 0) {
        parts.add(params.substring(start, i));
        start = i + 1;
      }
    }
    
    if (start < params.length) {
      parts.add(params.substring(start));
    }
    
    return parts;
  }

  String _camelToSnake(String camel) {
    return camel.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }
}

class ToolFileGenerator {
  final ServiceInfo serviceInfo;
  final String serviceName;

  ToolFileGenerator(this.serviceInfo, this.serviceName);

  String generate() {
    final buffer = StringBuffer();

    // File header
    _writeHeader(buffer);

    // Imports
    _writeImports(buffer);

    // Function to build tools
    _writeToolBuilderFunction(buffer);

    return buffer.toString();
  }

  void _writeHeader(StringBuffer buffer) {
    buffer.writeln('// AUTO-GENERATED by migrate_tools.dart');
    buffer.writeln('// Generated from: ${serviceName}_service.dart');
    buffer.writeln('// DO NOT EDIT - Review and adjust as needed\n');
  }

  void _writeImports(StringBuffer buffer) {
    // Core pilot imports
    buffer.writeln("import 'package:diohub/services/pilot/pilot_tool.dart';");
    buffer.writeln("import 'package:diohub/services/pilot/tool_builder.dart';");
    buffer.writeln("import 'package:diohub/services/pilot/tool_category.dart';");
    buffer.writeln("import 'package:diohub/services/pilot/tool_schema.dart';");

    // Service import (remove _service suffix from serviceName for the import)
    final serviceFileName = serviceName.replaceAll('_service', '');
    buffer.writeln("import '${serviceFileName}_service.dart';");

    // Other imports from original service
    for (final import in serviceInfo.imports) {
      if (!import.contains('pilot_annotations')) {
        buffer.writeln("import '$import';");
      }
    }

    buffer.writeln();
  }

  void _writeToolBuilderFunction(StringBuffer buffer) {
    final serviceVar = _toLowerCamelCase(serviceInfo.className);
    
    // Clean function name: remove _service suffix and capitalize
    final cleanName = serviceName
        .replaceAll('_service', '')
        .split('_')
        .map((part) => _capitalize(part))
        .join();
    
    buffer.writeln('/// Pilot tools for ${serviceInfo.className}.');
    buffer.writeln('List<PilotTool> build${cleanName}Tools() {');
    buffer.writeln('  final $serviceVar = ${serviceInfo.className}();');
    buffer.writeln();

    // Generate each tool
    for (var i = 0; i < serviceInfo.tools.length; i++) {
      final tool = serviceInfo.tools[i];
      _writeToolDefinition(buffer, tool, serviceVar, i);
      buffer.writeln();
    }

    // Return list
    buffer.writeln('  return [');
    for (var i = 0; i < serviceInfo.tools.length; i++) {
      buffer.writeln('    ${_toolVarName(serviceInfo.tools[i], i)},');
    }
    buffer.writeln('  ];');
    buffer.writeln('}');
  }

  void _writeToolDefinition(
    StringBuffer buffer,
    ToolInfo tool,
    String serviceVar,
    int index,
  ) {
    final varName = _toolVarName(tool, index);
    final scope = _scopeToDsl(serviceInfo.scope);
    final safety = _safetyToDslMethod(tool.safety);
    final category = _guessCategory(tool.toolName);

    buffer.writeln('  final $varName = Tool.$scope.$safety<${_extractGenericType(tool.returnType)}>(');
    buffer.writeln("    name: '${tool.toolName}',");
    buffer.writeln("    description: 'TODO: Add description for ${tool.toolName}',");
    buffer.writeln('    category: ToolCategory.$category,');
    
    // Schema
    if (tool.parameters.isNotEmpty) {
      _writeSchema(buffer, tool.parameters);
    }

    // Fetch callback
    _writeFetch(buffer, tool, serviceVar);

    // Serialize callback
    _writeSerialize(buffer, tool);

    // ExecuteConfirmed for write/optIn tools
    if (safety != 'read') {
      _writeExecuteConfirmed(buffer, tool, serviceVar);
    }

    buffer.writeln('  );');
  }

  void _writeSchema(StringBuffer buffer, List<Parameter> parameters) {
    buffer.writeln('    schema: ToolSchema.object(');
    buffer.writeln('      properties: {');

    for (final param in parameters) {
      if (param.name == 'this') continue; // Skip 'this' parameter
      
      final schemaType = _dartTypeToSchemaType(param.type);
      buffer.writeln("        '${param.name}': ToolSchema.$schemaType(");
      buffer.writeln("          description: 'TODO: Add description',");
      buffer.writeln('        ),');
    }

    buffer.writeln('      },');

    // Required parameters
    final required = parameters.where((p) => p.isRequired).map((p) => p.name).toList();
    if (required.isNotEmpty) {
      buffer.writeln('      required: [${required.map((r) => "'$r'").join(', ')}],');
    }

    buffer.writeln('    ),');
  }

  void _writeFetch(StringBuffer buffer, ToolInfo tool, String serviceVar) {
    buffer.writeln('    fetch: (args, scope) async {');
    
    // Extract parameters
    final namedParams = <String>[];
    final positionalParams = <String>[];
    
    for (final param in tool.parameters) {
      if (param.name == 'this') continue;
      
      final getter = param.isRequired ? 'get' : 'optional';
      final typeMethod = _dartTypeToArgsMethod(param.type);
      buffer.writeln('      final ${param.name} = args.$getter$typeMethod(\'${param.name}\');');
      
      if (param.isNamed) {
        namedParams.add('${param.name}: ${param.name}');
      } else {
        positionalParams.add(param.name);
      }
    }

    // Call the service method
    buffer.write('      return await $serviceVar.${tool.methodName}(');
    
    if (positionalParams.isNotEmpty && namedParams.isNotEmpty) {
      buffer.write(positionalParams.join(', '));
      buffer.write(', ');
      buffer.write(namedParams.join(', '));
    } else if (positionalParams.isNotEmpty) {
      buffer.write(positionalParams.join(', '));
    } else if (namedParams.isNotEmpty) {
      buffer.write(namedParams.join(', '));
    }
    
    buffer.writeln(');');
    buffer.writeln('    },');
  }

  void _writeSerialize(StringBuffer buffer, ToolInfo tool) {
    final returnType = _extractGenericType(tool.returnType);
    
    buffer.writeln('    serialize: (result) {');
    
    // Handle primitives
    if (_isPrimitiveType(returnType)) {
      buffer.writeln('      return {\'value\': result};');
    }
    // Handle lists
    else if (returnType.startsWith('List<')) {
      buffer.writeln('      return result.map((e) => e.toJson()).toList();');
    }
    // Handle PaginatedResult
    else if (returnType.startsWith('PaginatedResult<')) {
      buffer.writeln('      return result.items.map((e) => e.toJson()).toList();');
    }
    // Handle objects with toJson
    else {
      buffer.writeln('      return result.toJson();');
    }
    
    buffer.writeln('    },');
    buffer.writeln("    defaults: {'id'}, // TODO: Specify important fields");
  }
  
  bool _isPrimitiveType(String type) {
    final clean = type.replaceAll('?', '').trim();
    return ['int', 'String', 'bool', 'double', 'num', 'void'].contains(clean);
  }

  void _writeExecuteConfirmed(StringBuffer buffer, ToolInfo tool, String serviceVar) {
    buffer.writeln('    executeConfirmed: (payload, scope, ctx) async {');
    buffer.writeln('      // TODO: Implement executeConfirmed');
    buffer.writeln('      final result = await $serviceVar.${tool.methodName}(/* extract from payload */);');
    buffer.writeln('      return result;');
    buffer.writeln('    },');
  }

  String _toolVarName(ToolInfo tool, int index) {
    return '${tool.methodName}Tool';
  }

  String _scopeToDsl(String scope) {
    switch (scope.toLowerCase()) {
      case 'global': return 'global';
      case 'repo': return 'repo';
      case 'issuepull': return 'issuePull';
      case 'pullrequest': return 'pullRequest';
      case 'user': return 'user';
      default: return 'global';
    }
  }

  String _safetyToDslMethod(String safety) {
    switch (safety.toLowerCase()) {
      case 'readonly': return 'read';
      case 'requiresconfirmation': return 'write';
      case 'optin': return 'optIn';
      default: return 'read';
    }
  }

  String _guessCategory(String toolName) {
    if (toolName.contains('search')) return 'search';
    if (toolName.contains('notification')) return 'notifications';
    if (toolName.contains('issue')) return 'issues';
    if (toolName.contains('pull')) return 'issues';
    if (toolName.contains('repo')) return 'repository';
    if (toolName.contains('branch')) return 'branches';
    if (toolName.contains('user')) return 'userProfiles';
    return 'meta';
  }

  String _extractGenericType(String returnType) {
    final match = RegExp(r'Future<(.+)>').firstMatch(returnType);
    if (match != null) {
      return match.group(1)!;
    }
    return returnType;
  }

  String _dartTypeToSchemaType(String dartType) {
    final clean = dartType.replaceAll('?', '').trim();
    if (clean == 'String') return 'string';
    if (clean == 'int') return 'integer';
    if (clean == 'bool') return 'boolean';
    if (clean.startsWith('List<')) return 'array';
    if (clean.startsWith('Map<')) return 'object';
    return 'string';
  }

  String _dartTypeToArgsMethod(String dartType) {
    final clean = dartType.replaceAll('?', '').trim();
    if (clean == 'String') return 'String';
    if (clean == 'int') return 'Int';
    if (clean == 'bool') return 'Bool';
    if (clean.startsWith('List<String>')) return 'StringList';
    if (clean.startsWith('Set<String>')) return 'StringSet';
    if (clean.startsWith('Map<')) return 'raw';
    return 'String';
  }

  String _toLowerCamelCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toLowerCase() + s.substring(1);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
