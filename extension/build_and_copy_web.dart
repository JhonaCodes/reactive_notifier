import 'dart:developer';
import 'dart:io';

void main() async {
  log('🚀 Building ReactiveNotifier DevTools Extension...');

  final devtoolsDir = Directory('devtools');
  if (!devtoolsDir.existsSync()) {
    log('❌ DevTools extension directory not found');
    exit(1);
  }

  // Change to devtools directory
  final originalDir = Directory.current;
  Directory.current = devtoolsDir;

  try {
    // Get dependencies first
    log('📦 Getting dependencies...');
    final pubResult = await Process.run('flutter', ['pub', 'get']);

    if (pubResult.exitCode != 0) {
      log('❌ Pub get failed:');
      log(pubResult.stderr);
      exit(1);
    }

    // Build the web extension
    log('🏗️ Building web extension...');
    final buildResult = await Process.run(
      'flutter',
      ['build', 'web', '--dart-define=Dart2jsOptimization=O0'],
    );

    if (buildResult.exitCode != 0) {
      log('❌ Build failed:');
      log(buildResult.stderr);
      exit(1);
    }

    log('✅ Extension built successfully');
    log('📁 Extension files available at: ${Directory('build/web').absolute.path}');
    log('');
    log('🎉 ReactiveNotifier DevTools extension ready!');
    log('');
    log('To use the extension:');
    log('1. Run your Flutter app with ReactiveNotifier');
    log('2. Open Flutter DevTools');
    log('3. Look for the "ReactiveNotifier" tab');
    log('4. Use example/devtools_extension_demo.dart to test');
  } finally {
    Directory.current = originalDir;
  }
}
