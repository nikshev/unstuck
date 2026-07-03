// "TypeError: x is not a function" — the two most common causes.

// Cause 1 — a typo in the method name. Arrays have forEach (capital E), not foreach.
const numbers = [3, 1, 2];
try {
  numbers.foreach(n => console.log(n));
} catch (e) {
  console.error(`1) ${e.name}: ${e.message}`);
}

// Cause 2 — the value isn't what you think. Wrong casing => property is undefined.
const api = { getUser: () => 'Al' };
try {
  api.getuser();               // there is no getuser -> undefined -> not a function
} catch (e) {
  console.error(`2) ${e.name}: ${e.message}`);
}
