import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const KidsJigsawApp());
}

class KidsJigsawApp extends StatelessWidget {
  const KidsJigsawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atvex Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF6E5),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Animal types
// ---------------------------------------------------------------------------

enum Animal { cat, dog, elephant }

extension AnimalInfo on Animal {
  String get label {
    switch (this) {
      case Animal.cat:
        return 'Cat';
      case Animal.dog:
        return 'Dog';
      case Animal.elephant:
        return 'Elephant';
    }
  }

  Color get accentColor {
    switch (this) {
      case Animal.cat:
        return const Color.fromARGB(255, 211, 132, 108);
      case Animal.dog:
        return Colors.brown;
      case Animal.elephant:
        return Colors.blueGrey;
    }
  }
}

// ---------------------------------------------------------------------------
// Home screen: choose an animal
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atvex Puzzle'),
        backgroundColor: const Color.fromARGB(255, 208, 120, 179),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pick a puzzle!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            for (final animal in Animal.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 240,
                  height: 90,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: animal.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PuzzleScreen(animal: animal),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CustomPaint(
                            painter: AnimalScenePainter(animal: animal),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          animal.label,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Puzzle screen: the 4x4 jigsaw
// ---------------------------------------------------------------------------

class PuzzleScreen extends StatefulWidget {
  final Animal animal;
  const PuzzleScreen({super.key, required this.animal});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const int gridSize = 4; // 4x4 = 16 pieces
  late List<int> board; // board[slotIndex] = pieceId currently sitting there
  bool solved = false;

  @override
  void initState() {
    super.initState();
    _newPuzzle();
  }

  void _newPuzzle() {
    final pieces = List<int>.generate(gridSize * gridSize, (i) => i);
    final rnd = Random();
    do {
      pieces.shuffle(rnd);
    } while (_isSolved(pieces));
    setState(() {
      board = pieces;
      solved = false;
    });
  }

  bool _isSolved(List<int> b) {
    for (int i = 0; i < b.length; i++) {
      if (b[i] != i) return false;
    }
    return true;
  }

  void _swap(int slotA, int slotB) {
    if (slotA == slotB) return;
    setState(() {
      final temp = board[slotA];
      board[slotA] = board[slotB];
      board[slotB] = temp;
      if (_isSolved(board)) {
        solved = true;
        Future.delayed(const Duration(milliseconds: 200), _showWinDialog);
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Great job!'),
        content: Text(
            'You solved the ${widget.animal.label} puzzle, Congrats from Atvex!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _newPuzzle();
            },
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Choose another animal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.animal.label} Puzzle'),
        backgroundColor: widget.animal.accentColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle',
            onPressed: _newPuzzle,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize =
              min(constraints.maxWidth, constraints.maxHeight) * 0.85;
          final pieceSize = boardSize / gridSize;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reference thumbnail so kids know what they're building
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: AnimalScenePainter(animal: widget.animal),
                      size: const Size(90, 90),
                    ),
                  ),
                ),
                // The jigsaw board
                SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, slotIndex) {
                      final pieceId = board[slotIndex];
                      return DragTarget<int>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          final draggedPieceId = details.data;
                          final draggedSlot = board.indexOf(draggedPieceId);
                          _swap(slotIndex, draggedSlot);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final highlight = candidateData.isNotEmpty;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    highlight ? Colors.green : Colors.black12,
                                width: highlight ? 3 : 1,
                              ),
                            ),
                            child: Draggable<int>(
                              data: pieceId,
                              feedback: SizedBox(
                                width: pieceSize,
                                height: pieceSize,
                                child: _PuzzlePiece(
                                  animal: widget.animal,
                                  pieceId: pieceId,
                                  gridSize: gridSize,
                                  pieceSize: pieceSize,
                                ),
                              ),
                              childWhenDragging: Container(
                                color: Colors.black12,
                              ),
                              child: _PuzzlePiece(
                                animal: widget.animal,
                                pieceId: pieceId,
                                gridSize: gridSize,
                                pieceSize: pieceSize,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Drag a piece onto another to swap them!',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// A single puzzle piece: shows the correct crop of the full scene painting.
class _PuzzlePiece extends StatelessWidget {
  final Animal animal;
  final int pieceId;
  final int gridSize;
  final double pieceSize;

  const _PuzzlePiece({
    required this.animal,
    required this.pieceId,
    required this.gridSize,
    required this.pieceSize,
  });

  @override
  Widget build(BuildContext context) {
    final row = pieceId ~/ gridSize;
    final col = pieceId % gridSize;
    final fullSize = pieceSize * gridSize;

    // alignment ranges from -1 (left/top) to 1 (right/bottom)
    final alignX = gridSize == 1 ? 0.0 : -1 + 2 * col / (gridSize - 1);
    final alignY = gridSize == 1 ? 0.0 : -1 + 2 * row / (gridSize - 1);

    return ClipRect(
      child: OverflowBox(
        maxWidth: fullSize,
        maxHeight: fullSize,
        alignment: Alignment(alignX, alignY),
        child: SizedBox(
          width: fullSize,
          height: fullSize,
          child: CustomPaint(painter: AnimalScenePainter(animal: animal)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The hand-drawn scenes (no external images, no copyrighted characters)
// ---------------------------------------------------------------------------

class AnimalScenePainter extends CustomPainter {
  final Animal animal;
  AnimalScenePainter({required this.animal});

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    switch (animal) {
      case Animal.cat:
        _paintCat(canvas, size);
        break;
      case Animal.dog:
        _paintDog(canvas, size);
        break;
      case Animal.elephant:
        _paintElephant(canvas, size);
        break;
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFFAEE1F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), sky);

    final sun = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.16),
      size.width * 0.09,
      sun,
    );

    final grass = Paint()..color = const Color(0xFF9CCC65);
    final grassPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.64,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(grassPath, grass);
  }

  void _paintCat(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFFFF8A50);
    final belly = Paint()..color = const Color(0xFFFFF3E0);
    final dark = Paint()..color = const Color(0xFFBF360C);
    final eye = Paint()..color = Colors.black;
    final pink = Paint()..color = const Color(0xFFEF9A9A);

    // ears
    final earL = Path()
      ..moveTo(w * 0.34, h * 0.42)
      ..lineTo(w * 0.30, h * 0.22)
      ..lineTo(w * 0.46, h * 0.36)
      ..close();
    final earR = Path()
      ..moveTo(w * 0.66, h * 0.42)
      ..lineTo(w * 0.70, h * 0.22)
      ..lineTo(w * 0.54, h * 0.36)
      ..close();
    canvas.drawPath(earL, body);
    canvas.drawPath(earR, body);

    // head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.22, body);
    // belly patch
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.20,
        height: h * 0.16,
      ),
      belly,
    );
    // eyes
    canvas.drawCircle(Offset(w * 0.42, h * 0.50), w * 0.025, eye);
    canvas.drawCircle(Offset(w * 0.58, h * 0.50), w * 0.025, eye);
    // nose
    canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.018, pink);
    // whiskers
    final whisker = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1.5;
    for (final dy in [-0.01, 0.0, 0.01]) {
      canvas.drawLine(
        Offset(w * 0.30, h * (0.57 + dy)),
        Offset(w * 0.42, h * (0.58 + dy)),
        whisker,
      );
      canvas.drawLine(
        Offset(w * 0.70, h * (0.57 + dy)),
        Offset(w * 0.58, h * (0.58 + dy)),
        whisker,
      );
    }
    // tail
    final tail = Path()
      ..moveTo(w * 0.72, h * 0.70)
      ..quadraticBezierTo(w * 0.92, h * 0.68, w * 0.88, h * 0.48);
    canvas.drawPath(
      tail,
      Paint()
        ..color = dark.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintDog(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFFA1887F);
    final earColor = Paint()..color = const Color(0xFF6D4C41);
    final spot = Paint()..color = const Color(0xFF6D4C41);
    final eye = Paint()..color = Colors.black;
    final tongue = Paint()..color = const Color(0xFFE57373);

    // ears (floppy ovals)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.32, h * 0.46),
        width: w * 0.14,
        height: h * 0.26,
      ),
      earColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.68, h * 0.46),
        width: w * 0.14,
        height: h * 0.26,
      ),
      earColor,
    );

    // head
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.22, body);
    // spot
    canvas.drawCircle(Offset(w * 0.36, h * 0.44), w * 0.06, spot);
    // snout
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.16,
        height: h * 0.12,
      ),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    // nose
    canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.02, eye);
    // eyes
    canvas.drawCircle(Offset(w * 0.42, h * 0.48), w * 0.025, eye);
    canvas.drawCircle(Offset(w * 0.58, h * 0.48), w * 0.025, eye);
    // tongue
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.68),
        width: w * 0.05,
        height: h * 0.07,
      ),
      tongue,
    );
  }

  void _paintElephant(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFFB0BEC5);
    final earColor = Paint()..color = const Color(0xFF90A4AE);
    final eye = Paint()..color = Colors.black;

    // ears
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.28, h * 0.50),
        width: w * 0.22,
        height: h * 0.30,
      ),
      earColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.72, h * 0.50),
        width: w * 0.22,
        height: h * 0.30,
      ),
      earColor,
    );

    // head
    canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.20, body);

    // trunk
    final trunk = Path()
      ..moveTo(w * 0.44, h * 0.58)
      ..quadraticBezierTo(w * 0.40, h * 0.75, w * 0.50, h * 0.80)
      ..quadraticBezierTo(w * 0.56, h * 0.75, w * 0.52, h * 0.66);
    canvas.drawPath(
      trunk,
      Paint()
        ..color = body.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );

    // eyes
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), w * 0.02, eye);
    canvas.drawCircle(Offset(w * 0.58, h * 0.44), w * 0.02, eye);

    // tusks
    final tusk = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.44, h * 0.60),
        width: w * 0.03,
        height: h * 0.06,
      ),
      tusk,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.56, h * 0.60),
        width: w * 0.03,
        height: h * 0.06,
      ),
      tusk,
    );
  }

  @override
  bool shouldRepaint(covariant AnimalScenePainter oldDelegate) {
    return oldDelegate.animal != animal;
  }
}
