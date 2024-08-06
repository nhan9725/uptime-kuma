module.exports = {
    apps: [{
        name: "uptime-kuma",
        script: "./server/server.js",
    }],
     collectCoverage: true,
  coverageDirectory: "coverage",
  coverageReporters: ["lcov", "text"]	
};
