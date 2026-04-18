/// Annotations for generating DioLens tool definitions from service methods.
///
/// This is a stub package for OSS builds. Annotations are inert metadata.
/// The private premium plugin contains the full implementation and generator.
library lens_annotations;

/// Marks a service class for lens tool generation.
class LensService {
  const LensService({this.scope, this.group});

  /// Tool scope. If null, will be inferred from EntityService<T> supertype.
  final Scope? scope;
  
  /// Group name for consolidated tool generation. If set, all @Lens methods
  /// will be emitted as a single tool with action-based routing instead of
  /// individual tools per method.
  final String? group;
}

/// Marks a service method for tool generation.
class Lens {
  const Lens(
    this.name,
    this.description, {
    this.category,
    this.access = ToolAccess.read,
    this.priority = 0.7,
    this.isCore = false,
  });

  /// Tool name (snake_case, used in tool calls)
  final String name;

  /// Human-readable description shown to the LLM
  final String description;

  /// Tool category for grouping and discovery
  final dynamic category; // ToolCategory enum

  /// Access level: read, write, or optIn
  final ToolAccess access;

  /// Priority for tool ordering (0-1, higher = more important)
  final double priority;

  /// Core tools are always included in tool delivery
  final bool isCore;
}

/// Describes a method parameter for tool schema generation.
class Desc {
  const Desc(this.value);

  /// Human-readable parameter description
  final String value;
}

/// Marks a parameter to be skipped during tool generation.
class Skip {
  const Skip();
}

/// Scope types for lens tools.
enum Scope {
  global,
  repo,
  issuePull,
  pullRequest,
  user,
}

/// Tool access levels.
enum ToolAccess {
  /// Read-only tool (no confirmation required)
  read,

  /// Write tool (requires user confirmation)
  write,

  /// Opt-in tool (requires explicit approval, typically destructive)
  optIn,
}

/// Tool categories for organization and filtering.
enum ToolCategory {
  // Entity tools
  repository,
  issue,
  pullRequest,
  commit,
  user,
  organization,
  discussion,
  release,
  project,
  milestone,
  label,
  branches,
  wiki,
  collaborators,
  deployments,
  workflow,
  stats,
  security,
  gitDatabase,
  events,
  viewers,
  
  // Action tools
  search,
  navigation,
  notification,
  
  // Content tools
  content,
  markdown,
  code,
  
  // Meta tools
  meta,
  
  // Custom/system tools
  custom,
  system,
  bookmark,
  draft,
  history,
  deviceAndLocal,
  settings;
}

/// Interface for custom data classes used as tool parameters.
///
/// This is a stub interface for OSS builds. Types implementing this
/// interface compile but have no runtime behavior without the premium plugin.
abstract interface class ToolParam {
  /// Serialize this parameter to JSON for the tool schema.
  Map<String, dynamic> toJson();
}
