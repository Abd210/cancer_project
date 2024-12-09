const PatientAuthController = require("./Roles Auth Controllers/patientAuthController");
const DoctorAuthController = require("./Roles Auth Controllers/doctorAuthController"); // Assuming you have similar controllers for doctors
const AdminAuthController = require("./Roles Auth Controllers/adminAuthController"); // Similarly for admins
const SuperAuthAdminController = require("./Roles Auth Controllers/superAdminAuthController"); // Similarly for superadmins
const DeviceAuthController = require("./Roles Auth Controllers/deviceAuthController"); // Similarly for devices

class RedirectAuthController {
  // Redirect the register request to the appropriate controller
  static async register(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController: Role is required to determine the appropriate controller.",
      });
    }

    switch (role.toLowerCase()) {
      case "patient":
        return PatientAuthController.register(req, res);
      case "doctor":
        return DoctorAuthController.register(req, res);
      case "admin":
        return AdminAuthController.register(req, res);
      case "superadmin":
        return SuperAdminAuthController.register(req, res);
      case "device":
        return DeviceAuthController.register(req, res);
      default:
        return res
          .status(400)
          .json({ error: "redirectAuthController: Invalid role specified." });
    }
  }

  // Redirect the login request to the appropriate controller
  static async login(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController: Role is required to determine the appropriate controller.",
      });
    }

    switch (role.toLowerCase()) {
      case "patient":
        return PatientAuthController.login(req, res);
      case "doctor":
        return DoctorAuthController.login(req, res);
      case "admin":
        return AdminAuthController.login(req, res);
      case "superadmin":
        return SuperAuthAdminController.login(req, res);

      case "device":
        return DeviceAuthController.login(req, res);
      default:
        return res
          .status(400)
          .json({ error: "redirectAuthController: Invalid role specified." });
    }
  }
}

module.exports = RedirectAuthController;
