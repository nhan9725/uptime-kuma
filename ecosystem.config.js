module.exports = {
    apps: [{
        name: "uptime-kuma",
        script: "./server/server.js",
    }],
  testMatch: ['**/test/jest/**/*.spec.js'], // Adjust this pattern to match your test file locations
  collectCoverage: true,
  coverageDirectory: "coverage",
  coverageReporters: ["lcov", "text"]	
};
