import 'package:flutter/foundation.dart';

/// Enables graph-node debugging only in debug builds and only when explicitly
/// requested with --dart-define=SHOW_PATH_PLANNING_DEBUG_NODES=true.
const showPathPlanningDebugNodes = kDebugMode &&
    bool.fromEnvironment(
      'SHOW_PATH_PLANNING_DEBUG_NODES',
      defaultValue: false,
    );
