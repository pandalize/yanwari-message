import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ツリーマップノード（階層構造を表現）
class TreemapNode {
  final String id;
  final String name;
  final double value;
  final List<TreemapNode>? children;
  final Map<String, dynamic>? data; // 追加データ（メッセージなど）
  final Color? color;
  final int level;
  
  TreemapNode({
    required this.id,
    required this.name,
    required this.value,
    this.children,
    this.data,
    this.color,
    required this.level,
  });
}

/// ツリーマップの矩形情報
class TreemapRect {
  final double x;
  final double y;
  final double width;
  final double height;
  final TreemapNode node;
  final Color color;
  final String label;
  final bool isUnread;
  final int? rating;
  final String? senderName;
  
  TreemapRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.node,
    required this.color,
    required this.label,
    this.isUnread = false,
    this.rating,
    this.senderName,
  });
}

/// ツリーマップウィジェット
class TreemapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final double width;
  final double height;
  final Function(Map<String, dynamic> message)? onMessageTap;
  
  const TreemapWidget({
    Key? key,
    required this.messages,
    this.width = 300,
    this.height = 200,
    this.onMessageTap,
  }) : super(key: key);

  @override
  State<TreemapWidget> createState() => _TreemapWidgetState();
}

class _TreemapWidgetState extends State<TreemapWidget> {
  List<TreemapRect> _rectangles = [];
  TreemapRect? _selectedRect;

  @override
  void initState() {
    super.initState();
    _generateTreemapData();
  }

