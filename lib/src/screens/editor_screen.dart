import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/editor_selector.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
  double _density = 0.0;
  double _size = 0.0;

  // 添加一个 GlobalKey 用于 RepaintBoundary
  final GlobalKey _boundaryKey = GlobalKey();

  // 添加随机 emoji 列表
  final List<String> _defaultEmojis = ['🌸', '🌺', '🌹', '🌷', '🌼', '🌻', '🍀', '🌿', '🌱', '🌳', '🌴', '🌵', '🍄', '🦋', '🐝', '⭐️', '✨', '💫', '🌙', '☁️'];
  
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // 添加一个空的 bottomNavigationBar 来填充底部导航栏区域
        bottomNavigationBar: Container(
          color: Theme.of(context).colorScheme.secondaryContainer, // 与选择器相同的浅紫色
          height: MediaQuery.of(context).padding.bottom, // 只占用安全区域的高度
        ),
        body: Stack(
          children: [
            // 主要内容区域
            SafeArea(
              bottom: false, // 底部不需要 SafeArea，因为 EditorSelector 会处理
              child: Column(
                children: [
                  // 顶部导航栏
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
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
                  const SizedBox(height: 8),
                  // 主要图片显示区域
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final containerSize = screenWidth * 0.95;
                      return Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: Container(
                              width: containerSize,
                              height: containerSize,
                              decoration: BoxDecoration(
                                color: ColorScheme.fromSeed(seedColor: _selectedColor).secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                            child: Image.file(
                                              File(widget.selectedImage!.path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  // 操作按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Generate'),
                          style: FilledButton.styleFrom(
                                  minimumSize: const Size(100, 56),
                                  maximumSize: const Size(200, 56),
                              ),
                          onPressed: _generateRandomParameters,
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Save'),
                          style: FilledButton.styleFrom(
                                  minimumSize: const Size(100, 56),
                                  maximumSize: const Size(200, 56),
                              ),
                          onPressed: () async {
                            await _saveImage();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 底部选择器
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false, // 顶部不需要 SafeArea
                child: EditorSelector(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
