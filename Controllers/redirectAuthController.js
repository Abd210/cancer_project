const PatientAuthController = require("./Roles Auth Controllers/patientAuthController");
const DoctorAuthController = require("./Roles Auth Controllers/doctorAuthController"); // Assuming you have similar controllers for doctors
const AdminAuthController = require("./Roles Auth Controllers/adminAuthController"); // Similarly for admins
const SuperAdminAuthController = require("./Roles Auth Controllers/superadminAuthController"); // Similarly for superadmins
const DeviceAuthController = require("./Roles Auth Controllers/deviceAuthController"); // Similarly for devices
const AuthService = require("../Services/authService");
class RedirectAuthController {
  // Redirect the register request to the appropriate controller
  static async register(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController-Register: Role is required to determine the appropriate controller.",
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
        return res.status(400).json({
          error: "redirectAuthController-Register: Invalid role specified.",
        });
    }
  }

  // Redirect the login request to the appropriate controller
  static async login(req, res) {
    const { role } = req.body;

    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController-Login: Role is required to determine the appropriate controller.",
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
        return res.status(400).json({
          error: "redirectAuthController-Login: Invalid role specified.",
        });
    }
  }

  // If the user forgets their password, send an email to reset it
  static async forgotPassword(req, res) {
    const { role, email, mobile_number } = req.body;

    // Check if the role is valid
    if (!(role in ["patient", "doctor", "admin", "superadmin"])) {
      return res.status(400).json({
        error: "redirectAuthController-Forgot Pass: Invalid role specified.",
      });
    }

    if (!email && !mobile_number) {
      return res.status(400).json({
        error: `redirectAuthController-Forgot Pass: email or mobile number is required.`,
      });
    }

    return AuthService.forgotPassword({ role, email, mobile_number });
  }

  // Reset the user's password provided the token is valid
  static async resetPassword(req, res) {
    const { role, email, new_password, token } = req.body;

    // Check if the role is valid
    if (!(role in ["patient", "doctor", "admin", "superadmin"])) {
      return res.status(400).json({
        error: "redirectAuthController-Reset Pass: Invalid role specified.",
      });
    }

    // Check if the required fields are provided
    if (!email) {
      return res.status(400).json({
        error: "redirectAuthController-Reset Pass: Email is required.",
      });
    }

    if (!new_password) {
      return res.status(400).json({
        error: "redirectAuthController-Reset Pass: New password is required.",
      });
    }

    // logic for checking if the token is valid

    return AuthService.resetPassword({ role, email, new_password, token });
  }
}

module.exports = RedirectAuthController;
