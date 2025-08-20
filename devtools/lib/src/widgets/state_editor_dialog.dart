import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../models/debug_data.dart';
import '../services/reactive_notifier_service.dart';

class StateEditorDialog extends StatefulWidget {
  final InstanceData instance;
  final ReactiveNotifierService service;

  const StateEditorDialog({
    super.key,
    required this.instance,
    required this.service,
  });

  @override
  State<StateEditorDialog> createState() => _StateEditorDialogState();
}

class _StateEditorDialogState extends State<StateEditorDialog> {
  late TextEditingController _controller;
  String _error = '';
  bool _isValid = true;
  Map<String, dynamic>? _parsedState;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatStateForEditing(widget.instance.state));
    _validateAndParse(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatStateForEditing(String state) {
    try {
      // Try to parse as JSON first
      final parsed = jsonDecode(state);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsed);
    } catch (e) {
      // If not JSON, check if it's a simple value
      if (state.startsWith('"') && state.endsWith('"') ||
          RegExp(r'^\d+(\.\d+)?$').hasMatch(state) ||
          state == 'true' || state == 'false' ||
          state == 'null') {
        return state;
      }
      
      // Try to create a JSON representation for complex objects
      try {
        return jsonEncode({
          'type': widget.instance.type,
          'value': state,
          'editable': false,
          'note': 'This state cannot be directly edited as JSON. Use the simplified editor below.',
        });
      } catch (e) {
        return state;
      }
    }
  }

  void _validateAndParse(String text) {
    try {
      _parsedState = jsonDecode(text);
      setState(() {
        _error = '';
        _isValid = true;
      });
    } catch (e) {
      // Check if it's a simple value
      if (_isSimpleValue(text)) {
        _parsedState = {'value': _parseSimpleValue(text)};
        setState(() {
          _error = '';
          _isValid = true;
        });
      } else {
        setState(() {
          _error = 'Invalid JSON: $e';
          _isValid = false;
        });
      }
    }
  }

  bool _isSimpleValue(String text) {
    text = text.trim();
    return text == 'true' || 
           text == 'false' || 
           text == 'null' ||
           RegExp(r'^\d+(\.\d+)?$').hasMatch(text) ||
           (text.startsWith('"') && text.endsWith('"'));
  }

  dynamic _parseSimpleValue(String text) {
    text = text.trim();
    if (text == 'true') return true;
    if (text == 'false') return false;
    if (text == 'null') return null;
    if (RegExp(r'^\d+$').hasMatch(text)) return int.parse(text);
    if (RegExp(r'^\d+\.\d+$').hasMatch(text)) return double.parse(text);
    if (text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  Future<void> _applyChanges() async {
    if (!_isValid || _parsedState == null) return;

    try {
      await widget.service.updateInstanceState(widget.instance.id, _parsedState!);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('State updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update state: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Edit State - ${widget.instance.type}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Instance ID: ${widget.instance.id.substring(0, 16)}...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'State JSON:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _controller.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy to clipboard',
                      ),
                      IconButton(
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _controller.text = data!.text!;
                            _validateAndParse(data.text!);
                          }
                        },
                        icon: const Icon(Icons.paste),
                        tooltip: 'Paste from clipboard',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isValid ? Colors.grey : Colors.red,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          hintText: 'Enter valid JSON...',
                        ),
                        onChanged: _validateAndParse,
                      ),
                    ),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValid ? _applyChanges : null,
                  child: const Text('Apply Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick state editor for common state types
class QuickStateEditor extends StatefulWidget {
  final InstanceData instance;
  final ReactiveNotifierService service;

  const QuickStateEditor({
    super.key,
    required this.instance,
    required this.service,
  });

  @override
  State<QuickStateEditor> createState() => _QuickStateEditorState();
}

class _QuickStateEditorState extends State<QuickStateEditor> {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedTemplate = 'custom';

  static const Map<String, Map<String, dynamic>> _templates = {
    'boolean': {'value': true},
    'number': {'value': 0},
    'string': {'value': 'Hello World'},
    'list': {'items': []},
    'user': {
      'id': 1,
      'name': 'John Doe',
      'email': 'john@example.com',
      'isActive': true,
    },
    'custom': {},
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    try {
      final state = jsonDecode(widget.instance.state) as Map<String, dynamic>;
      for (final entry in state.entries) {
        _controllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    } catch (e) {
      // If parsing fails, start with empty
    }
  }

  void _applyTemplate() {
    final template = _templates[_selectedTemplate]!;
    setState(() {
      _controllers.clear();
      for (final entry in template.entries) {
        _controllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    });
  }

  Map<String, dynamic> _buildState() {
    final result = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;

      // Try to parse as appropriate type
      if (text == 'true') {
        result[entry.key] = true;
      } else if (text == 'false') {
        result[entry.key] = false;
      } else if (text == 'null') {
        result[entry.key] = null;
      } else if (RegExp(r'^\d+$').hasMatch(text)) {
        result[entry.key] = int.parse(text);
      } else if (RegExp(r'^\d+\.\d+$').hasMatch(text)) {
        result[entry.key] = double.parse(text);
      } else if (text.startsWith('[') && text.endsWith(']')) {
        try {
          result[entry.key] = jsonDecode(text);
        } catch (e) {
          result[entry.key] = text;
        }
      } else if (text.startsWith('{') && text.endsWith('}')) {
        try {
          result[entry.key] = jsonDecode(text);
        } catch (e) {
          result[entry.key] = text;
        }
      } else {
        result[entry.key] = text;
      }
    }
    return result;
  }

  void _addField() {
    showDialog(
      context: context,
      builder: (context) {
        final keyController = TextEditingController();
        final valueController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Add Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Field Name',
                  hintText: 'e.g., name, age, isActive',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Field Value',
                  hintText: 'e.g., "John", 25, true, null',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim().isNotEmpty) {
                  setState(() {
                    _controllers[keyController.text.trim()] = 
                        TextEditingController(text: valueController.text);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _applyChanges() async {
    try {
      final newState = _buildState();
      await widget.service.updateInstanceState(widget.instance.id, newState);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('State updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update state: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Quick Edit - ${widget.instance.type}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Template:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedTemplate,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTemplate = value;
                      });
                      _applyTemplate();
                    }
                  },
                  items: _templates.keys.map((template) {
                    return DropdownMenuItem(
                      value: template,
                      child: Text(template),
                    );
                  }).toList(),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _controllers.isEmpty
                  ? const Center(child: Text('No fields to edit'))
                  : ListView.builder(
                      itemCount: _controllers.length,
                      itemBuilder: (context, index) {
                        final entry = _controllers.entries.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry.value,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    hintText: 'Enter value...',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    entry.value.dispose();
                                    _controllers.remove(entry.key);
                                  });
                                },
                                icon: const Icon(Icons.delete, size: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyChanges,
                  child: const Text('Apply Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}