  @override
  void didUpdateWidget(TreemapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages || 
        oldWidget.width != widget.width || 
        oldWidget.height != widget.height) {
      _generateTreemapData();
    }
  }

  /// メッセージを階層構造にグループ化
  TreemapNode _groupMessages() {
    if (widget.messages.isEmpty) {
      return TreemapNode(id: 'root', name: 'root', value: 0, level: 0);
    }
    
    // 送信者別にグループ化
    Map<String, List<Map<String, dynamic>>> senderGroups = {};
    
    for (var message in widget.messages) {
      final senderName = message['sender']?['name'] ?? 
                        message['sender']?['email'] ?? 
                        message['from']?['name'] ?? 
                        message['from']?['email'] ?? 
                        message['fromEmail'] ?? 
                        message['senderName'] ?? 
                        message['senderEmail'] ?? '送信者不明';
      
      if (!senderGroups.containsKey(senderName)) {
        senderGroups[senderName] = [];
      }
      senderGroups[senderName]!.add(message);
    }
    
    List<TreemapNode> senderNodes = [];
    
    // 送信者ごとに評価別グループ化
    senderGroups.forEach((senderName, messages) {
      Map<String, List<Map<String, dynamic>>> ratingGroups = {};
      
      // 評価別にグループ化（Web版と同じロジック）
      for (var message in messages) {
        String ratingKey;
        // Web版と同じ条件: statusで判定、なければreadAtで判定
        if (message['status'] != 'read' || message['readAt'] == null) {
          ratingKey = '未読';
        } else if (message['rating'] == null || message['rating'] == 0) {
          ratingKey = '未評価';
        } else {
          ratingKey = '★${message['rating']}';
        }
        
        if (!ratingGroups.containsKey(ratingKey)) {
          ratingGroups[ratingKey] = [];
        }
        ratingGroups[ratingKey]!.add(message);
      }
      
      // 評価グループのノードを作成
      List<TreemapNode> ratingNodes = [];
      final ratingOrder = ['未読', '未評価', '★5', '★4', '★3', '★2', '★1'];
      
      for (String ratingName in ratingOrder) {
        if (!ratingGroups.containsKey(ratingName)) continue;
        
        List<Map<String, dynamic>> ratingMessages = ratingGroups[ratingName]!;
        double ratingWeight = _getRatingWeight(ratingName);
        
        // 個別メッセージのノードを作成
        List<TreemapNode> messageNodes = ratingMessages.map((message) {
          return TreemapNode(
            id: message['_id'] ?? message['id'] ?? '',
            name: _getMessagePreview(message),
            value: ratingWeight,
            data: message,
            color: _getMessageColor(message),
            level: 3,
          );
        }).toList();
        
        ratingNodes.add(TreemapNode(
          id: '${senderName}-${ratingName}',
          name: ratingName,
          value: ratingMessages.length * ratingWeight,
          children: messageNodes,
          color: _getRatingColor(ratingName),
          level: 2,
        ));
      }
      
      // 送信者ノードの総値を計算
      double senderTotalValue = ratingNodes.fold(0.0, (sum, node) => sum + node.value);
      
      senderNodes.add(TreemapNode(
        id: senderName,
        name: senderName,
        value: senderTotalValue,
        children: ratingNodes,
        color: _getSenderColor(senderName),
        level: 1,
      ));
    });
    
    // 送信者を優先順位でソート
    senderNodes.sort((a, b) => _getSenderPriority(b) - _getSenderPriority(a));
    
    return TreemapNode(
      id: 'root',
      name: 'メッセージ',
      value: senderNodes.fold(0.0, (sum, node) => sum + node.value),
      children: senderNodes,
      level: 0,
    );
  }

  /// 評価の重み付けを取得（Web版と同じ比率）
  double _getRatingWeight(String ratingName) {
    switch (ratingName) {
      case '未読': return 4.0;    // Web版と同じ
      case '未評価': return 4.0;  // Web版と同じ
      case '★5': return 5.0;      // Web版と同じ
      case '★4': return 4.0;      // Web版と同じ
      case '★3': return 3.0;      // Web版と同じ
      case '★2': return 2.0;      // Web版と同じ
      case '★1': return 1.0;      // Web版と同じ
      default: return 1.0;
    }
  }

  /// 送信者の優先順位を取得
  int _getSenderPriority(TreemapNode sender) {
    final children = sender.children ?? [];
    if (children.any((c) => c.name == '未読')) return 10;
    if (children.any((c) => c.name == '未評価')) return 8;
    if (children.any((c) => c.name == '★5')) return 6;
    if (children.any((c) => c.name == '★4')) return 5;
    if (children.any((c) => c.name == '★3')) return 4;
    if (children.any((c) => c.name == '★2')) return 3;
    if (children.any((c) => c.name == '★1')) return 2;
    return 1;
  }

  /// メッセージプレビューを取得
  String _getMessagePreview(Map<String, dynamic> message) {
    final text = message['transformedText'] ?? 
                message['finalText'] ?? 
                message['originalText'] ?? '';
    if (text.isEmpty) return '';
    return text.length > 15 ? '${text.substring(0, 15)}…' : text;
  }

  /// 送信者の色を生成（Web版と同じアルゴリズム）
  Color _getSenderColor(String senderName) {
    // Web版と同じハッシュ計算
    int hash = 0;
    for (int i = 0; i < senderName.length; i++) {
      hash = ((hash << 5) - hash) + senderName.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    
    final hue = hash.abs() % 360;
    // HSL(hue, 65%, 75%) をHSLColorで生成
    final hslColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.65, 0.75);
    return hslColor.toColor();
  }

  /// 評価の色を取得（Web版と同じ色）
  Color _getRatingColor(String ratingName) {
    switch (ratingName) {
      case '未読': return const Color(0xFF3B82F6);   // #3b82f6
      case '未評価': return const Color(0xFF9CA3AF); // #9ca3af
      case '★1': return const Color(0xFFEF4444);     // #ef4444
      case '★2': return const Color(0xFFF97316);     // #f97316
      case '★3': return const Color(0xFFEAB308);     // #eab308
      case '★4': return const Color(0xFF84CC16);     // #84cc16
      case '★5': return const Color(0xFF22C55E);     // #22c55e
      default: return const Color(0xFF6B7280);       // #6b7280
    }
  }

  /// メッセージの色を取得（Web版と同じ色）
  Color _getMessageColor(Map<String, dynamic> message) {
    // 未読メッセージは特別な色（目立つ青色）
    if (message['readAt'] == null || message['status'] != 'read') {
      return const Color(0xFFDBEAFE); // #dbeafe
    }
    
    // 評価に基づく色分け（薄い色合い）
    final rating = message['rating'] as int?;
    if (rating == null || rating == 0) {
      return const Color(0xFFF3F4F6); // #f3f4f6 未評価は薄い灰色
    }
    
    switch (rating) {
      case 1: return const Color(0xFF87CEFA);  // #87cefa
      case 2: return const Color(0xFFB0E0E6);  // #b0e0e6
      case 3: return const Color(0xFFFEF3C7);  // #fef3c7
      case 4: return const Color(0xFFFFB6C1);  // #ffb6c1
      case 5: return const Color(0xFFFF7F50);  // #ff7f50
      default: return const Color(0xFFF3F4F6); // #f3f4f6
    }
  }

  /// ツリーマップデータを生成
  void _generateTreemapData() {
    if (widget.messages.isEmpty) {
      setState(() => _rectangles = []);
      return;
    }

    final hierarchyData = _groupMessages();
    final rectangles = _calculateTreemap(hierarchyData);
    
    setState(() => _rectangles = rectangles);
  }

  /// ツリーマップの矩形を計算
  List<TreemapRect> _calculateTreemap(TreemapNode rootNode) {
    final containerWidth = widget.width - 20;
    final containerHeight = widget.height - 20;
    
    return _layoutHierarchy(rootNode, 10, 10, containerWidth, containerHeight);
  }

  /// 階層構造を再帰的にレイアウト
  List<TreemapRect> _layoutHierarchy(TreemapNode node, double x, double y, double width, double height) {
    List<TreemapRect> result = [];
    
    if (node.children == null || node.children!.isEmpty) {
      // 葉ノード（個別メッセージ）
      final message = node.data;
      result.add(TreemapRect(
        x: x,
        y: y,
        width: width,
        height: height,
        node: node,
        color: node.color ?? _getMessageColor(message ?? {}),
        label: node.name,
        isUnread: message?['readAt'] == null,
        rating: message?['rating'] as int?,
        senderName: message?['senderName'] ?? message?['senderEmail'],
      ));
      return result;
    }
    
    // 子ノードの総値を計算
    double totalValue = node.children!.fold(0.0, (sum, child) => sum + child.value);
    
    // Squarifyアルゴリズムで矩形を計算
    List<_Rectangle> rectangles = _squarify(node.children!, x, y, width, height, totalValue);
    
    for (int i = 0; i < rectangles.length; i++) {
      final rect = rectangles[i];
      final child = node.children![i];
      
      if (child.children != null && child.children!.isNotEmpty) {
        // 子ノードを再帰的にレイアウト
        final childRects = _layoutHierarchy(
          child, 
          rect.x + 2, 
          rect.y + 2, 
          rect.width - 4, 
          rect.height - 4
        );
        result.addAll(childRects);
      } else {
        // 葉ノード
        final message = child.data;
        result.add(TreemapRect(
          x: rect.x,
          y: rect.y,
          width: rect.width,
          height: rect.height,
          node: child,
          color: child.color ?? _getMessageColor(message ?? {}),
          label: child.name,
          isUnread: message?['readAt'] == null,
          rating: message?['rating'] as int?,
          senderName: message?['senderName'] ?? message?['senderEmail'],
        ));
      }
    }
    
    return result;
  }

  /// Squarifyアルゴリズム（Web版と同じ実装）
  List<_Rectangle> _squarify(List<TreemapNode> children, double x, double y, double width, double height, double totalValue) {
    if (children.isEmpty) return [];
    
    List<_Rectangle> rectangles = [];
    double totalArea = width * height;
    
    double currentX = x;
    double currentY = y;
    double remainingWidth = width;
    double remainingHeight = height;
    
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final childValue = child.value;
      final areaRatio = childValue / totalValue;
      final targetArea = areaRatio * totalArea;
      
      double rectWidth, rectHeight;
      
      if (i == children.length - 1) {
        // 最後の要素は残り全部
        rectWidth = remainingWidth;
        rectHeight = remainingHeight;
      } else {
        // 長い辺に沿って分割（Web版と同じアルゴリズム）
        if (remainingWidth >= remainingHeight) {
          // 横に分割
          rectWidth = targetArea / remainingHeight;
          rectHeight = remainingHeight;
          rectWidth = math.min(rectWidth, remainingWidth);
        } else {
          // 縦に分割
          rectHeight = targetArea / remainingWidth;
          rectWidth = remainingWidth;
          rectHeight = math.min(rectHeight, remainingHeight);
        }
        
        // 最小サイズ保証（Web版と同じ）
        rectWidth = math.max(rectWidth, 30);
        rectHeight = math.max(rectHeight, 25);
      }
      
      rectangles.add(_Rectangle(
        x: currentX,
        y: currentY,
        width: rectWidth,
        height: rectHeight,
      ));
      
      // 次の位置を計算
      if (remainingWidth >= remainingHeight) {
        currentX += rectWidth;
        remainingWidth -= rectWidth;
      } else {
        currentY += rectHeight;
        remainingHeight -= rectHeight;
      }
    }
    
    return rectangles;
  }

  /// テキストの色を取得（背景色に応じて）
  Color _getTextColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// メッセージを複数行に分割
  List<String> _getMessageLines(String text, double width, double height) {
    if (text.isEmpty) return [''];
    
    int charsPerLine = _getCharsPerLine(width);
    int maxLines = _getMaxLines(height);
    int totalMaxChars = charsPerLine * maxLines;
    
    String displayText = text.length > totalMaxChars 
        ? '${text.substring(0, totalMaxChars - 1)}…'
        : text;
    
    List<String> lines = [];
    String remainingText = displayText;
    
    for (int i = 0; i < maxLines && remainingText.isNotEmpty; i++) {
      String lineText = remainingText.substring(0, math.min(charsPerLine, remainingText.length));
      lines.add(lineText);
      remainingText = remainingText.substring(lineText.length);
    }
    
    return lines.isNotEmpty ? lines : [''];
  }

  /// 枠の幅による1行あたりの文字数
  int _getCharsPerLine(double width) {
    if (width >= 120) return 12;
    if (width >= 80) return 8;
    if (width >= 60) return 6;
    if (width >= 40) return 4;
    return 3;
  }

  /// 枠の高さによる最大行数
  int _getMaxLines(double height) {
    if (height >= 80) return 3;
    if (height >= 60) return 2;
    return 1;
  }

  /// メッセージフォントサイズを取得
  double _getMessageFontSize(double width, double height) {
    return math.max(math.min(math.min(width / 8, height / 5), 10), 7);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_graph,
                size: 64,
                color: Color(0xFFE5E7EB),
              ),
              SizedBox(height: 16),
              Text(
                'ツリーマップ表示用の\nメッセージがありません',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          final position = details.localPosition;
          for (final rect in _rectangles) {
            if (position.dx >= rect.x && 
                position.dx <= rect.x + rect.width &&
                position.dy >= rect.y && 
                position.dy <= rect.y + rect.height) {
              setState(() => _selectedRect = rect);
              if (rect.node.data != null && widget.onMessageTap != null) {
                widget.onMessageTap!(rect.node.data!);
              }
              break;
            }
          }
        },
        child: CustomPaint(
          painter: _TreemapPainter(
            rectangles: _rectangles,
            selectedRect: _selectedRect,
            getTextColor: _getTextColor,
            getMessageLines: _getMessageLines,
            getMessageFontSize: _getMessageFontSize,
          ),
          size: Size(widget.width, widget.height),
        ),
      ),
    );
  }
}

