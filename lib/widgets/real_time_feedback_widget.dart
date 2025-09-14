import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

class RealTimeFeedbackWidget extends StatelessWidget {
  final WorkoutFeedback? feedback;
  final bool isVisible;

  const RealTimeFeedbackWidget({
    super.key,
    this.feedback,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || feedback == null) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _getFeedbackColor(feedback!.type),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _getFeedbackColor(feedback!.type).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getFeedbackIcon(feedback!.type),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feedback!.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return const Color(0xFF4CAF50); // Green - đúng hoặc tốt
      case FeedbackType.warning:
        return const Color(0xFFF57F17); // Yellow/Orange - cảnh báo
      case FeedbackType.danger:
        return const Color(0xFFD32F2F); // Red - nguy hiểm
      case FeedbackType.incorrect:
        return const Color(0xFFE91E63); // Pink - sai
      case FeedbackType.guidance:
        return const Color(0xFF2196F3); // Blue - hướng dẫn
    }
  }

  IconData _getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return Icons.check_circle;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.danger:
        return Icons.error;
      case FeedbackType.incorrect:
        return Icons.cancel;
      case FeedbackType.guidance:
        return Icons.lightbulb;
    }
  }
}

// Floating feedback widget for overlay display
class FloatingFeedbackWidget extends StatefulWidget {
  final WorkoutFeedback? feedback;
  final VoidCallback? onDismiss;

  const FloatingFeedbackWidget({super.key, this.feedback, this.onDismiss});

  @override
  State<FloatingFeedbackWidget> createState() => _FloatingFeedbackWidgetState();
}

class _FloatingFeedbackWidgetState extends State<FloatingFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    if (widget.feedback != null) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingFeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != null && oldWidget.feedback != widget.feedback) {
      _animationController.reset();
      _animationController.forward();
    } else if (widget.feedback == null && oldWidget.feedback != null) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feedback == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getFeedbackColor(widget.feedback!.type),
                    _getFeedbackColor(widget.feedback!.type).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getFeedbackColor(
                      widget.feedback!.type,
                    ).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFeedbackIcon(widget.feedback!.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.feedback!.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onDismiss != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return const Color(0xFF4CAF50); // Green - đúng hoặc tốt
      case FeedbackType.warning:
        return const Color(0xFFF57F17); // Yellow/Orange - cảnh báo
      case FeedbackType.danger:
        return const Color(0xFFD32F2F); // Red - nguy hiểm
      case FeedbackType.incorrect:
        return const Color(0xFFE91E63); // Pink - sai
      case FeedbackType.guidance:
        return const Color(0xFF2196F3); // Blue - hướng dẫn
    }
  }

  IconData _getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return Icons.check_circle;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.danger:
        return Icons.dangerous;
      case FeedbackType.incorrect:
        return Icons.cancel;
      case FeedbackType.guidance:
        return Icons.lightbulb;
    }
  }
}
