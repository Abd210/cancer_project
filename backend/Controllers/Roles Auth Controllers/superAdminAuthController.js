// controllers/superAdminController.js
const AuthService = require("../../Services/authService");

/**
 * SuperAdminAuthController handles the authentication-related actions for SuperAdmins.
 * It includes methods for SuperAdmin registration and login.
 * The controller interacts with AuthService to perform the registration and login logic.
 *
 * This controller ensures that the required fields for both registration and login are present
 * and handles the authentication process for SuperAdmins.
 */
class SuperAdminAuthController {
  /**
   * Registers a new SuperAdmin by verifying and saving the provided details.
   * It checks if all required fields are present and then calls the AuthService to handle registration logic.
   *
   * @param {Object} req - The Express request object, containing the details to register the SuperAdmin.
   * @param {Object} res - The Express response object, used to send the result or error message.
   *
   * @return {Object} A JSON response containing either the result of the registration or an error message.
   */
  static async register(req, res) {
    try {
      // Destructure the required fields from the request body
      const { persId, name, password, mobileNumber, email } = req.body;

      // Check for required fields for SuperAdmin registration
      if (!persId || !name || !password || !mobileNumber || !email) {
        return res.status(400).json({
          error: `Missing required fields: ${!persId ? "personal id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${
            !mobileNumber ? "mobile number, " : ""
          }${!email ? "email" : ""}`,
        });
      }

      // Call the AuthService to handle the SuperAdmin registration logic
      const result = await AuthService.register({
        persId,
        name,
        password,
        role: "superadmin", // Ensure the role is 'superadmin'
        mobileNumber,
        email,
      });

      // Return the result of the registration
      res.status(201).json(result);
    } catch (error) {
      // Catch any errors during registration and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `SuperAdminAuthController-Register: ${error.message}` });
    }
  }

  /**
   * Logs in a SuperAdmin by verifying the provided credentials (either persId, email, or mobileNumber, along with password).
   * Calls the AuthService to authenticate the SuperAdmin and return an authentication token.
   *
   * @param {Object} req - The Express request object, containing the login credentials.
   * @param {Object} res - The Express response object, used to send the authentication result or error message.
   *
   * @return {Object} A JSON response containing either the login result (token) or an error message.
   */
  static async login(req, res) {
    try {
      const { persId, email, mobileNumber, password } = req.body;

      // Determine the login identifier
      const identifier = persId || email || mobileNumber;

      // Check for required fields for login
      if (!identifier || !password) {
        return res.status(400).json({
          error:
            `SuperAdminAuthController - Login SuperAdmin: Missing required fields:${
              !persId ? "personal id, " : ""
            }${!email ? "email, " : ""}${
              !mobileNumber ? "mobile number, " : ""
            }${!password ? "password, " : ""}`.split(0, -2),
        });
      }

      // Call the AuthService to authenticate the SuperAdmin using the provided credentials
      const result = await AuthService.login({
        identifier,
        password,
        role: "superadmin", // Ensure the role is 'superadmin'
      });

      // Return the result of the login (usually a token)
      res.status(200).json(result);
    } catch (error) {
      // Catch any errors during login and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `SuperAdminAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = SuperAdminAuthController;
