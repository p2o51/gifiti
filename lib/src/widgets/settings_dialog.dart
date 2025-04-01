import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _hasApiKey = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    print('SettingsDialog: 开始加载API Key');
    final apiKey = await GeminiService.getApiKey();
    setState(() {
      _hasApiKey = apiKey != null && apiKey.isNotEmpty;
      _isLoading = false;
      
      // If there's an API key, show a placeholder instead of the actual key
      _apiKeyController.text = _hasApiKey ? '••••••••••••••••••••••' : '';
      print('SettingsDialog: API Key 加载${_hasApiKey ? "成功" : "失败或不存在"}');
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      print('SettingsDialog: API Key 为空，不保存');
      return;
    }

    print('SettingsDialog: 开始保存 API Key');
    setState(() => _isLoading = true);
    
    try {
      await GeminiService.saveApiKey(apiKey);
      if (mounted) {
        print('SettingsDialog: API Key 保存成功');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _hasApiKey = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('SettingsDialog: API Key 保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save API Key: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteApiKey() async {
    print('SettingsDialog: 开始删除 API Key');
    setState(() => _isLoading = true);
    
    try {
      await GeminiService.deleteApiKey();
      _apiKeyController.clear();
      if (mounted) {
        print('SettingsDialog: API Key 删除成功');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _hasApiKey = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('SettingsDialog: API Key 删除失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove API Key: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gemini API Settings'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure your Gemini API key to enable automatic emoji and color suggestions based on your images.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Enter your Gemini API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can get a Gemini API key from Google AI Studio: https://aistudio.google.com',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
      actions: _isLoading
          ? null
          : [
              if (_hasApiKey)
                TextButton(
                  onPressed: _deleteApiKey,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Remove Key'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _saveApiKey,
                child: const Text('Save'),
              ),
            ],
    );
  }
} 