import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Court Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CourtSchedulerScreen(),
    );
  }
}

class CourtSchedulerScreen extends StatefulWidget {
  const CourtSchedulerScreen({Key? key}) : super(key: key);

  @override
  _CourtSchedulerScreenState createState() => _CourtSchedulerScreenState();
}

class _CourtSchedulerScreenState extends State<CourtSchedulerScreen> {
  final TextEditingController _numPlayersController = TextEditingController(text: '6');
  final TextEditingController _numGamesController = TextEditingController(text: '8');
  
  // Static list of regular players
  final List<String> regularPlayers = ['Seong', 'Yen', 'Rocky', 'Ken', 'Simon', 'Heidi'];
  
  List<TextEditingController> _playerNameControllers = [];
  List<String> playerNames = [];
  Map<int, List<List<String>>> schedule = {};
  Map<int, List<String>> restingPlayers = {};
  bool isScheduleGenerated = false;
  bool showPlayerNameInputs = false;
  int numGames = 8;
  
  // Maximum player limit
  final int maxPlayers = 20;

  @override
  void initState() {
    super.initState();
    // Initialize with the 6 regular players
    playerNames = List.from(regularPlayers);
    _initPlayerControllers(6);
  }

  void _initPlayerControllers(int count) {
    // Clear existing controllers
    for (var controller in _playerNameControllers) {
      controller.dispose();
    }
    
    _playerNameControllers = [];
    
    // First add the regular players
    for (int i = 0; i < min(regularPlayers.length, count); i++) {
      _playerNameControllers.add(TextEditingController(text: regularPlayers[i]));
    }
    
    // Then add additional players if needed
    for (int i = regularPlayers.length; i < count; i++) {
      _playerNameControllers.add(TextEditingController(text: 'Player ${i + 1}'));
    }
  }

