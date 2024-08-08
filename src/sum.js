// your-code-files.js

function sum(a, b) {
  if (typeof a !== 'number' || typeof b !== 'number') {
    return NaN;
  }
  return a + b;
}

module.exports = { sum };

