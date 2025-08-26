import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String? content;
  final int maxLinesToShow;
  final TextStyle? textStyle;
  final TextStyle? buttonStyle;
  final Duration animationDuration;
  final String? expandText;
  final String? collapsText;

  const ExpandableText({
    super.key,
    required this.content,
    this.maxLinesToShow = 3,
    this.textStyle,
    this.buttonStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.collapsText,
    this.expandText,
  });

  @override
  State<ExpandableText> createState() => _ExpandableWidgetState();
}

class _ExpandableWidgetState extends State<ExpandableText>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _expanded = ValueNotifier(false);
  late TextStyle _textStyle;
  late TextStyle _buttonStyle;
  late AnimationController _animationController;

  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _textStyle =
        widget.textStyle ??
        const TextStyle(fontSize: 14, color: Colors.black87);
    _buttonStyle =
        widget.buttonStyle ??
        const TextStyle(
          fontSize: 14,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        );

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  @override
  void dispose() {
    _expanded.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, isExpanded, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final textSpan = TextSpan(
              text: widget.content ?? "",
              style: _textStyle,
            );

            final textPainter = TextPainter(
              text: textSpan,
              maxLines: widget.maxLinesToShow,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout(maxWidth: constraints.maxWidth);

            // Check if text overflows or exactly fits the max lines
            final lineMetrics = textPainter.computeLineMetrics();

            final lineCount = lineMetrics.length;
            _isOverflowing =
                textPainter.didExceedMaxLines ||
                lineCount >= widget.maxLinesToShow;

            // Start animation
            if (isExpanded) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }

            if (!_isOverflowing && !isExpanded) {
              return Text.rich(textSpan, textAlign: TextAlign.start);
            }

            return SizedBox(
              width: double.infinity,
              child: AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.fastLinearToSlowEaseIn,
                alignment: Alignment.topCenter,
                child:
                    isExpanded
                        ? _buildCollapsedText(textSpan)
                        : _buildExpandedText(constraints.maxWidth),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCollapsedText(TextSpan textSpan) {
    return GestureDetector(
      onTap: () => _expanded.value = false,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: widget.animationDuration,
        child: RichText(
          overflow: TextOverflow.clip,
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              textSpan,
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Text(widget.collapsText ?? '', style: _buttonStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedText(double maxWidth) {
    final fullText = widget.content ?? "";

    // Calculate the width needed for the "Xem thêm" button
    final buttonTextSpan = TextSpan(
      text: widget.expandText,
      style: _buttonStyle,
    );
    final buttonTextPainter = TextPainter(
      text: buttonTextSpan,
      textDirection: TextDirection.ltr,
    );
    buttonTextPainter.layout();
    final buttonWidth = buttonTextPainter.width;

    //Tính toán xem có thể chứa bao nhiêu văn bản trong không gian có sẵn
    final availableWidth = maxWidth - buttonWidth - 32;

    // Create a text span with the full content
    final textSpan = TextSpan(text: fullText, style: _textStyle);

    // Use text painter to find where to break the text
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.maxLinesToShow,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);

    // Get the position where the text would end in the last line
    final endPosition = textPainter.getPositionForOffset(
      Offset(availableWidth, textPainter.size.height),
    );

    int breakIndex = endPosition.offset;

    // Adjust break index to avoid cutting words in the middle
    if (breakIndex < fullText.length - 1) {
      // Find the last space to break at a word boundary
      final lastSpaceIndex = fullText.lastIndexOf(' ', breakIndex);
      if (lastSpaceIndex != -1 && lastSpaceIndex > breakIndex - 10) {
        breakIndex = lastSpaceIndex;
      }
    }

    // kiểm tra để đoạn text cắt có nằm trong khoảng này không
    breakIndex = breakIndex.clamp(0, fullText.length);

    // lấy text thu gọn
    String visibleText = fullText.substring(0, breakIndex).trim();

    // Add ellipsis if we're not showing the full text
    if (breakIndex < fullText.length) {
      visibleText = visibleText.replaceAll(RegExp(r'\s+$'), '');
      if (!visibleText.endsWith('...')) {
        visibleText += '...';
      }
    }

    return GestureDetector(
      onTap: () => _expanded.value = true,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: widget.animationDuration,
        child: RichText(
          maxLines: widget.maxLinesToShow,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.left,
          text: TextSpan(
            children: [
              TextSpan(text: visibleText, style: _textStyle),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Text(widget.expandText ?? '', style: _buttonStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
