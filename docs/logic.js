/* ==========================================================================
   THE THOUSANDS — core game logic (pure, no DOM)
   Shared by the browser UI (index.html) and the Node test suite (test.js).
   ========================================================================== */
(function (root) {
  'use strict';

  /* ---- Dice ------------------------------------------------------------- */

  function rollDie() {
    return 1 + Math.floor(Math.random() * 6);
  }

  function rollFour() {
    return [rollDie(), rollDie(), rollDie(), rollDie()];
  }

  /* ---- Scoring ---------------------------------------------------------- *
   * Sort the four dice high->low. The dice read as a number:
   *   thousands, hundreds, tens, ones.   e.g. 6-6-6-5 => 6665, 6-4-3-3 => 6433
   * Four of a kind: append a zero (multiply the 4-digit reading by 10),
   *   e.g. 6-6-6-6 => 66660, 5-5-5-5 => 55550.
   * Because the smallest four-of-a-kind (1111 -> 11110) is larger than the
   * largest non-quad (6-6-6-5 -> 6665), a plain numeric compare already makes
   * "any four of a kind beat all non-four-of-a-kind scores".
   * --------------------------------------------------------------------- */
  function computeScore(dice) {
    var sorted = dice.slice().sort(function (a, b) { return b - a; });
    var isQuad = sorted.every(function (d) { return d === sorted[0]; });
    var reading = sorted[0] * 1000 + sorted[1] * 100 + sorted[2] * 10 + sorted[3];
    var score = isQuad ? reading * 10 : reading;
    return { sorted: sorted, score: score, isQuad: isQuad };
  }

  /* ---- Elimination + Gammon -------------------------------------------- *
   * Input: array of { id, score } for every player still active at the end
   * of the round. Returns the elimination decision.
   *   - push: every active player tied for lowest (degenerate) -> replay.
   *   - eliminatedIds: the lowest scorer(s); ties at the bottom all go out.
   *   - gammon: true when next-lowest score is >= 1000 above the lowest,
   *             in which case the eliminated player(s) pay double.
   * --------------------------------------------------------------------- */
  function evaluateElimination(players) {
    var scores = players.map(function (p) { return p.score; });
    var min = Math.min.apply(null, scores);
    var lowest = players.filter(function (p) { return p.score === min; });

    if (lowest.length === players.length) {
      return { push: true, min: min };
    }

    var higher = players
      .filter(function (p) { return p.score > min; })
      .map(function (p) { return p.score; });
    var nextLowest = Math.min.apply(null, higher);
    var gammon = (nextLowest - min) >= 1000;

    return {
      push: false,
      min: min,
      nextLowest: nextLowest,
      gammon: gammon,
      eliminatedIds: lowest.map(function (p) { return p.id; })
    };
  }

  var api = {
    rollDie: rollDie,
    rollFour: rollFour,
    computeScore: computeScore,
    evaluateElimination: evaluateElimination
  };

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;          // Node (tests)
  } else {
    root.Thousands = api;          // Browser (UI)
  }
})(typeof globalThis !== 'undefined' ? globalThis : this);