/// 矩形情報を保持するヘルパークラス
class _Rectangle {
  final double x;
  final double y;
  final double width;
  final double height;
  
  _Rectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// ツリーマップカスタムペインター
class _TreemapPainter extends CustomPainter {
  final List<TreemapRect> rectangles;
  final TreemapRect? selectedRect;
  final Color Function(Color) getTextColor;
  final List<String> Function(String, double, double) getMessageLines;
  final double Function(double, double) getMessageFontSize;
  
  _TreemapPainter({
    required this.rectangles,
    this.selectedRect,
    required this.getTextColor,
    required this.getMessageLines,
    required this.getMessageFontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final rect in rectangles) {
      _drawRect(canvas, rect);
      _drawText(canvas, rect);
    }
  }

  void _drawRect(Canvas canvas, TreemapRect rect) {
    final paint = Paint()
      ..color = rect.color
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = selectedRect == rect ? const Color(0xFF2563EB) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedRect == rect ? 3 : 1;
    
    final rectF = Rect.fromLTWH(rect.x, rect.y, rect.width, rect.height);
    canvas.drawRect(rectF, paint);
    canvas.drawRect(rectF, borderPaint);
  }

  void _drawText(Canvas canvas, TreemapRect rect) {
    final textColor = getTextColor(rect.color);
    
    // 送信者ラベル（レベル1）
    if (rect.node.level == 1 && rect.width > 80 && rect.height > 30) {
      _drawTextAtPosition(
        canvas,
        '👤 ${rect.label}',
        rect.x + 8,
        rect.y + 20,
        textColor,
        math.min(rect.width / 6, 20),
        FontWeight.w700,
      );
    }
    
    // 評価ラベル（レベル2）
    if (rect.node.level == 2 && rect.width > 60 && rect.height > 25) {
      _drawTextAtPosition(
        canvas,
        rect.label,
        rect.x + 6,
        rect.y + 16,
        textColor,
        math.min(rect.width / 8, 18),
        FontWeight.w600,
      );
    }
    
    // メッセージ（レベル3）
    if (rect.node.level >= 3) {
      // 送信者名
      if (rect.width > 25 && rect.height > 20 && rect.senderName != null) {
        final senderName = rect.senderName!.length > math.max((rect.width / 8).floor(), 3)
            ? rect.senderName!.substring(0, math.max((rect.width / 8).floor(), 3))
            : rect.senderName!;
        
        _drawTextAtPosition(
          canvas,
          senderName,
          rect.x + rect.width / 2,
          rect.y + math.min(12, rect.height * 0.4),
          textColor,
          getMessageFontSize(rect.width, rect.height),
          FontWeight.w600,
          textAlign: TextAlign.center,
        );
      }
      
      // メッセージテキスト（複数行対応）
      if (rect.width > 35 && rect.height > 30) {
        final lines = getMessageLines(rect.label, rect.width, rect.height);
        final fontSize = getMessageFontSize(rect.width, rect.height);
        final lineHeight = fontSize * 1.2;
        final totalTextHeight = lines.length * lineHeight;
        final startY = rect.y + rect.height / 2 - totalTextHeight / 2 + fontSize * 0.8;
        
        for (int i = 0; i < lines.length; i++) {
          _drawTextAtPosition(
            canvas,
            lines[i],
            rect.x + rect.width / 2,
            startY + (i * lineHeight),
            textColor,
            fontSize,
            FontWeight.normal,
            textAlign: TextAlign.center,
          );
        }
      }
      
      // 評価表示
      if (rect.width > 20 && rect.height > 25) {
        String ratingText;
        if (rect.rating != null && rect.rating! > 0) {
          ratingText = '★' * math.min(rect.rating!, (rect.width / 8).floor());
        } else if (rect.isUnread) {
          ratingText = '未読';
        } else {
          ratingText = '未評価';
        }
        
        _drawTextAtPosition(
          canvas,
          ratingText,
          rect.x + rect.width / 2,
          rect.y + rect.height - math.min(4, rect.height * 0.1),
          rect.rating != null ? Colors.black : textColor,
          math.max(math.min(math.min(rect.width / 6, rect.height / 3), 12), 8),
          FontWeight.w500,
          textAlign: TextAlign.center,
        );
      }
    }
  }

  void _drawTextAtPosition(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
    double fontSize,
    FontWeight fontWeight, {
    TextAlign textAlign = TextAlign.start,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    
    textPainter.layout();
    
    double offsetX = x;
    if (textAlign == TextAlign.center) {
      offsetX = x - textPainter.width / 2;
    }
    
    textPainter.paint(canvas, Offset(offsetX, y - textPainter.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}