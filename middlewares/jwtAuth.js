const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Device = require("../Models/Device");
const mongoose = require("mongoose");

const jwt = require("jsonwebtoken");
const JWT_SECRET = process.env.JWT_SECRET || "supersecretkeythatnobodyknows";

const collections = {
  patient: Patient,
  doctor: Doctor,
  admin: Admin,
  superadmin: SuperAdmin,
  device: Device,
};

const authenticate = (req, res, next) => {
  const { token } = req.body;
  if (!token)
    return res.status(401).json({
      error: "jwtAuth - Authenticate: Access denied. No token provided.",
    });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(400).json({ error: "jwtAuth - Authenticate: Invalid token." });
  }
};

const authorize = (roles = []) => {
  if (typeof roles === "string") {
    roles = [roles];
  }

  return async (req, res, next) => {
    try {
      // Check if user is authenticated and role is allowed
      if (!req.user || !roles.includes(req.user.role)) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Forbidden" });
      }
      // Validate user ID against the corresponding collection
      const Model = collections[req.user.role];
      if (!Model) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Forbidden" });
      }
      // Check if the _id exists in the respective collection
      const exists = await Model.exists({ _id: req.user.id });
      if (!exists) {
        return res
          .status(403)
          .json({ error: "jwtAuth - Authorize: Unauthorized" });
      }

      next();
    } catch (error) {
      console.error("Authorization error:", error);
      return res
        .status(500)
        .json({ error: "jwtAuth - Authorize: Internal Server Error" });
    }
  };
};

module.exports = { authenticate, authorize };
