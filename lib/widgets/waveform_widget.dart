import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveformWidget extends StatefulWidget {
  final List<double>? waveformData;
  final Duration? duration;
  final Duration? position;
  final Color? waveColor;
  final Color? progressColor;
  final double height;

  const WaveformWidget({
    super.key,
    this.waveformData,
    this.duration,
    this.position,
    this.waveColor,
    this.progressColor,
    this.height = 80,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<double> _mockWaveformData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _generateMockWaveform();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _generateMockWaveform() {
    // Generate mock waveform data for demonstration
    final random = math.Random();
    _mockWaveformData = List.generate(100, (index) {
      // Create a more realistic waveform pattern
      final baseAmplitude = math.sin(index * 0.1) * 0.5 + 0.5;
      final noise = (random.nextDouble() - 0.5) * 0.3;
      return (baseAmplitude + noise).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.waveColor ?? Colors.grey.withOpacity(0.3);
    final progressColor = widget.progressColor ?? Theme.of(context).primaryColor;
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              waveformData: widget.waveformData ?? _mockWaveformData,
              progress: _calculateProgress(),
              waveColor: waveColor,
              progressColor: progressColor,
              animationValue: _animationController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  double _calculateProgress() {
    if (widget.duration == null || widget.position == null) {
      return 0.0;
    }
    
    final totalMs = widget.duration!.inMilliseconds;
    final currentMs = widget.position!.inMilliseconds;
    
    if (totalMs == 0) return 0.0;
    
    return (currentMs / totalMs).clamp(0.0, 1.0);
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final Color waveColor;
  final Color progressColor;
  final double animationValue;

  WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.waveColor,
    required this.progressColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..color = waveColor;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final amplitude = waveformData[i];
      
      // Add slight animation to make it feel alive
      final animatedAmplitude = amplitude + (math.sin(animationValue * 2 * math.pi + i * 0.1) * 0.05);
      final barHeight = animatedAmplitude.clamp(0.0, 1.0) * maxBarHeight;
      
      final rect = Rect.fromCenter(
        center: Offset(x + barWidth / 2, centerY),
        width: barWidth * 0.8,
        height: barHeight,
      );

      // Determine if this bar should be colored as progress or wave
      final progressX = size.width * progress;
      final isProgress = x < progressX;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        isProgress ? progressPaint : wavePaint,
      );
    }

    // Draw progress indicator line
    if (progress > 0) {
      final progressX = size.width * progress;
      final linePaint = Paint()
        ..color = progressColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(progressX, 0),
        Offset(progressX, size.height),
        linePaint,
      );

      // Draw progress indicator circle
      final circlePaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(progressX, centerY),
        4,
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.waveformData != waveformData;
  }
}
