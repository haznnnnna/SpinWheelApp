import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with TickerProviderStateMixin {
  final StreamController<int> controller = StreamController<int>();
  final List<String> prizes = [
    "20% OFF",
    "Mystery Gift",
    "Free Delivery",
    "Better Luck",
    "Better Luck",
    "Better Luck",
    "₹100 OFF",
  ];

  final List<String> prizeEmojis = [
    "🎁",
    "🎉",
    "🚚",
    "😅",
    "😅",
    "😅",
    "💸",
  ];

  int remainingSpins = 3;
  DateTime? lastSpinTime;
  bool isSpinning = false;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  String _timeRemaining = "Resets in 1h";

  @override
  void initState() {
    super.initState();
    _loadSpinData();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    controller.close();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  void _updateTimeRemaining() {
    if (lastSpinTime == null || remainingSpins > 0) {
      setState(() {
        _timeRemaining = "Resets in 1h";
      });
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(lastSpinTime!);
    
    if (difference.inHours >= 1) {
      // Time to reset spins
      setState(() {
        remainingSpins = 3;
        _timeRemaining = "Resets in 1h";
      });
      _saveSpinData();
    } else {
      // Calculate remaining time
      final remainingDuration = const Duration(hours: 1) - difference;
      final minutes = remainingDuration.inMinutes;
      final seconds = remainingDuration.inSeconds % 60;
      
      setState(() {
        _timeRemaining = "${minutes}m ${seconds}s";
      });
    }
  }

  Future<void> _loadSpinData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getString('lastSpinTime');
    final spins = prefs.getInt('remainingSpins') ?? 3;

    if (lastTime != null) {
      lastSpinTime = DateTime.tryParse(lastTime);
      if (lastSpinTime != null &&
          DateTime.now().difference(lastSpinTime!).inHours >= 1) {
        remainingSpins = 3;
      } else {
        remainingSpins = spins;
      }
    } else {
      remainingSpins = 3;
    }
    setState(() {});
    _updateTimeRemaining();
  }

  Future<void> _saveSpinData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remainingSpins', remainingSpins);
    await prefs.setString('lastSpinTime', DateTime.now().toIso8601String());
    lastSpinTime = DateTime.now();
  }

  void _spinWheel() {
    if (remainingSpins > 0 && !isSpinning) {
      setState(() {
        remainingSpins--;
        isSpinning = true;
      });
      _saveSpinData();
      final randomIndex = Random().nextInt(prizes.length);
      controller.add(randomIndex);

      Future.delayed(const Duration(seconds: 4), () {
        setState(() {
          isSpinning = false;
        });
        _confettiController.forward().then((_) => _confettiController.reset());
        _showPrizeDialog(prizes[randomIndex], prizeEmojis[randomIndex]);
      });
    } else if (remainingSpins == 0) {
      _showNoSpinsDialog();
    }
  }

  void _showNoSpinsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange[700], size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "No Spins Left!",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "You've used all your spins. Come back in $_timeRemaining for more chances to win!",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Got it!",
              style: GoogleFonts.poppins(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrizeDialog(String prize, String emoji) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade400,
                Colors.purple.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 50),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "🎉 Congratulations! 🎉",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You won",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prize,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Claim Prize",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade600,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "🎡 Spin the Wheel",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Try your luck and win amazing prizes!",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Spins Remaining Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Spins Available",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$remainingSpins spins left",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: remainingSpins == 0 
                            ? Colors.orange.shade50 
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time, 
                            size: 16, 
                            color: remainingSpins == 0 
                                ? Colors.orange[700] 
                                : Colors.green[700]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeRemaining,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: remainingSpins == 0 
                                  ? Colors.orange[700] 
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Fortune Wheel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: FortuneWheel(
                  animateFirst: false,
                  selected: controller.stream,
                  physics: CircularPanPhysics(
                    duration: const Duration(seconds: 3),
                    curve: Curves.decelerate,
                  ),
                  items: [
                    for (int i = 0; i < prizes.length; i++)
                      FortuneItem(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                prizeEmojis[i],
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prizes[i],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        style: FortuneItemStyle(
                          color: _getColorForIndex(i),
                          borderColor: Colors.white,
                          borderWidth: 3,
                        ),
                      ),
                  ],
                  indicators: const [
                    FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: TriangleIndicator(
                        color: Colors.deepPurple,
                        width: 30.0,
                        height: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Spin Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSpinning ? 1.0 : 1.0 + (_pulseController.value * 0.05),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSpinning || remainingSpins == 0
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [Colors.deepPurple, Colors.purple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isSpinning || remainingSpins == 0
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: isSpinning ? null : _spinWheel,
                          child: Center(
                            child: isSpinning
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "SPINNING...",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    remainingSpins > 0 ? "SPIN NOW" : "NO SPINS LEFT",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Prize List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Prizes",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    prizes.take(prizes.length - 3).length,
                    (index) => _buildPrizeItem(prizeEmojis[index], prizes[index]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeItem(String emoji, String prize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Text(
            prize,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.amber.shade300,
    ];
    return colors[index % colors.length];
  }
}