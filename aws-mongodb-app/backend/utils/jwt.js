const jwt = require('jsonwebtoken');

/**
 * Generate JWT token
 * @param {string} userId - User ID to encode in token
 * @param {object} options - Additional options for token generation
 * @returns {string} JWT token
 */
const generateToken = (userId, options = {}) => {
  const payload = { userId };
  
  // Add additional payload data if provided
  if (options.role) payload.role = options.role;
  if (options.email) payload.email = options.email;
  
  const tokenOptions = {
    expiresIn: options.expiresIn || process.env.JWT_EXPIRE || '7d',
    issuer: process.env.APP_NAME || 'AWS MongoDB Backend',
    audience: 'aws-mongodb-app-users'
  };

  return jwt.sign(payload, process.env.JWT_SECRET, tokenOptions);
};

/**
 * Generate refresh token (longer expiration)
 * @param {string} userId - User ID to encode in token
 * @returns {string} Refresh token
 */
const generateRefreshToken = (userId) => {
  return jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_SECRET,
    {
      expiresIn: '30d',
      issuer: process.env.APP_NAME || 'AWS MongoDB Backend',
      audience: 'aws-mongodb-app-users'
    }
  );
};

/**
 * Verify JWT token
 * @param {string} token - JWT token to verify
 * @returns {object} Decoded token payload
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET, {
      issuer: process.env.APP_NAME || 'AWS MongoDB Backend',
      audience: 'aws-mongodb-app-users'
    });
  } catch (error) {
    throw error;
  }
};

/**
 * Decode JWT token without verification (for debugging)
 * @param {string} token - JWT token to decode
 * @returns {object} Decoded token
 */
const decodeToken = (token) => {
  return jwt.decode(token, { complete: true });
};

/**
 * Extract token from Authorization header
 * @param {string} authHeader - Authorization header value
 * @returns {string|null} Extracted token or null
 */
const extractTokenFromHeader = (authHeader) => {
  if (!authHeader) return null;
  
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null;
  
  return parts[1];
};

/**
 * Check if token is expired
 * @param {string} token - JWT token to check
 * @returns {boolean} True if token is expired
 */
const isTokenExpired = (token) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) return true;
    
    const currentTime = Math.floor(Date.now() / 1000);
    return decoded.exp < currentTime;
  } catch (error) {
    return true;
  }
};

module.exports = {
  generateToken,
  generateRefreshToken,
  verifyToken,
  decodeToken,
  extractTokenFromHeader,
  isTokenExpired
};
