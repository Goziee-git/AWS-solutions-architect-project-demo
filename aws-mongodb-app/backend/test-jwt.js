require('dotenv').config();
const { generateToken, generateRefreshToken, verifyToken, isTokenExpired } = require('./utils/jwt');

console.log('Testing JWT functionality...\n');

// Test token generation
const testUserId = '507f1f77bcf86cd799439011';
console.log('1. Generating tokens...');
const token = generateToken(testUserId, { role: 'user', email: 'test@example.com' });
const refreshToken = generateRefreshToken(testUserId);

console.log('Access Token:', token);
console.log('Refresh Token:', refreshToken);
console.log('');

// Test token verification
console.log('2. Verifying tokens...');
try {
  const decodedToken = verifyToken(token);
  console.log('Access Token Decoded:', decodedToken);
  
  const decodedRefreshToken = verifyToken(refreshToken);
  console.log('Refresh Token Decoded:', decodedRefreshToken);
} catch (error) {
  console.error('Token verification failed:', error.message);
}
console.log('');

// Test token expiration check
console.log('3. Checking token expiration...');
console.log('Access Token Expired:', isTokenExpired(token));
console.log('Refresh Token Expired:', isTokenExpired(refreshToken));
console.log('');

// Test with invalid token
console.log('4. Testing invalid token...');
try {
  verifyToken('invalid.token.here');
} catch (error) {
  console.log('Invalid token correctly rejected:', error.message);
}

console.log('\nJWT functionality test completed!');
