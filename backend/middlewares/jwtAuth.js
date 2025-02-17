const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Device = require("../Models/Device");

const SuperAdminService = require("../Services/superadminService.js");
const DeviceService = require("../Services/deviceService");
const AdminService = require("../Services/adminService");
const PatientService = require("../Services/patientService");
const DoctorService = require("../Services/doctorService");

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

/**
 * Middleware function to authorize users based on their roles and verify their existence in the database.
 *
 * @param {Array|string} roles - A role or an array of roles that are allowed to access the resource.
 * @returns {Function} Middleware function to check role and existence in the database.
 */
const authorize = (roles = []) => {
  if (typeof roles === "string") {
    roles = [roles];
  }

  return async (req, res, next) => {
    try {
      const user = req.headers.user;

      if (!user || !roles.includes(user.role)) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Forbidden" });
      }

      try {
        switch (user.role) {
          case "patient":
            exists = await PatientService.getPatientData(user.id);
            break;
          case "doctor":
            exists = await DoctorService.getDoctorData(user.id);
            break;
          case "admin":
            exists = await AdminService.findAdmin(user.id);
            break;
          case "superadmin":
            exists = await SuperAdminService.findSuperAdmin(user.id);
            break;
          case "device":
            exists = await Device.exists({ _id: user.id });
            break;
          default:
            return res
              .status(403)
              .json({ error: "jwtAuth - Authorize: Forbidden" });
        }
        next(); // Proceed to the next middleware
      } catch (error) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Unauthorized" });
      }
    } catch (error) {
      console.error("Authorization error:", error);
      return res
        .status(500)
        .json({ error: "jwtAuth - Authorize: Internal Server Error" });
    }
  };
};
// Export the authenticate and authorize functions for use in other parts of the application
module.exports = { authenticate, authorize };
