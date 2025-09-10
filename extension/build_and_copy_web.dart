import 'dart:io';

void main() async {
  print('🚀 Building ReactiveNotifier DevTools Extension...');
  
  final devtoolsDir = Directory('devtools');
  if (!devtoolsDir.existsSync()) {
    print('❌ DevTools extension directory not found');
    exit(1);
  }
  
  // Change to devtools directory
  final originalDir = Directory.current;
  Directory.current = devtoolsDir;
  
  try {
    // Get dependencies first
    print('📦 Getting dependencies...');
    final pubResult = await Process.run('flutter', ['pub', 'get']);
    
    if (pubResult.exitCode != 0) {
      print('❌ Pub get failed:');
      print(pubResult.stderr);
      exit(1);
    }
    
    // Build the web extension
    print('🏗️ Building web extension...');
    final buildResult = await Process.run(
      'flutter',
      ['build', 'web', '--dart-define=Dart2jsOptimization=O0'],
    );
    
    if (buildResult.exitCode != 0) {
      print('❌ Build failed:');
      print(buildResult.stderr);
      exit(1);
    }
    
    print('✅ Extension built successfully');
    print('📁 Extension files available at: ${Directory('build/web').absolute.path}');
    print('');
    print('🎉 ReactiveNotifier DevTools extension ready!');
    print('');
    print('To use the extension:');
    print('1. Run your Flutter app with ReactiveNotifier');
    print('2. Open Flutter DevTools');
    print('3. Look for the "ReactiveNotifier" tab');
    print('4. Use example/devtools_extension_demo.dart to test');
    
  } finally {
    Directory.current = originalDir;
  }
}

