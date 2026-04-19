/// Mémorisation locale du meilleur score et de la progression par jeu.
class GameScore {
  final String gameId;
  int bestScore;
  int gamesPlayed;
  DateTime? lastPlayed;

  /// Niveau le plus élevé atteint (1-indexé).
  int highestLevel;

  GameScore({
    required this.gameId,
    this.bestScore    = 0,
    this.gamesPlayed  = 0,
    this.lastPlayed,
    this.highestLevel = 1,
  });

  factory GameScore.fromMap(Map<String, dynamic> map) => GameScore(
        gameId:       map['gameId']       as String,
        bestScore:    map['bestScore']    as int? ?? 0,
        gamesPlayed:  map['gamesPlayed']  as int? ?? 0,
        highestLevel: map['highestLevel'] as int? ?? 1,
        lastPlayed: map['lastPlayed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'] as int)
            : null,
      );

  Map<String, dynamic> toMap() => {
        'gameId':       gameId,
        'bestScore':    bestScore,
        'gamesPlayed':  gamesPlayed,
        'highestLevel': highestLevel,
        'lastPlayed':   lastPlayed?.millisecondsSinceEpoch,
      };
}
