#!/usr/bin/env dart
// Script to add @Lens annotations to service methods based on existing tool definitions

import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  print('DioLens Service Annotator');
  print('========================\n');
  
  final toolFiles = await _findToolFiles();
  print('Found ${toolFiles.length} tool files\n');
  
  final toolMappings = <String, List<ToolDefinition>>{};
  
  // Parse all tool files
  for (final toolFile in toolFiles) {
    print('Parsing ${path.basename(toolFile)}...');
    final tools = await _parseToolFile(toolFile);
    final serviceName = _inferServiceName(path.basename(toolFile));
    toolMappings[serviceName] = tools;
    print('  Found ${tools.length} tools\n');
  }
  
  // Find and annotate service files
  for (final entry in toolMappings.entries) {
    final serviceName = entry.key;
    final tools = entry.value;
    
    final serviceFile = await _findServiceFile(serviceName);
    if (serviceFile == null) {
      print('WARNING: Could not find service file for $serviceName');
      continue;
    }
    
    print('Annotating ${path.basename(serviceFile)}...');
    await _annotateServiceFile(serviceFile, tools, serviceName);
    print('  Added ${tools.length} annotations\n');
  }
  
  print('\nDone! Review the changes and run:');
  print('  fvm dart format lib/services/');
  print('  fvm dart run build_runner build');
}

class ToolDefinition {
  final String toolName;
  final String description;
  final String category;
  final String access; // read, write, optIn
  final String methodName;
  final Map<String, String> paramDescriptions;
  final double priority;
  final bool isCore;
  
  ToolDefinition({
    required this.toolName,
    required this.description,
    required this.category,
    required this.access,
    required this.methodName,
    required this.paramDescriptions,
    this.priority = 0.7,
    this.isCore = false,
  });
}

Future<List<String>> _findToolFiles() async {
  final files = <String>[];
  
  // Search in lib/services/**/*_tools.dart
  final servicesDir = Directory('lib/services');
  await for (final entity in servicesDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('_tools.dart')) {
      // Skip meta and custom tools - those are hand-written
      if (entity.path.contains('/tools/meta/') || 
          entity.path.contains('/tools/custom/')) {
        continue;
      }
      files.add(entity.path);
    }
  }
  
  return files;
}

Future<List<ToolDefinition>> _parseToolFile(String filePath) async {
  final content = await File(filePath).readAsString();
  final tools = <ToolDefinition>[];
  
  // Simple regex-based parsing (sufficient for our use case)
  // Look for patterns like: Tool.repo.readTyped(name: 'tool_name', ...)
  final toolPattern = RegExp(
    r'Tool\.(repo|global|user|issuePull|pullRequest)\.(read|write|optIn)Typed[^(]*\(\s*'
    r'name:\s*' + "'" + r'([^' + "'" + r']+)' + "'" + r'\s*,\s*'
    r'description:\s*' + "'" + r'([^' + "'" + r']+)' + "'" + r'\s*,\s*'
    r'category:\s*([^,]+),',
    multiLine: true,
    dotAll: true,
  );
  
  final matches = toolPattern.allMatches(content);
  for (final match in matches) {
    final scope = match.group(1)!;
    final access = match.group(2)!;
    final toolName = match.group(3)!;
    final description = match.group(4)!;
    final category = match.group(5)!.trim();
    
    // Extract method name from fn: callback
    final methodName = _extractMethodName(content, match.end);
    if (methodName == null) continue;
    
    // Extract parameter descriptions
    final paramDescs = _extractParamDescriptions(content, match.start, match.end);
    
    tools.add(ToolDefinition(
      toolName: toolName,
      description: description,
      category: category,
      access: access,
      methodName: methodName,
      paramDescriptions: paramDescs,
    ));
  }
  
  return tools;
}

String? _extractMethodName(String content, int startPos) {
  // Look for pattern: service.methodName( or return service.methodName(
  final methodPattern = RegExp(r'service\.(\w+)\(');
  final searchEnd = (startPos + 500).clamp(0, content.length);
  final match = methodPattern.firstMatch(content.substring(startPos, searchEnd));
  return match?.group(1);
}

Map<String, String> _extractParamDescriptions(String content, int start, int end) {
  final params = <String, String>{};
  
  // Look for P.string('param_name', 'description') patterns
  final paramPattern = RegExp(r'P\.\w+\(' + "'" + r'(\w+)' + "'" + r'\s*,\s*' + "'" + r'([^' + "'" + r']+)' + "'" + r'\)');
  final searchEnd = (end + 1000).clamp(0, content.length);
  final section = content.substring(start, searchEnd);
  
  for (final match in paramPattern.allMatches(section)) {
    params[match.group(1)!] = match.group(2)!;
  }
  
  return params;
}

String _inferServiceName(String toolFileName) {
  // Convert repo_stats_tools.dart -> RepoStatsService
  var name = toolFileName.replaceAll('_tools.dart', '');
  name = name.split('_').map((word) => 
    word[0].toUpperCase() + word.substring(1)
  ).join('');
  
  if (!name.endsWith('Service')) {
    name += 'Service';
  }
  
  return name;
}

Future<String?> _findServiceFile(String serviceName) async {
  // Convert RepoStatsService -> repo_stats_service.dart
  final fileName = serviceName
      .replaceAll(RegExp(r'([A-Z])'), '_\$1')
      .toLowerCase()
      .replaceFirst('_', '');
  
  final servicesDir = Directory('lib/services');
  await for (final entity in servicesDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('/$fileName.dart')) {
      return entity.path;
    }
  }
  
  return null;
}

Future<void> _annotateServiceFile(
  String filePath,
  List<ToolDefinition> tools,
  String serviceName,
) async {
  var content = await File(filePath).readAsString();
  
  // Add import for annotations if not present
  if (!content.contains('package:lens_annotations')) {
    final importPos = content.indexOf('import');
    if (importPos != -1) {
      content = content.substring(0, importPos) +
          "import 'package:lens_annotations/lens_annotations.dart';\n" +
          content.substring(importPos);
    }
  }
  
  // Add @LensService to class if not present
  final classPattern = RegExp(r'class\s+$serviceName\s+extends');
  if (!content.contains('@LensService') && classPattern.hasMatch(content)) {
    content = content.replaceFirst(
      classPattern,
      '@LensService()\nclass $serviceName extends',
    );
  }
  
  // Add @Lens to each method
  for (final tool in tools) {
    content = _addLensAnnotation(content, tool);
  }
  
  await File(filePath).writeAsString(content);
}

String _addLensAnnotation(String content, ToolDefinition tool) {
  // Find the method declaration
  final methodPattern = RegExp(
    r'([\s]*)(Future<[^>]+>|void)\s+' + tool.methodName + r'\s*\(',
    multiLine: true,
  );
  
  final match = methodPattern.firstMatch(content);
  if (match == null) return content;
  
  final indent = match.group(1)!;
  final methodStart = match.start;
  
  // Check if already annotated
  final before = content.substring(max(0, methodStart - 200), methodStart);
  if (before.contains('@Lens')) return content;
  
  // Build annotation
  final annotation = '$indent@Lens(\n'
      '$indent  \'${tool.toolName}\',\n'
      '$indent  \'${tool.description}\',\n'
      '$indent  category: ${tool.category},\n'
      '$indent  access: ToolAccess.${tool.access},\n'
      '$indent)\n';
  
  // Insert annotation
  return content.substring(0, methodStart) +
      annotation +
      content.substring(methodStart);
}

int max(int a, int b) => a > b ? a : b;
