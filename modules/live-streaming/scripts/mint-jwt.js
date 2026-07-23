const jwt = require("jsonwebtoken");

const secret = process.env.JWT_SECRET || "change-me-local-secret";
const role = process.argv[2] || "viewer";
const roomId = process.argv[3] || "room1";

if (!["broadcaster", "viewer"].includes(role)) {
  console.error("Role must be broadcaster or viewer");
  process.exit(1);
}

const token = jwt.sign(
  {
    sub: "local-dev-user",
    role,
    roomId,
  },
  secret,
  {
    expiresIn: "12h",
  }
);

console.log(token);
