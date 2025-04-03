const PatientAuthController = require("./Roles Auth Controllers/patientAuthController");
const DoctorAuthController = require("./Roles Auth Controllers/doctorAuthController"); // Assuming you have similar controllers for doctors
const AdminAuthController = require("./Roles Auth Controllers/adminAuthController"); // Similarly for admins
const SuperAdminAuthController = require("./Roles Auth Controllers/superadminAuthController"); // Similarly for superadmins
const DeviceAuthController = require("./Roles Auth Controllers/deviceAuthController"); // Similarly for devices
const AuthService = require("../Services/authService");

/**
 * RedirectAuthController handles the routing of authentication-related requests to the
 * appropriate role-specific controllers. It includes methods for registering, logging in,
 * resetting passwords, and handling forgotten passwords.
 *
 * The controller ensures that requests are directed to the correct controller based on the role
 * provided in the request body. The role-specific controllers handle the actual logic for registration,
 * login, and password management.
 */
class RedirectAuthController {
  /**
   * Registers a user by redirecting the request to the appropriate role-specific controller.
   * The role is determined from the request body, and the corresponding controller's register method is called.
   *
   * @param {Object} req - The Express request object containing the registration details.
   * @param {Object} res - The Express response object used to send the result or error message.
   *
   * @returns {Object} A JSON response with either the result of the registration or an error message.
   */
  static async register(req, res) {
    const { role } = req.body;

    // Check if the role is provided in the request body
    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController-Register: Role is required to determine the appropriate controller.",
      });
    }

    // Direct the request to the appropriate controller based on the role
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

  /**
   * Logs in a user by redirecting the request to the appropriate role-specific controller.
   * The role is determined from the request body, and the corresponding controller's login method is called.
   *
   * @param {Object} req - The Express request object containing the login credentials.
   * @param {Object} res - The Express response object used to send the result or error message.
   *
   * @returns {Object} A JSON response with either the result of the login or an error message.
   */
  static async login(req, res) {
    const { role } = req.headers;

    // Check if the role is provided in the request headers
    if (!role) {
      return res.status(400).json({
        error:
          "redirectAuthController-Login: Role is required to determine the appropriate controller.",
      });
    }

    // Direct the request to the appropriate controller based on the role
    switch (role.toLowerCase()) {
      case "patient":
        return PatientAuthController.login(req, res);
      case "doctor":
        return DoctorAuthController.login(req, res);
      case "admin":
        return AdminAuthController.login(req, res);
      case "superadmin":
        return SuperAdminAuthController.login(req, res);

      case "device":
        return DeviceAuthController.login(req, res);
      default:
        return res.status(400).json({
          error: "redirectAuthController-Login: Invalid role specified.",
        });
    }
  }

  /**
   * Handles the forgotten password scenario by sending a password reset email.
   * The request is routed based on the provided role, and the corresponding service is called.
   *
   * @param {Object} req - The Express request object containing the role, email, and/or mobile number.
   * @param {Object} res - The Express response object used to send the result or error message.
   *
   * @returns {Object} A JSON response with either the result of the password reset process or an error message.
   */
  static async forgotPassword(req, res) {
    const { role, email, mobile_number } = req.body;

    // Check if the role is valid
    if (!(role in ["patient", "doctor", "admin", "superadmin"])) {
      return res.status(400).json({
        error: "redirectAuthController-Forgot Pass: Invalid role specified.",
      });
    }

    // Check if at least one of the contact details (email or mobile number) is provided
    if (!email && !mobile_number) {
      return res.status(400).json({
        error: `redirectAuthController-Forgot Pass: email or mobile number is required.`,
      });
    }

    // Call the AuthService to handle the password reset logic for the provided role
    return AuthService.forgotPassword({ role, email, mobile_number });
  }

  /**
   * Resets a user's password using the provided token and new password.
   * The request is routed based on the role, and the corresponding service is called to handle the reset process.
   *
   * @param {Object} req - The Express request object containing the role, email, new password, and token.
   * @param {Object} res - The Express response object used to send the result or error message.
   *
   * @returns {Object} A JSON response with either the result of the password reset or an error message.
   */
  static async resetPassword(req, res) {
    const { role, email, new_password, token } = req.body;

    // Check if the role is valid
    if (!(role in ["patient", "doctor", "admin", "superadmin"])) {
      return res.status(400).json({
        error: "redirectAuthController-Reset Pass: Invalid role specified.",
      });
    }

    // Ensure required fields are provided
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

    // Logic for validating the token can be implemented here

    // Call the AuthService to reset the password for the provided role and credentials
    return AuthService.resetPassword({ role, email, new_password, token });
  }
}

module.exports = RedirectAuthController;
