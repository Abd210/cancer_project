const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Device = require("../Models/Device");
const mongoose = require("mongoose");

const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "supersecretkeythatnobodyknows";

// Mapping roles to corresponding Mongoose models
const collections = {
  patient: Patient,
  doctor: Doctor,
  admin: Admin,
  superadmin: SuperAdmin,
  device: Device,
};

// /** 
//  * @param req HTTP request
//  * @param res HTTP response
//  * @param next Callback function
// */

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

    // Proceed to the next middleware or route handler
    next();
  } catch (error) {

    // If the token is invalid, return a 400 error
    res.status(400).json({ error: "jwtAuth - Authenticate: Invalid token." });
  }
};

/**
 * Middleware function to authorize users based on their roles and verify their existence in the database.
 * 
 * @param {Array|string} roles - A role or an array of roles that are allowed to access the resource.
 *    If a single role is passed as a string, it will be converted into an array.
 * 
 * @returns {Function} Returns an async function which checks the user's role and existence in the database.
 */

const authorize = (roles = []) => {
  // If roles is provided as a string, convert it to an array for easier checking
  if (typeof roles === "string") {
    roles = [roles];
  }

  return async (req, res, next) => {
    try {
      // Check if the user is authenticated and their role is included in the allowed roles
      if (!req.headers.user || !roles.includes(req.headers.user.role)) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Forbidden" });
      }

      // Get the corresponding model based on the user's role
      const Model = collections[req.headers.user.role];

      // If no model exists for the user role, return a forbidden error
      if (!Model) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Forbidden" });
      }

      // Check if the user's _id exists in the respective model's collection
      const exists = await Model.exists({ _id: req.headers.user._id });

       // If the user does not exist in the collection, return an unauthorized error
      if (!exists) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Unauthorized" });
      }

      // If everything is fine, proceed to the next middleware or route handler
      next();
    } catch (error) {
      console.error("Authorization error:", error);
      // In case of an internal error, return a 500 error
      return res
        .status(500)
        .json({ error: "jwtAuth - Authorize: Internal Server Error" });
    }
  };
};

// Export the authenticate and authorize functions for use in other parts of the application
module.exports = { authenticate, authorize };
