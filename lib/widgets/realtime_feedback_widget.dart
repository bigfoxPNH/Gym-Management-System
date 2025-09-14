import 'package:flutter/material.dart';
import '../models/exercise_model.dart';

class RealtimeFeedbackWidget extends StatelessWidget {
  final WorkoutFeedback? feedback;
  final Duration animationDuration;

  const RealtimeFeedbackWidget({
    super.key,
    required this.feedback,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    if (feedback == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: animationDuration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getFeedbackColor(feedback!.type).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getFeedbackColor(feedback!.type).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: _getFeedbackColor(feedback!.type).withOpacity(0.7),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFeedbackIcon(feedback!.type),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  feedback!.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getFeedbackTypeLabel(feedback!.type),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Pulse animation for dangerous feedback
          if (feedback!.type == FeedbackType.danger)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return const Color(0xFF4CAF50); // Xanh lá - Đúng/Tốt
      case FeedbackType.warning:
        return const Color(0xFFFF9800); // Vàng - Cảnh báo
      case FeedbackType.danger:
        return const Color(0xFFF44336); // Đỏ - Nguy hiểm
      case FeedbackType.incorrect:
        return const Color(0xFFE91E63); // Hồng đỏ - Sai
      case FeedbackType.guidance:
        return const Color(0xFF2196F3); // Xanh dương - Hướng dẫn
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

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return 'Tốt';
      case FeedbackType.warning:
        return 'Cảnh báo';
      case FeedbackType.danger:
        return 'Nguy hiểm';
      case FeedbackType.incorrect:
        return 'Sai';
      case FeedbackType.guidance:
        return 'Hướng dẫn';
    }
  }
}

class PulsatingFeedbackWidget extends StatefulWidget {
  final WorkoutFeedback feedback;

  const PulsatingFeedbackWidget({super.key, required this.feedback});

  @override
  State<PulsatingFeedbackWidget> createState() =>
      _PulsatingFeedbackWidgetState();
}

class _PulsatingFeedbackWidgetState extends State<PulsatingFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // Start animations
    _slideController.forward();

    if (widget.feedback.type == FeedbackType.danger) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: RealtimeFeedbackWidget(feedback: widget.feedback),
          );
        },
      ),
    );
  }
}

class FeedbackHistoryWidget extends StatelessWidget {
  final List<WorkoutFeedback> feedbackHistory;
  final int maxHistoryItems;

  const FeedbackHistoryWidget({
    super.key,
    required this.feedbackHistory,
    this.maxHistoryItems = 3,
  });

  @override
  Widget build(BuildContext context) {
    final recentFeedback = feedbackHistory.reversed
        .take(maxHistoryItems)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Lịch sử phản hồi',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentFeedback.asMap().entries.map((entry) {
            final index = entry.key;
            final feedback = entry.value;
            final opacity = 1.0 - (index * 0.3);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < recentFeedback.length - 1 ? 4 : 0,
              ),
              child: Opacity(
                opacity: opacity,
                child: Row(
                  children: [
                    Icon(
                      _getFeedbackIcon(feedback.type),
                      color: _getFeedbackColor(feedback.type),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        feedback.message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(opacity),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.correct:
        return const Color(0xFF4CAF50);
      case FeedbackType.warning:
        return const Color(0xFFFF9800);
      case FeedbackType.danger:
        return const Color(0xFFF44336);
      case FeedbackType.incorrect:
        return const Color(0xFFE91E63);
      case FeedbackType.guidance:
        return const Color(0xFF2196F3);
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
