import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/editor_selector.dart';
import '../widgets/settings_dialog.dart';
import '../services/gemini_service.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class EditorScreen extends StatefulWidget {
  final XFile? selectedImage;
  
  const EditorScreen({
    super.key,
    this.selectedImage,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  EditorMode _selectedMode = EditorMode.emojis;
  Color _selectedColor = Colors.blue;
  String _selectedEmoji = '';
  double _density = 2.0;
  double _size = 1.0;
  bool _isAnalyzingImage = false;

  // 添加一个 GlobalKey 用于 RepaintBoundary
  final GlobalKey _boundaryKey = GlobalKey();
  // ScrollController for small screens
  final ScrollController _scrollController = ScrollController();

  // 添加随机 emoji 列表
  final List<String> _defaultEmojis = ['🌸', '🌺', '🌹', '🌷', '🌼', '🌻', '🍀', '🌿', '🌱', '🌳', '🌴', '🌵', '🍄', '🦋', '🐝', '⭐️', '✨', '💫', '🌙', '☁️'];
  
  @override
  void initState() {
    super.initState();
    _analyzeImageWithGemini();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  // Analyze the selected image using Gemini API
  Future<void> _analyzeImageWithGemini() async {
    // Only proceed if there's a selected image and Gemini API key is configured
    if (widget.selectedImage == null) {
      print('EditorScreen: 没有选择图片，不调用Gemini API');
      return;
    }
    
    final hasApiKey = await GeminiService.hasApiKey();
    if (!hasApiKey) {
      print('EditorScreen: 未配置Gemini API Key，跳过图片分析');
      return;
    }
    
    try {
      // 设置正在分析状态
      if (mounted) {
        setState(() {
          _isAnalyzingImage = true;
        });
      }
      
      print('EditorScreen: 开始读取图片文件: ${widget.selectedImage!.path}');
      // Read the image file
      final file = File(widget.selectedImage!.path);
      final imageBytes = await file.readAsBytes();
      print('EditorScreen: 图片文件读取成功，大小: ${imageBytes.length} 字节');
      
      // Call Gemini API to analyze the image
      print('EditorScreen: 调用Gemini API分析图片');
      final result = await GeminiService.analyzeImage(imageBytes);
      
      if (result != null && mounted) {
        print('EditorScreen: Gemini API返回结果: $result');
        
        // 检查是否有错误
        if (result.containsKey('error')) {
          setState(() {
            _isAnalyzingImage = false;
          });
          
          // 显示错误消息
          if (mounted) {
            // 特别处理网络相关错误
            if (result['error'] == 'network_error' || 
                result['error'] == 'connection_error') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? '网络连接问题'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: '重试',
                    textColor: Colors.white,
                    onPressed: _reimagineWithGemini,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? '未知错误'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: '设置',
                    onPressed: _showSettingsDialog,
                  ),
                ),
              );
            }
          }
          return;
        }
        
        setState(() {
          // Update emoji if provided
          if (result['emojis'] != null && result['emojis'].isNotEmpty) {
            _selectedEmoji = result['emojis'];
            print('EditorScreen: 设置Emoji为: $_selectedEmoji');
          } else {
            print('EditorScreen: Gemini未返回有效Emoji');
          }
          
          // Update color if provided
          if (result['color'] != null) {
            _selectedColor = result['color'];
            print('EditorScreen: 设置颜色为: $_selectedColor');
          } else {
            print('EditorScreen: Gemini未返回有效颜色');
          }
          
          _isAnalyzingImage = false;
        });
      } else {
        print('EditorScreen: Gemini API分析未返回结果');
        if (mounted) {
          setState(() {
            _isAnalyzingImage = false;
          });
          
          // 显示错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('无法获取AI分析结果，可能是网络连接问题'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '重试',
                onPressed: _reimagineWithGemini,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('EditorScreen: 图片分析过程发生错误: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
        
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分析图片时出错: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '重试',
              onPressed: _reimagineWithGemini,
            ),
          ),
        );
      }
    }
  }

  // 添加随机生成参数的方法
  void _generateRandomParameters() {
    final random = Random();
    
    setState(() {
      // 随机选择1-3个emoji组合
      final emojiCount = random.nextInt(3) + 1;
      final selectedEmojis = List.generate(
        emojiCount,
        (_) => _defaultEmojis[random.nextInt(_defaultEmojis.length)]
      );
      _selectedEmoji = selectedEmojis.join();
      
      // 随机颜色
      _selectedColor = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      );
      
      // 随机密度 (0.0-3.0)
      _density = random.nextDouble() * 3.0;
      
      // 随机大小 (0.0-5.0)
      _size = random.nextDouble() * 5.0;
    });
  }

  // 重新通过Gemini API分析图片
  Future<void> _reimagineWithGemini() async {
    if (widget.selectedImage == null) {
      print('EditorScreen: 没有选择图片，无法重新分析');
      return;
    }
    
    final hasApiKey = await GeminiService.hasApiKey();
    if (!hasApiKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在设置中配置Gemini API密钥'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('EditorScreen: 未配置Gemini API Key，无法重新分析');
      return;
    }
    
    // 检查网络连接
    if (!await _checkNetworkPermission()) {
      return;
    }
    
    // 开始分析
    _analyzeImageWithGemini();
  }
  
  // 检查网络权限和连接
  Future<bool> _checkNetworkPermission() async {
    try {
      // 简单的网络连接测试
      print('EditorScreen: 检查网络权限...');
      final result = await Future.wait([
        GeminiService.ping(),
        Future.delayed(const Duration(seconds: 1)), // 确保UI有足够时间响应
      ]);
      
      final pingSuccess = result[0] as bool;
      if (!pingSuccess && mounted) {
        print('EditorScreen: 网络检查失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法连接到网络，请检查网络设置和应用权限'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _reimagineWithGemini,
            ),
          ),
        );
        return false;
      }
      
      return true;
    } catch (e) {
      print('EditorScreen: 网络权限检查失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('网络连接检查失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  void _handleColorChanged(Color color) {
    setState(() {
      _selectedColor = color;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleEmojiChanged(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleDensityChanged(double density) {
    setState(() {
      _density = density;
    });
    // TODO: 更新图片显示区域的内容
  }

  void _handleSizeChanged(double size) {
    setState(() {
      _size = size;
    });
    // TODO: 更新图片显示区域的内容
  }

  List<Widget> _generateEmojiGrid(double containerSize) {
    if (_selectedEmoji.isEmpty) return [];

    final emojis = <Widget>[];
    final adjustedDensity = _density + 2;
    final cols = (adjustedDensity * 2).floor();
    final rows = adjustedDensity.floor();
    final emojiArray = _selectedEmoji.characters.toList();
    
    if (emojiArray.isEmpty) return emojis;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final isOddCol = col % 2 == 1;
        
        // 计算位置
        final x = (col * 100.0) / cols;
        final y = (row * 100.0) / rows + (isOddCol ? 50.0 / rows : 0);
        
        // 选择 emoji（循环使用输入的emoji）
        final index = col % emojiArray.length;
        final currentEmoji = emojiArray[index];

        emojis.add(
          Positioned(
            left: x / 100 * containerSize,
            top: y / 100 * containerSize,
            child: Transform.translate(
              offset: const Offset(-0.5, -0.5),
              child: Text(
                currentEmoji,
                style: TextStyle(
                  fontSize: 24 + _size * 8,
                  color: ColorScheme.fromSeed(seedColor: _selectedColor).primary,
                  fontFamily: 'NotoEmoji',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    return emojis;
  }

  Future<String?> _saveImage() async {
    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final double pixelRatio = 6;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // Web platform - trigger a download
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'gifiti_art_${DateTime.now().millisecondsSinceEpoch}.png')
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Downloaded image'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      } else {
        // Mobile platforms
        // 获取临时目录
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
        await tempFile.writeAsBytes(bytes);

        if (Platform.isIOS) {
          final result = await ImageGallerySaver.saveFile(tempFile.path);
          await tempFile.delete();
          
          if (result['isSuccess']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Saved to Photos'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return tempFile.path;
          } else {
            throw Exception('Failed to save to gallery');
          }
        } else {
          final result = await ImageGallerySaver.saveFile(tempFile.path);
          await tempFile.delete();
          
          if (result['isSuccess']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Saved to Gallery'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return result['filePath'];
          } else {
            throw Exception('Failed to save to gallery');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
      return null;
    }
  }
  
  // Editor canvas widget that's used in both layouts
  Widget _buildEditorCanvas(double containerSize) {
    return Stack(
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Remove the box shadow
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: containerSize,
                height: containerSize,
                color: ColorScheme.fromSeed(seedColor: _selectedColor).secondaryContainer,
                child: Stack(
                  children: [
                    // Emoji 层放在底部
                    ...(_generateEmojiGrid(containerSize)),
                    // 图片放在最上层，添加内边距和圆角
                    if (widget.selectedImage != null)
                      Positioned.fill(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: containerSize - 128, // 考虑左右边距
                              maxHeight: containerSize - 128, // 考虑上下边距
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildImageWidget(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Loading indicator overlay
        if (_isAnalyzingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'AI Analyzing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Helper method to handle image display for both web and mobile
  Widget _buildImageWidget() {
    if (widget.selectedImage == null) {
      return const SizedBox.shrink();
    }
    
    if (kIsWeb) {
      // For web, XFile.path is actually a object URL
      return Image.network(
        widget.selectedImage!.path,
        fit: BoxFit.cover,
      );
    } else {
      // For mobile, use File
      return Image.file(
        File(widget.selectedImage!.path),
        fit: BoxFit.cover,
      );
    }
  }
  
  // Action buttons widget that's used in both layouts
  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      alignment: WrapAlignment.start,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.shuffle),
          label: const Text('Shuffle'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 48),
            maximumSize: const Size(200, 48),
          ),
          onPressed: _generateRandomParameters,
        ),
        if (widget.selectedImage != null)
          FilledButton.icon(
            icon: _isAnalyzingImage 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    )
                  ) 
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzingImage ? 'Analyzing...' : 'Reimagine'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(100, 48),
              maximumSize: const Size(200, 48),
              backgroundColor: _isAnalyzingImage 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : null,
            ),
            onPressed: _isAnalyzingImage ? null : _reimagineWithGemini,
          ),
        FilledButton.icon(
          icon: const Icon(Icons.download_rounded),
          label: const Text('Save'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 48),
            maximumSize: const Size(200, 48),
          ),
          onPressed: () async {
            await _saveImage();
          },
        ),
      ],
    );
  }
  
  // Selector widget used in both layouts
  Widget _buildSelector() {
    return EditorSelector(
      selectedMode: _selectedMode,
      onModeChanged: (mode) => setState(() => _selectedMode = mode),
      onColorChanged: _handleColorChanged,
      onEmojiChanged: _handleEmojiChanged,
      onDensityChanged: _handleDensityChanged,
      onSizeChanged: _handleSizeChanged,
      initialColor: _selectedColor,
      initialEmoji: _selectedEmoji,
      initialDensity: _density,
      initialSize: _size,
    );
  }

  // Mobile layout with scrolling content and bottom selector
  Widget _buildMobileLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerSize = screenWidth * 0.95;
    
    return Stack(
      children: [
        // 固定的顶部导航栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Theme.of(context).colorScheme.background,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Add settings button
                IconButton.filledTonal(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettingsDialog,
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    try {
                      // 直接获取图片数据用于分享，使用高分辨率
                      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                      final double pixelRatio = 6; // 使用高分辨率
                      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
                      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      final bytes = byteData!.buffer.asUint8List();

                      // 创建临时文件用于分享
                      final tempDir = await getTemporaryDirectory();
                      final shareFile = File('${tempDir.path}/share_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
                      await shareFile.writeAsBytes(bytes);
                      
                      // 分享文件
                      await Share.shareXFiles([XFile(shareFile.path)]);
                      
                      // 清理临时文件
                      await shareFile.delete();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share image: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Scrollable main content - 添加顶部padding腾出AppBar空间
        Positioned.fill(
          top: 56, // 为顶部导航栏留出空间
          bottom: MediaQuery.of(context).size.height * 0.25, // Reserve space for the selector
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Canvas
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildEditorCanvas(containerSize),
                  ),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildActionButtons(),
                ),
                // Add extra space at the bottom to ensure content doesn't get hidden behind the selector
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
        
        // Bottom selector
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false, // 顶部不需要 SafeArea
            child: _buildSelector(),
          ),
        ),
      ],
    );
  }
  
  // Desktop/tablet layout with side-by-side content
  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerSize = screenWidth * 0.5; // 50% of the screen width
    
    return Column(
      children: [
        // 固定的顶部导航栏
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.background,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Add settings button
              IconButton.filledTonal(
                icon: const Icon(Icons.settings),
                onPressed: _showSettingsDialog,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  try {
                    // 直接获取图片数据用于分享，使用高分辨率
                    final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                    final double pixelRatio = 6; // 使用高分辨率
                    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
                    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                    final bytes = byteData!.buffer.asUint8List();

                    // 创建临时文件用于分享
                    final tempDir = await getTemporaryDirectory();
                    final shareFile = File('${tempDir.path}/share_emoji_art_${DateTime.now().millisecondsSinceEpoch}.png');
                    await shareFile.writeAsBytes(bytes);
                    
                    // 分享文件
                    await Share.shareXFiles([XFile(shareFile.path)]);
                    
                    // 清理临时文件
                    await shareFile.delete();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to share image: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        
        // 内容区域
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Editor Canvas and action buttons below it
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片容器，添加左边距使其与按钮对齐
                      Padding(
                        padding: EdgeInsets.only(left: 0), // 调整此值以匹配按钮的位置
                        child: _buildEditorCanvas(containerSize),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons 左对齐
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              
              // Right side - All Controls on a single page
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title removed
                          // All selectors shown at once instead of tabs
                          // Color selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Color',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ColorSelector(
                            onColorChanged: _handleColorChanged,
                            initialColor: _selectedColor,
                          ),
                          const SizedBox(height: 16),
                          
                          // Emoji selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Emojis',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          EmojiSelector(
                            onEmojiChanged: _handleEmojiChanged,
                            initialEmoji: _selectedEmoji,
                          ),
                          const SizedBox(height: 16),
                          
                          // Layout selector
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Layout',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          LayoutSelector(
                            onDensityChanged: _handleDensityChanged,
                            onSizeChanged: _handleSizeChanged,
                            initialDensity: _density,
                            initialSize: _size,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          // If the pop was successful, no need to do anything
          return;
        }
        // Navigate back manually if needed
        if (mounted && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        // Add an empty bottomNavigationBar to fill the bottom navigation bar area for mobile
        bottomNavigationBar: isLargeScreen
            ? null
            : Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                height: MediaQuery.of(context).padding.bottom,
              ),
        body: SafeArea(
          bottom: isLargeScreen, // Only apply bottom SafeArea on desktop layout
          child: isLargeScreen
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }
}
