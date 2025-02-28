const Device = require("../Models/Device");

const SuperAdminService = require("../Services/superadminService.js");
const AdminService = require("../Services/adminService");
const PatientService = require("../Services/patientService");
const DoctorService = require("../Services/doctorService");

const identifyUserRole = async (req, res, next) => {
  let { email, mobileNumber } = req.body;
  try {
    let user = null;

    try {
      user = await PatientService.findPatient(null, email, mobileNumber);
    } catch (error) {
      console.error("Error finding patient:", error);
    }

    if (!user) {
      try {
        user = await DoctorService.findDoctor(null, email, mobileNumber);
      } catch (error) {
        console.error("Error finding doctor:", error);
      }
    }

    if (!user) {
      try {
        user = await AdminService.findAdmin(null, email, mobileNumber);
      } catch (error) {
        console.error("Error finding admin:", error);
      }
    }

    if (!user) {
      try {
        user = await SuperAdminService.findSuperAdmin(
          null,
          email,
          mobileNumber
        );
      } catch (error) {
        console.error("Error finding superadmin:", error);
      }
    }

    if (!user) {
      res
        .status(400)
        .json({ error: "roleAuth - IdentifyUserRole: Invalid user" });
      return;
    }

    req.headers["role"] = user.role;
    next();
  } catch (roleIdentificationError) {
    res.status(400).json({
      error: `roleAuth - IdentifyUserRole: ${roleIdentificationError}`,
    });
  }
};

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
      return res
        .status(500)
        .json({ error: "jwtAuth - Authorize: Internal Server Error" });
    }
  };
};

module.exports = { identifyUserRole, authorize };
