// The fix: call the method that actually EXISTS (right name, right casing),
// and diagnose with typeof before you call.

const numbers = [3, 1, 2];
console.log('typeof numbers.forEach =', typeof numbers.forEach); // 'function'
numbers.forEach(n => console.log('  n =', n));                    // correct: forEach

const api = { getUser: () => 'Al' };
console.log('typeof api.getUser  =', typeof api.getUser);        // 'function'
console.log('  user =', api.getUser());                          // correct casing

console.log('fixed — everything is callable');
