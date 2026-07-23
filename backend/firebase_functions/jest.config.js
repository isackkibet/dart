module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["**/test/**/*.test.ts", "**/src/**/*.test.ts"],
  moduleNameMapper: {
    "^../shared/firebaseAdmin$": "<rootDir>/src/__mocks__/firebaseAdmin.ts",
    "^../../shared/firebaseAdmin$": "<rootDir>/src/__mocks__/firebaseAdmin.ts"
  }
};
