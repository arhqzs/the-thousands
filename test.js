/* Quick sanity tests for the core logic. Run: node test.js */
var T = require('./www/logic.js');
var pass = 0, fail = 0;

function eq(label, got, want) {
  var ok = JSON.stringify(got) === JSON.stringify(want);
  console.log((ok ? 'PASS ' : 'FAIL ') + label +
    (ok ? '' : '  got=' + JSON.stringify(got) + ' want=' + JSON.stringify(want)));
  ok ? pass++ : fail++;
}

/* Scoring examples straight from the rules sheet */
eq('6-6-6-5 => 6665',      T.computeScore([6, 6, 6, 5]).score, 6665);
eq('6-4-3-3 => 6433',      T.computeScore([6, 4, 3, 3]).score, 6433);
eq('order independent',    T.computeScore([3, 6, 3, 4]).score, 6433);
eq('6-6-6-6 => 66660',     T.computeScore([6, 6, 6, 6]).score, 66660);
eq('5-5-5-5 => 55550',     T.computeScore([5, 5, 5, 5]).score, 55550);
eq('quad flag set',        T.computeScore([2, 2, 2, 2]).isQuad, true);
eq('non-quad flag clear',  T.computeScore([2, 2, 2, 1]).isQuad, false);

/* "Any four of a kind beats all non-four-of-a-kind scores" */
eq('weakest quad > best non-quad',
   T.computeScore([1, 1, 1, 1]).score > T.computeScore([6, 6, 6, 5]).score, true);

/* Elimination + gammon */
eq('lowest eliminated',
   T.evaluateElimination([{ id: 'a', score: 5000 }, { id: 'b', score: 3000 }]).eliminatedIds,
   ['b']);
eq('gammon when gap >= 1000',
   T.evaluateElimination([{ id: 'a', score: 5000 }, { id: 'b', score: 3000 }]).gammon,
   true);
eq('no gammon when gap < 1000',
   T.evaluateElimination([{ id: 'a', score: 4000 }, { id: 'b', score: 3500 }]).gammon,
   false);
eq('tie at bottom => both out',
   T.evaluateElimination([{ id: 'a', score: 3000 }, { id: 'b', score: 3000 }, { id: 'c', score: 4500 }]).eliminatedIds.sort(),
   ['a', 'b']);
eq('full tie => push',
   T.evaluateElimination([{ id: 'a', score: 3000 }, { id: 'b', score: 3000 }]).push,
   true);

console.log('\n' + pass + ' passed, ' + fail + ' failed');
process.exit(fail ? 1 : 0);