  void generateDefaultPlayerNames(int count) {
    playerNames = [];
    
    // First add the regular players
    for (int i = 0; i < min(regularPlayers.length, count); i++) {
      playerNames.add(regularPlayers[i]);
    }
    
    // Then add additional players if needed
    for (int i = regularPlayers.length; i < count; i++) {
      playerNames.add('Player ${i + 1}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Scheduler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Court Allocation Generator',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numPlayersController,
                    decoration: InputDecoration(
                      labelText: 'Number of Players (max $maxPlayers)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? numPlayers = int.tryParse(value);
                      if (numPlayers != null && numPlayers <= maxPlayers && numPlayers > 0) {
                        setState(() {
                          generateDefaultPlayerNames(numPlayers);
                          _initPlayerControllers(numPlayers);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _numGamesController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Games',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? games = int.tryParse(value);
                      if (games != null && games > 0) {
                        setState(() {
                          numGames = games;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Customize Player Names'),
                    value: showPlayerNameInputs,
                    onChanged: (value) {
                      setState(() {
                        showPlayerNameInputs = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    int? numPlayers = int.tryParse(_numPlayersController.text);
                    int? games = int.tryParse(_numGamesController.text);
                    
                    if (numPlayers != null && numPlayers <= maxPlayers && numPlayers > 0 &&
                        games != null && games > 0) {
                        
                      // Update player names from controllers if custom names are enabled
                      if (showPlayerNameInputs) {
                        playerNames = _playerNameControllers
                            .map((controller) => controller.text.isNotEmpty 
                                ? controller.text 
                                : 'Player')
                            .toList();
                      }
                      
                      setState(() {
                        numGames = games;
                        generateSchedule(numPlayers);
                        isScheduleGenerated = true;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter valid numbers for players (1-$maxPlayers) and games')),
                      );
                    }
                  },
                  child: const Text('Generate Schedule'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showPlayerNameInputs)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Player Names',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset to Default'),
                              onPressed: () {
                                setState(() {
                                  int currentCount = _playerNameControllers.length;
                                  _initPlayerControllers(currentCount);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _playerNameControllers.length,
                            itemBuilder: (context, index) {
                              bool isRegularPlayer = index < regularPlayers.length;
                              return TextField(
                                controller: _playerNameControllers[index],
                                decoration: InputDecoration(
                                  labelText: isRegularPlayer 
                                    ? 'Regular - ${regularPlayers[index]}' 
                                    : 'Player ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  filled: isRegularPlayer,
                                  fillColor: isRegularPlayer ? Colors.blue.shade50 : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!showPlayerNameInputs && !isScheduleGenerated)
              const Expanded(
                child: Center(
                  child: Text('Generate a schedule to see player allocations'),
                ),
              ),
            if (isScheduleGenerated)
              Expanded(
                child: DefaultTabController(
                  length: numGames,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: Theme.of(context).primaryColor,
                        tabs: List.generate(
                          numGames,
                          (index) => Tab(text: 'Game ${index + 1}'),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: List.generate(
                            numGames,
                            (gameIndex) => _buildGameTab(gameIndex + 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTab(int gameNumber) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game $gameNumber',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                // Courts section
                ...List.generate(3, (courtIndex) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Court ${courtIndex + 1}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(),
                          if (schedule.containsKey(gameNumber) &&
                              courtIndex < schedule[gameNumber]!.length)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...schedule[gameNumber]![courtIndex].map((player) {
                                  bool isRegularPlayer = regularPlayers.contains(player);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      player,
                                      style: isRegularPlayer 
                                        ? TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ) 
                                        : null,
                                    ),
                                  );
                                }).toList(),
                              ],
                            )
                          else
                            const Text('No players assigned to this court'),
                        ],
                      ),
                    ),
                  );
                }),
                
                // Resting players section
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hotel, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Resting Players',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        if (restingPlayers.containsKey(gameNumber) && 
                            restingPlayers[gameNumber]!.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: restingPlayers[gameNumber]!.map((player) {
                              bool isRegularPlayer = regularPlayers.contains(player);
                              return Chip(
                                backgroundColor: isRegularPlayer 
                                  ? Colors.blue.shade100 
                                  : Colors.amber.shade100,
                                avatar: isRegularPlayer
                                  ? const Icon(Icons.star, size: 16)
                                  : null,
                                label: Text(
                                  player,
                                  style: isRegularPlayer
                                    ? TextStyle(fontWeight: FontWeight.bold)
                                    : null,
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const Text('No players resting this game'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void generateSchedule(int numPlayers) {
    // Initialize players and their game counts
    Map<String, int> playerGameCounts = {};
    Map<String, int> consecutiveGames = {};
    Map<String, int> lastPlayedGame = {};
    
    for (int i = 0; i < numPlayers; i++) {
      playerGameCounts[playerNames[i]] = 0;
      consecutiveGames[playerNames[i]] = 0;
      lastPlayedGame[playerNames[i]] = 0;
    }

    // Clear previous schedule and resting players
    schedule.clear();
    restingPlayers.clear();
    
    // Generate schedule for specified number of games
    for (int gameNumber = 1; gameNumber <= numGames; gameNumber++) {
      List<List<String>> courts = [];
      List<String> availablePlayers = [];
      List<String> restingPlayersList = [];
      
      // Determine available players for this game
      for (String player in playerNames) {
        // Skip players who need to rest (played 3 consecutive games)
        if (consecutiveGames[player]! >= 3) {
          restingPlayersList.add(player);
          consecutiveGames[player] = 0; // Reset consecutive games after rest
          continue;
        }
        
        // Add to available players
        availablePlayers.add(player);
      }
      
      // Store resting players for this game
      restingPlayers[gameNumber] = restingPlayersList;
      
      // Shuffle available players to randomize court assignments
      availablePlayers.shuffle(Random());
      
      // Sort by players who have played fewer games
      availablePlayers.sort((a, b) => playerGameCounts[a]!.compareTo(playerGameCounts[b]!));
      
      // We need 12 players (4 per court x 3 courts)
      int playersNeeded = min(12, availablePlayers.length);
      List<String> selectedPlayers = availablePlayers.sublist(0, playersNeeded);
      
      // Add players who aren't selected to resting players list
      if (availablePlayers.length > playersNeeded) {
        for (int i = playersNeeded; i < availablePlayers.length; i++) {
          restingPlayers[gameNumber]!.add(availablePlayers[i]);
        }
      }
      
      // Assign players to courts (4 players per court)
      for (int i = 0; i < 3; i++) {
        List<String> courtPlayers = [];
        for (int j = 0; j < 4; j++) {
          int playerIndex = i * 4 + j;
          if (playerIndex < selectedPlayers.length) {
            String player = selectedPlayers[playerIndex];
            courtPlayers.add(player);
            
            // Update player stats
            playerGameCounts[player] = playerGameCounts[player]! + 1;
            
            // Update consecutive games
            if (gameNumber - lastPlayedGame[player]! == 1) {
              consecutiveGames[player] = consecutiveGames[player]! + 1;
            } else {
              consecutiveGames[player] = 1;
            }
            
            lastPlayedGame[player] = gameNumber;
          }
        }
        courts.add(courtPlayers);
      }
      
      schedule[gameNumber] = courts;
    }
  }
  
  @override
  void dispose() {
    _numPlayersController.dispose();
    _numGamesController.dispose();
    for (var controller in _playerNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}