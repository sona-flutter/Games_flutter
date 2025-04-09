import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Card Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MemoryGameScreen(),
    );
  }
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen>
    with TickerProviderStateMixin {
  // Game state
  late List<CardItem> _cards;
  int? _firstCardIndex;
  int? _secondCardIndex;
  bool _isChecking = false;
  int _pairsFound = 0;
  int _moves = 0;
  bool _gameCompleted = false;

  // Timer state
  late Timer _timer;
  int _secondsElapsed = 0;

  // Confetti animation controller
  late AnimationController _confettiController;

  // Game level
  int _gridSize = 4; // 4x4 grid
  int get _totalPairs => (_gridSize * _gridSize) ~/ 2;

  // Emoji list for card faces
  final List<String> _emojis = [
    '🍎',
    '🍌',
    '🍇',
    '🍓',
    '🍒',
    '🍑',
    '🍍',
    '🥭',
    '🥝',
    '🍋',
    '🍊',
    '🍉',
    '🍈',
    '🥥',
    '🥑',
    '🍆',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Create pairs of cards
    final cardCount = _gridSize * _gridSize;
    final pairsNeeded = cardCount ~/ 2;

    // Shuffle and take needed emojis
    final shuffledEmojis = [..._emojis]..shuffle();
    final selectedEmojis = shuffledEmojis.take(pairsNeeded).toList();

    // Create pairs of cards with those emojis
    final cardPairs = <CardItem>[];
    for (var emoji in selectedEmojis) {
      cardPairs.add(CardItem(emoji));
      cardPairs.add(CardItem(emoji));
    }

    // Shuffle the cards
    _cards = cardPairs..shuffle();

    // Reset game state
    _firstCardIndex = null;
    _secondCardIndex = null;
    _isChecking = false;
    _pairsFound = 0;
    _moves = 0;
    _gameCompleted = false;
    _secondsElapsed = 0;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameCompleted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _onCardTap(int index) {
    // Prevent tapping if checking pairs or card is already flipped
    if (_isChecking || _cards[index].isMatched || _cards[index].isFlipped) {
      return;
    }

    // If this is the first card selection
    if (_firstCardIndex == null) {
      setState(() {
        _firstCardIndex = index;
        _cards[index].isFlipped = true;
      });
      return;
    }

    // Prevent tapping the same card twice
    if (_firstCardIndex == index) {
      return;
    }

    // If this is the second card selection
    setState(() {
      _secondCardIndex = index;
      _cards[index].isFlipped = true;
      _isChecking = true;
      _moves++;
    });

    // Check if the cards match
    _checkForMatch();
  }

  void _checkForMatch() {
    // Delay to allow viewing the second card
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_firstCardIndex != null && _secondCardIndex != null) {
        final firstCard = _cards[_firstCardIndex!];
        final secondCard = _cards[_secondCardIndex!];

        if (firstCard.emoji == secondCard.emoji) {
          // Cards match
          setState(() {
            firstCard.isMatched = true;
            secondCard.isMatched = true;
            _pairsFound++;

            // Check for game completion
            if (_pairsFound == _totalPairs) {
              _gameCompleted = true;
              _confettiController.repeat();
            }
          });
        } else {
          // Cards don't match, flip them back
          setState(() {
            firstCard.isFlipped = false;
            secondCard.isFlipped = false;
          });
        }

        // Reset for next selection
        setState(() {
          _firstCardIndex = null;
          _secondCardIndex = null;
          _isChecking = false;
        });
      }
    });
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
      _confettiController.stop();
    });
  }

  String _formatTime() {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade900, Colors.purple.shade800],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildGameStats(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildCardGrid()),
                  const SizedBox(height: 16),
                  _buildControls(),
                  const SizedBox(height: 24),
                ],
              ),
              if (_gameCompleted) _buildConfetti(),
              if (_gameCompleted) _buildCompletionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Memory Match',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black38,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Pairs Found',
            '$_pairsFound/$_totalPairs',
            Colors.greenAccent,
          ),
          _buildStatItem('Moves', '$_moves', Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = (constraints.maxWidth / _gridSize) - 8;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              return MemoryCard(
                card: _cards[index],
                size: cardSize,
                onTap: () => _onCardTap(index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton.icon(
        onPressed: _resetGame,
        icon: Icon(Icons.refresh, color: Colors.white),
        label: Text(
          'New Game',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.purpleAccent.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.deepPurple.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 Congratulations! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You completed the game in:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Moves: $_moves',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: Icon(Icons.replay, color: Colors.purple.shade800),
                label: Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.purple.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, _) {
          return CustomPaint(
            painter: ConfettiPainter(_confettiController.value),
          );
        },
      ),
    );
  }
}

class CardItem {
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardItem(this.emoji, {this.isFlipped = false, this.isMatched = false});
}

class MemoryCard extends StatefulWidget {
  final CardItem card;
  final double size;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.card,
    required this.size,
    required this.onTap,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.isFlipped != widget.card.isFlipped) {
      if (widget.card.isFlipped) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isBackVisible = _animation.value < 0.5;
          final transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(isBackVisible ? 0 : pi);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child:
                isBackVisible
                    ? _buildCardBack()
                    : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardFront(),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.purple.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          size: widget.size * 0.5,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    final isMatched = widget.card.isMatched;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isMatched
                  ? [Colors.green.shade400, Colors.green.shade700]
                  : [Colors.orange.shade300, Colors.deepOrange.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: (isMatched ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.card.emoji,
          style: TextStyle(fontSize: widget.size * 0.5),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Confetti> _confetti = [];
  final Random _random = Random();

  ConfettiPainter(this.progress) {
    if (_confetti.isEmpty) {
      for (int i = 0; i < 100; i++) {
        _confetti.add(
          Confetti(
            position: Offset(
              _random.nextDouble() * 400,
              _random.nextDouble() * 400 - 400,
            ),
            color: Color.fromARGB(
              255,
              _random.nextInt(255),
              _random.nextInt(255),
              _random.nextInt(255),
            ),
            size: 10 + _random.nextDouble() * 10,
            velocity: Offset(
              (_random.nextDouble() - 0.5) * 4,
              _random.nextDouble() * 8 + 4,
            ),
            rotation: _random.nextDouble() * 2 * pi,
            rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
          ),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var confetti in _confetti) {
      final updatedPos = Offset(
        confetti.position.dx + confetti.velocity.dx,
        confetti.position.dy + confetti.velocity.dy,
      );

      if (updatedPos.dy > size.height) {
        confetti.position = Offset(
          _random.nextDouble() * size.width,
          -confetti.size,
        );
      } else {
        confetti.position = updatedPos;
      }

      confetti.rotation += confetti.rotationSpeed;

      canvas.save();
      canvas.translate(confetti.position.dx, confetti.position.dy);
      canvas.rotate(confetti.rotation);

      final paint = Paint()..color = confetti.color;

      // Draw a rectangle for confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: confetti.size,
          height: confetti.size / 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class Confetti {
  Offset position;
  final Color color;
  final double size;
  final Offset velocity;
  double rotation;
  final double rotationSpeed;

  Confetti({
    required this.position,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}
