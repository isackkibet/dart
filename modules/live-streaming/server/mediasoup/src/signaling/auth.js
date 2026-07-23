import jwt from "jsonwebtoken";

export function verifyJoinToken({ token, jwtSecret, roomId, role }) {
  if (!token) {
    throw new Error("Missing JWT token");
  }

  const claims = jwt.verify(token, jwtSecret);

  if (claims.roomId && claims.roomId !== roomId) {
    throw new Error("JWT roomId mismatch");
  }

  if (claims.role && claims.role !== role) {
    throw new Error("JWT role mismatch");
  }

  return claims;
}
