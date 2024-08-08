// test/jest/your-jest-tests.spec.js


const { sum } = require('../../src/sum.js');

describe('sum', () => {
  it('should return the sum of two numbers', () => {
    expect(sum(1, 2)).toBe(3);
    expect(sum(-1, 1)).toBe(0);
    expect(sum(-1, -1)).toBe(-2);
  });

  it('should return NaN when adding non-numeric values', () => {
    expect(sum(1, 'a')).toBeNaN();
    expect(sum('a', 'b')).toBeNaN();
  });
});

