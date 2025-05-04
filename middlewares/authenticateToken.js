const admin = require('firebase-admin');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    console.log('No token provided in request');
    return res.status(401).json({ error: 'Token required' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log('Decoded token:', decodedToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying token:', error);
    res.status(403).json({ error: 'Invalid token' });
  }
};

module.exports = authenticateToken;
