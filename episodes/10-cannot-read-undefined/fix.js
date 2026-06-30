const user = { name: "Ada", age: 36 };

console.log("Name:", user.name);

// FIX: optional chaining ?. short-circuits to undefined instead of throwing,
//      and ?? supplies a fallback value.
console.log("City:", user.address?.city ?? "unknown");
