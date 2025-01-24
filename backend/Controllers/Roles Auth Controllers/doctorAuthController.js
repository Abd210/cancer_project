// controllers/doctorAuthController.js
const AuthService = require("../../Services/authService");

/**
 * DoctorAuthController handles the authentication-related actions for doctors.
 * It includes methods for doctor registration and login.
 * The controller communicates with the AuthService to process the registration and login logic.
 */
class DoctorAuthController {
   /**
   * Registers a new doctor by verifying and saving the provided details.
   * It checks if all required fields are present and then calls the AuthService to handle registration logic.
   * 
   * @param {Object} req - The Express request object, containing the details to register the doctor.
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
        birth_date,
        licenses,
        description,
        hospital,
        suspended,
      } = req.body;

      // Check for required fields for Doctor registration
      if (
        !pers_id ||
        !name ||
        !password ||
        !email ||
        !mobile_number ||
        !birth_date ||
        !licenses ||
        !hospital
      ) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "pers. id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${!email ? "email, " : ""}${
            !mobile_number ? "mobile number, " : ""
          }${!birth_date ? "birth date, " : ""}${
            !licenses ? "licenses, " : ""
          }${!hospital ? "hospital" : ""}`.slice(0, -2),
        });
      }

      // Call the AuthService to handle the doctor registration logic
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "doctor", // Set the role as 'doctor'
        email,
        mobile_number,
        birth_date,
        licenses,
        description,
        hospital,
        suspended
      });

      // Return the result of the registration
      res.status(201).json(result);
    } catch (error) {
      // Catch any errors during registration and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `DoctorAuthController-Register: ${error.message}` });
    }
  }

  /**
   * Logs in a doctor by verifying the provided credentials (either pers_id, email, or mobile_number, along with password).
   * Calls the AuthService to authenticate the doctor and return an authentication token.
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

      // Call the AuthService to authenticate the doctor using the provided credentials
      const result = await AuthService.login({
        identifier,
        password,
        role: "doctor", // Ensure the role is 'doctor'
      });

      // Return the result of the login (usually a token)
      res.status(200).json(result);
    } catch (error) {
      // Catch any errors during login and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `DoctorAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = DoctorAuthController;
