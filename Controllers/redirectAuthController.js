const PatientController = require("./Roles Auth Controllers/patientAuthController");
const DoctorController = require("./Roles Auth Controllers/doctorAuthController"); // Assuming you have similar controllers for doctors
const AdminController = require("./Roles Auth Controllers/adminAuthController"); // Similarly for admins
const SuperAdminController = require("./Roles Auth Controllers/superAdminAuthController"); // Similarly for superadmins
const DeviceController = require("./Roles Auth Controllers/deviceAuthController"); // Similarly for devices

class RedirectAuthController {
  // Redirect the register request to the appropriate controller
  static async register(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error: "Role is required to determine the appropriate controller.",
      });
    }

    switch (role.toLowerCase()) {
      case "patient":
        return PatientController.register(req, res);
      case "doctor":
        return DoctorController.register(req, res);
      case "admin":
        return AdminController.register(req, res);
      case "superadmin":
        return SuperAdminController.register(req, res);
      case "device":
        return DeviceController.register(req, res);
      default:
        return res.status(400).json({ error: "Invalid role specified." });
    }
  }

  // Redirect the login request to the appropriate controller
  static async login(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error: "Role is required to determine the appropriate controller.",
      });
    }

    switch (role.toLowerCase()) {
      case "patient":
        return PatientController.login(req, res);
      case "doctor":
        return DoctorController.login(req, res);
      case "admin":
        return AdminController.login(req, res);
      case "superadmin":
        return SuperAdminController.login(req, res);

      case "device":
        return DeviceController.login(req, res);
      default:
        return res.status(400).json({ error: "Invalid role specified." });
    }
  }
}

module.exports = RedirectAuthController;
