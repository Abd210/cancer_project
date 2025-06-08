// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'pages/authentication/log_reg.dart';
import 'shared/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Custom Logger that works in all build modes
class Logger {
  static bool _loggingEnabled = false;

  // In-memory log storage (limited to last 100 entries)
  static final List<LogEntry> _logHistory = [];
  static const int _maxLogEntries = 100;

  // Enable or disable logging globally
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }

  // Get the current log history
  static List<LogEntry> getLogHistory() {
    return List.from(_logHistory.reversed);
  }

  // Clear log history
  static void clearLogHistory() {
    _logHistory.clear();
  }

  static void log(String message, {String name = 'APP'}) {
    if (!_loggingEnabled) return;

    // Add to history
    final entry = LogEntry(
      timestamp: DateTime.now(),
      category: name,
      message: message,
    );

    _logHistory.add(entry);
    if (_logHistory.length > _maxLogEntries) {
      _logHistory.removeAt(0);
    }
  }
}

// Log entry model
class LogEntry {
  final DateTime timestamp;
  final String category;
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

// Log viewer dialog
class LogViewerDialog extends StatelessWidget {
  const LogViewerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = Logger.getLogHistory();

    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Viewer',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Logger.clearLogHistory();
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Clear logs',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No logs recorded'))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${log.formattedTime} ',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextSpan(
                                  text: '[${log.category}] ',
                                  style: TextStyle(
                                    color: _getCategoryColor(log.category),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextSpan(
                                  text: log.message,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'HTTP':
        return Colors.blue;
      case 'PATIENT_API':
        return Colors.green;
      case 'DOCTOR_UI':
        return Colors.purple;
      case 'INIT':
        return Colors.orange;
      case 'UI':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

// Create a custom HTTP client for logging
class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  // Disable logging by default
  bool enableLogging = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Only log if explicitly enabled
    if (enableLogging) {
      Logger.log('REQUEST: ${request.method} ${request.url}', name: 'HTTP');
      Logger.log('HEADERS: ${request.headers}', name: 'HTTP');
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

// Global HTTP client for the application
final http.Client httpClient = LoggingClient();

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curanics Super Admin',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: LogIn(),
    );
  }
}
