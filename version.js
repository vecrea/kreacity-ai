// Kreacity AI Version Information
const version = {
  version: "1.5.0",
  lastUpdate: "2025-03-26",
  features: [
    "Added Ollama for local LLM and embedding processing",
    "Standardized vector size to 1024 dimensions for universal compatibility",
    "Added web UI dashboard for easy service navigation",
    "Fixed compatibility issues with ARM64 architecture (Apple Silicon)",
    "Improved documentation and integration guides",
    "Replaced localtunnel with ngrok for more reliable external access"
  ]
};

console.log("Kreacity AI Version:", version.version);
console.log("Last Updated:", version.lastUpdate);
console.log("Latest Features:");
version.features.forEach((feature, index) => {
  console.log(`  ${index + 1}. ${feature}`);
});

module.exports = version;
