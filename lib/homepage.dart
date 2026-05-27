import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pacman_flutter/cell.dart';
import 'package:pacman_flutter/dpad.dart';
import 'package:pacman_flutter/ghost.dart';
import 'package:pacman_flutter/path.dart';
import 'package:pacman_flutter/player.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static int numberInrow = 11;
  int numberofsq = numberInrow * 16;
  int player = numberInrow * 14 + 1;
  int score = 0;
  int max = 0;
  int level = 1;
  bool isGameOver = false;

  // ── সব 4টা ghost এর fixed starting positions ──
  // 3+ valid move আছে এমন cells বেছে নেওয়া হয়েছে
  final List<int> _allGhostStartPositions = [
    26, // row 2 — 3 valid moves
    28, // row 2 — 3 valid moves
    58, // row 5 — 3 valid moves
    62, // row 5 — 3 valid moves
  ];

  // ── level অনুযায়ী কতটা ghost active সেটা বের করে ──
  // level 1 → 1 ghost, level 2 → 2, level 3 → 3, level 4+ → 4
  int get _activeGhostCount => level.clamp(1, 4);

  // ── active ghost positions (level অনুযায়ী) ──
  late List<int> ghosts;
  late List<int> _ghostLastPositions; // পিছনে যাওয়া বন্ধ করতে

  Timer? ghostTimer;

  Set<int> barriers = {
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    16,
    21,
    22,
    24,
    25,
    29,
    30,
    32,
    33,
    35,
    38,
    41,
    43,
    44,
    48,
    49,
    50,
    54,
    55,
    56,
    57,
    63,
    64,
    65,
    66,
    70,
    72,
    76,
    77,
    79,
    80,
    84,
    85,
    87,
    88,
    93,
    98,
    99,
    100,
    102,
    106,
    108,
    109,
    110,
    113,
    114,
    116,
    117,
    120,
    121,
    123,
    129,
    131,
    132,
    134,
    136,
    138,
    140,
    142,
    143,
    147,
    149,
    153,
    154,
    161,
    162,
    164,
    165,
    166,
    167,
    168,
    169,
    170,
    171,
    172,
    173,
    174,
    175,
  };

  Set<int> food = {};
  Timer? moveTimer;
  String direction = 'right';

  @override
  void initState() {
    super.initState();
    _initFood();
    _initGhosts(); // level 1 → 1 ghost দিয়ে শুরু
    _startGhostMovement();
  }

  @override
  void dispose() {
    moveTimer?.cancel();
    ghostTimer?.cancel();
    super.dispose();
  }

  // ── level অনুযায়ী ghost list বানাও ──
  void _initGhosts() {
    ghosts = List<int>.from(
      _allGhostStartPositions.sublist(0, _activeGhostCount),
    );
    // শুরুতে lastPosition = current position (কোনো preferred direction নেই)
    _ghostLastPositions = List<int>.from(ghosts);
  }

  void _initFood() {
    food.clear();
    for (int i = 0; i < numberofsq; i++) {
      if (!barriers.contains(i) && i != player) {
        food.add(i);
      }
    }
  }

  void _startGhostMovement() {
    ghostTimer?.cancel();
    // level বাড়লে ghost একটু দ্রুত হবে (400ms → 300ms → 250ms → 200ms)
    final speeds = [350, 300, 250, 200];
    final speed = speeds[(level - 1).clamp(0, 3)];

    ghostTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (!isGameOver) _moveGhosts();
    });
  }

  void _moveGhosts() {
    final random = Random();
    setState(() {
      for (int i = 0; i < ghosts.length; i++) {
        final current = ghosts[i];
        final last = _ghostLastPositions[i];

        List<int> possibleMoves = [
          current - 1,
          current + 1,
          current - numberInrow,
          current + numberInrow,
        ];

        // valid moves — barrier নয়, bound এর ভেতরে
        List<int> validMoves = possibleMoves.where((pos) {
          return pos >= 0 && pos < numberofsq && !barriers.contains(pos);
        }).toList();

        // আগের position এ ফিরে যাওয়া বন্ধ করো
        // (যদি অন্য কোনো valid move থাকে)
        final noBacktrack = validMoves.where((pos) => pos != last).toList();
        final moveCandidates = noBacktrack.isNotEmpty
            ? noBacktrack
            : validMoves;

        if (moveCandidates.isNotEmpty) {
          int nextPos;
          // 60% chance player এর দিকে যাবে, 40% random
          if (random.nextDouble() < 0.6) {
            moveCandidates.sort((a, b) {
              final distA =
                  (a % numberInrow - player % numberInrow).abs() +
                  (a ~/ numberInrow - player ~/ numberInrow).abs();
              final distB =
                  (b % numberInrow - player % numberInrow).abs() +
                  (b ~/ numberInrow - player ~/ numberInrow).abs();
              return distA.compareTo(distB);
            });
            nextPos = moveCandidates.first;
          } else {
            nextPos = moveCandidates[random.nextInt(moveCandidates.length)];
          }

          _ghostLastPositions[i] = current; // আগের position save করো
          ghosts[i] = nextPos;
        }

        if (ghosts[i] == player) {
          _triggerGameOver();
        }
      }
    });
  }

  void _triggerGameOver() {
    ghostTimer?.cancel();
    moveTimer?.cancel();
    isGameOver = true;
    if (score > max) max = score;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'GAME OVER',
            style: GoogleFonts.pressStart2p(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'SCORE: $score',
            style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: Text(
                'PLAY AGAIN',
                style: GoogleFonts.pressStart2p(
                  color: Colors.lightGreenAccent,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void resetGame() {
    ghostTimer?.cancel();
    moveTimer?.cancel();
    setState(() {
      if (score > max) max = score;
      score = 0;
      level = 1;
      isGameOver = false;
      player = numberInrow * 14 + 1;
      direction = 'right';
      _initFood();
      _initGhosts(); // level 1 → 1 ghost দিয়ে reset
    });
    _startGhostMovement();
  }

  void pauseGame() {
    moveTimer?.cancel();
    ghostTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'PACMAN 2D',
          style: GoogleFonts.pressStart2p(color: Colors.yellow, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGhostMovement();
            },
            child: Text(
              'RESUME',
              style: GoogleFonts.pressStart2p(
                color: Colors.lightGreenAccent,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: Text(
              'QUIT GAME',
              style: GoogleFonts.pressStart2p(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void makeMove() {
    if (isGameOver) return;
    switch (direction) {
      case "left":
        _tryMove(player - 1);
        break;
      case "right":
        _tryMove(player + 1);
        break;
      case "up":
        _tryMove(player - numberInrow);
        break;
      case "down":
        _tryMove(player + numberInrow);
        break;
    }
  }

  void _tryMove(int newPosition) {
    if (!barriers.contains(newPosition) &&
        newPosition >= 0 &&
        newPosition < numberofsq) {
      setState(() {
        player = newPosition;

        if (food.contains(player)) {
          food.remove(player);
          score++;
          if (score > max) max = score;

          // ── সব food শেষ → level up ──
          if (food.isEmpty) {
            level++;
            _initFood();
            _initGhosts(); // নতুন level এ একটা নতুন ghost যোগ হবে
            _startGhostMovement(); // নতুন speed এ timer restart
          }
        }

        if (ghosts.contains(player)) {
          _triggerGameOver();
        }
      });
    }
  }

  void stopGame() {
    moveTimer?.cancel();
    moveTimer = null;
  }

  Widget _arcadeText(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.pressStart2p(
            color: Colors.lightGreenAccent,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 4, 5, 4),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 5) {
                  setState(() => direction = "down");
                } else if (details.delta.dy < 5) {
                  setState(() => direction = "up");
                }
                makeMove();
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 5) {
                  setState(() => direction = "right");
                } else if (details.delta.dx < 5) {
                  setState(() => direction = "left");
                }
                makeMove();
              },
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: numberofsq,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: numberInrow,
                ),
                itemBuilder: (BuildContext context, int index) {
                  // ── Player ──
                  if (player == index) {
                    Widget playerWidget;
                    switch (direction) {
                      case "left":
                        playerWidget = Transform.rotate(
                          angle: pi,
                          child: MyPlayer(),
                        );
                        break;
                      case "up":
                        playerWidget = Transform.rotate(
                          angle: -pi / 2,
                          child: MyPlayer(),
                        );
                        break;
                      case "down":
                        playerWidget = Transform.rotate(
                          angle: pi / 2,
                          child: MyPlayer(),
                        );
                        break;
                      default:
                        playerWidget = MyPlayer();
                    }
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: playerWidget,
                    );
                  }
                  // ── Ghost — index দিয়ে কোন ghost সেটা বের করো ──
                  else if (ghosts.contains(index)) {
                    final ghostIndex = ghosts.indexOf(index);
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1.0),
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: MyGhost(ghostNumber: ghostIndex + 1),
                    );
                  }
                  // ── Wall ──
                  else if (barriers.contains(index)) {
                    return MyCell(
                      innercolor: Colors.green[800],
                      outercolor: Colors.green[900],
                    );
                  }
                  // ── Food dot ──
                  else if (food.contains(index)) {
                    return MyPath(
                      innercolor: Colors.yellowAccent,
                      outercolor: Colors.black,
                    );
                  }
                  // ── Empty path ──
                  else {
                    return MyPath(
                      innercolor: Colors.black,
                      outercolor: Colors.black,
                    );
                  }
                },
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _arcadeText('SCORE', score),
                        const SizedBox(height: 16),
                        _arcadeText('LEVEL', level),
                        const SizedBox(height: 16),
                        _arcadeText('MAX', max),
                      ],
                    ),
                  ),
                ),
                DPad(
                  size: 180,
                  onUp: () {
                    setState(() => direction = 'up');
                    makeMove();
                  },
                  onDown: () {
                    setState(() => direction = 'down');
                    makeMove();
                  },
                  onLeft: () {
                    setState(() => direction = 'left');
                    makeMove();
                  },
                  onRight: () {
                    setState(() => direction = 'right');
                    makeMove();
                  },
                  onUpRelease: stopGame,
                  onDownRelease: stopGame,
                  onLeftRelease: stopGame,
                  onRightRelease: stopGame,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: resetGame,
                        child: Image.asset(
                          'lib/image/start.png',
                          width: 120,
                          height: 45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: pauseGame,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pink,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PAUSE',
                            style: GoogleFonts.pressStart2p(
                              color: Colors.pink,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
