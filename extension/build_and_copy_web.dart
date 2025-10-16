import 'dart:developer';
import 'dart:io';

void main() async {
  log('🚀 Building ReactiveNotifier DevTools Extension...');
  log('');

  // Check devtools directory exists
  final devtoolsDir = Directory('devtools');
  if (!devtoolsDir.existsSync()) {
    log('❌ DevTools extension directory not found at: ${devtoolsDir.absolute.path}');
    exit(1);
  }

  // Change to devtools directory for building
  final originalDir = Directory.current;
  Directory.current = devtoolsDir;

  try {
    // Step 1: Get dependencies
    log('📦 Step 1/4: Getting dependencies...');
    final pubResult = await Process.run('flutter', ['pub', 'get']);

    if (pubResult.exitCode != 0) {
      log('❌ Pub get failed:');
      log(pubResult.stderr.toString());
      exit(1);
    }
    log('✅ Dependencies installed');
    log('');

    // Step 2: Build the web extension
    log('🏗️  Step 2/4: Building web extension...');
    final buildResult = await Process.run(
      'flutter',
      [
        'build',
        'web',
        '--release',
        '--web-renderer=canvaskit',
      ],
    );

    if (buildResult.exitCode != 0) {
      log('❌ Build failed:');
      log(buildResult.stderr.toString());
      exit(1);
    }
    log('✅ Web extension built successfully');
    log('');

    // Step 3: Copy files to extension location
    log('📂 Step 3/4: Copying files to extension directory...');

    // Go back to original directory
    Directory.current = originalDir;

    // Read version from pubspec
    final pubspecFile = File('pubspec.yaml');
    final pubspecContent = await pubspecFile.readAsString();
    final versionMatch = RegExp(r'version:\s*(\d+\.\d+\.\d+)').firstMatch(pubspecContent);
    final version = versionMatch?.group(1) ?? '2.13.0';

    // Create target directory (root devtools_extensions/)
    final targetDir = Directory('devtools_extensions/reactive_notifier_$version');
    if (targetDir.existsSync()) {
      log('🗑️  Cleaning existing extension directory...');
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    // Copy build/web contents to target
    final buildWebDir = Directory('extension/devtools/build/web');
    if (!buildWebDir.existsSync()) {
      log('❌ Build output not found at: ${buildWebDir.absolute.path}');
      exit(1);
    }

    log('   Copying files from ${buildWebDir.path} to ${targetDir.path}');
    await _copyDirectory(buildWebDir, targetDir);

    // Copy config.yaml
    final configSource = File('extension/devtools/config.yaml');
    final configTarget = File('${targetDir.path}/config.yaml');
    if (configSource.existsSync()) {
      await configSource.copy(configTarget.path);
      log('   ✓ config.yaml copied');
    }

    log('✅ Files copied successfully');
    log('');

    // Step 4: Verify extension structure
    log('🔍 Step 4/4: Verifying extension structure...');
    final requiredFiles = [
      'index.html',
      'main.dart.js',
      'flutter.js',
      'config.yaml',
    ];

    bool allFilesExist = true;
    for (final file in requiredFiles) {
      final filePath = File('${targetDir.path}/$file');
      if (filePath.existsSync()) {
        final size = await filePath.length();
        log('   ✓ $file (${_formatBytes(size)})');
      } else {
        log('   ✗ $file - MISSING!');
        allFilesExist = false;
      }
    }

    if (!allFilesExist) {
      log('');
      log('❌ Extension verification failed - some files are missing!');
      exit(1);
    }

    log('✅ Extension structure verified');
    log('');

    // Success summary
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('🎉 ReactiveNotifier DevTools Extension Ready!');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    log('');
    log('📦 Version: $version');
    log('📁 Location: ${targetDir.path}');
    log('');
    log('To use the extension:');
    log('1. Add to your pubspec.yaml:');
    log('   dependencies:');
    log('     reactive_notifier:');
    log('       path: ../path/to/reactive_notifier');
    log('');
    log('2. Initialize in your main.dart:');
    log('   import \'package:reactive_notifier/reactive_notifier.dart\';');
    log('   ');
    log('   void main() {');
    log('     initializeReactiveNotifierDevTools();');
    log('     runApp(MyApp());');
    log('   }');
    log('');
    log('3. Run your app in debug mode');
    log('4. Open Flutter DevTools');
    log('5. Look for the "ReactiveNotifier" tab');
    log('');
    log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } catch (e, stackTrace) {
    log('');
    log('❌ Error occurred: $e');
    log('Stack trace: $stackTrace');
    exit(1);
  } finally {
    // Restore original directory
    Directory.current = originalDir;
  }
}

/// Copy directory recursively
Future<void> _copyDirectory(Directory source, Directory target) async {
  await target.create(recursive: true);

  await for (final entity in source.list()) {
    final name = entity.path.split('/').last;

    if (entity is File) {
      await entity.copy('${target.path}/$name');
    } else if (entity is Directory) {
      await _copyDirectory(
        entity,
        Directory('${target.path}/$name'),
      );
    }
  }
}

/// Format bytes to human-readable format
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
