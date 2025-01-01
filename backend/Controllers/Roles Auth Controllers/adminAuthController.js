// controllers/adminAuthController.js
const AuthService = require("../../Services/authService");

/**
 * AdminAuthController handles the authentication-related actions for admins.
 * It includes methods for admin registration and login.
 * The controller communicates with the AuthService to process the registration and login logic.
 */
class AdminAuthController {
  /**
   * Registers a new admin by verifying and saving the provided details.
   * It checks if all required fields are present and then calls the AuthService to handle registration logic.
   * 
   * @param {Object} req - The Express request object, containing the details to register the admin.
   * @param {Object} res - The Express response object, used to send the result or error message.
   * 
   * @returns {Object} A JSON response containing either the result of the registration or an error message.
   */
  static async register(req, res) {
    try {
      // Destructure the required fields from the request body
      const {
        pers_id,
        name,
        password,
        email,
        mobile_number,
        hospital,
      } = req.body;

      // Check for required fields for Admin registration
      if (
        !pers_id ||
        !name ||
        !password ||
        !email ||
        !mobile_number ||
        !hospital
      ) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "pers. id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${!email ? "email, " : ""}${
            !mobile_number ? "mobile number, " : ""
          }${!hospital ? "hospital" : ""}`.slice(0, -2),
        });
      }

      // Call the AuthService to handle the admin registration logic
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "admin", // Set the role as 'admin'
        email,
        mobile_number,
        hospital,
      });

      // Return the result of the registration
      res.status(201).json(result);
    } catch (error) {
      // Catch any errors during registration and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `AdminAuthController-Register: ${error.message}` });
    }
  }

  /**
   * Logs in an admin by verifying the provided credentials (either pers_id, email, or mobile_number, along with password).
   * Calls the AuthService to authenticate the admin and return an authentication token.
   * 
   * @param {Object} req - The Express request object, containing the login credentials.
   * @param {Object} res - The Express response object, used to send the authentication result or error message.
   * 
   * @returns {Object} A JSON response containing either the login result (token) or an error message.
   */
  static async login(req, res) {
    try {
      // Destructure the login credentials from the request body
      const { pers_id, email, mobile_number, password } = req.body;

      // Determine the login identifier (could be pers_id, email, or mobile_number)
      const identifier = pers_id || email || mobile_number;

      // Check for required fields for login
      if (!identifier || !password) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "pers_id, " : ""}${
            !email ? "email, " : ""
          }${!mobile_number ? "mobile_number, " : ""}${
            !password ? "password" : ""
          }`.slice(0, -2),
        });
      }

      // Call the AuthService to authenticate the admin using the provided credentials
      const result = await AuthService.login({
        identifier,
        password,
        role: "admin", // Ensure the role is 'admin'
      });

      // Return the result of the login (usually a token)
      res.status(200).json(result);
    } catch (error) {
      // Catch any errors during login and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `AdminAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = AdminAuthController;
