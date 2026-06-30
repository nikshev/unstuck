// A user object — but this one has no "address" field
const user = { name: "Ada", age: 36 };

console.log("Name:", user.name);

// BUG: we assume every user has an address.
// user.address is undefined, and reading .city OF undefined throws.
console.log("City:", user.address.city);
