const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "supersecretkeythatnobodyknows";

/**
 * Middleware function to authenticate user by verifying the JWT token.
 *
 * @param {Object} req - The HTTP request object which contains the headers with the token.
 * @param {Object} res - The HTTP response object to send responses back to the client.
 * @param {Function} next - A callback function to pass control to the next middleware or route handler.
 *
 * @returns {void} If token is valid, it calls the next middleware, else returns a 401 or 400 response.
 */

const authenticate = (req, res, next) => {
  // Extract the JWT token from the "authentication" header
  const token = req.headers.authentication;

  // If no token is provided, deny access with a 401 error
  if (!token) {
    return res.status(401).json({
      error: "jwtAuth - Authenticate: Access denied. No token provided.",
    });
  }

  try {
    // Verify the token using the secret key
    const decoded = jwt.verify(token, JWT_SECRET);

    // Attach the decoded user information to the request object for further use
    req.headers.user = decoded;
    req.body["role"] =
      // Proceed to the next middleware or route handler
      next();
  } catch (error) {
    // If the token is invalid, return a 400 error
    res.status(400).json({ error: "jwtAuth - Authenticate: Invalid token." });
  }
};

// Export the authenticate function for use in other parts of the application
module.exports = { authenticate };
