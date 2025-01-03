const AuthService = require("../../Services/authService");

/**
 * PatientAuthController handles the authentication-related actions for patients.
 * It includes methods for patient registration and login.
 * The controller interacts with AuthService to perform the registration and login logic.
 * 
 * This controller ensures that the required fields for both registration and login are present
 * and handles the authentication process for patients.
 */
class PatientAuthController {

  /**
   * Registers a new patient by verifying and saving the provided details.
   * It checks if all required fields are present and then calls the AuthService to handle registration logic.
   * 
   * @param {Object} req - The Express request object, containing the details to register the patient.
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
        mobile_number,
        email,
        status,
        problem,
        birth_date,
        medicalHistory,
        hospital_id,
      } = req.body;

      // Check for required fields for Patient
      if (
        !pers_id ||
        !name ||
        !password ||
        !mobile_number ||
        !email ||
        !status ||
        !problem ||
        !birth_date ||
        !medicalHistory ||
        !hospital_id
      ) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "pers. id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${
            !mobile_number ? "mobile number, " : ""
          }${!email ? "email, " : ""}${!status ? "status, " : ""}${
            !problem ? "problem, " : ""
          }${!birth_date ? "date of birth, " : ""}${
            !medicalHistory ? "medical history, " : ""
          }${!hospital_id ? "hospital id" : ""}`.slice(0, -2),
        });
      }

      // Call the AuthService to handle the patient registration logic
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "patient", // Ensure the role is 'patient'
        mobile_number,
        email,
        status,
        problem,
        birth_date,
        medicalHistory,
        hospital: hospital_id,
      });

      // Return the result of the registration
      res.status(201).json(result);
    } catch (error) {
      // Catch any errors during registration and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `patientAuthController-Register: ${error.message}` });
    }
  }

  /**
   * Logs in a patient by verifying the provided credentials (either pers_id, email, name, phone_number, or device_id, along with password).
   * Calls the AuthService to authenticate the patient and return an authentication token.
   * 
   * @param {Object} req - The Express request object, containing the login credentials.
   * @param {Object} res - The Express response object, used to send the authentication result or error message.
   * 
   * @returns {Object} A JSON response containing either the login result (token) or an error message.
   */
  static async login(req, res) {
    try {
      // Destructure the login credentials from the request body
      const { pers_id, name, phone_number, email, device_id, password } =
        req.body;

      // Determine the login identifier (could be pers_id, email, name, phone_number, or device_id)
      const identifier = pers_id || email || name || phone_number || device_id;

      // Check for required fields for login
      if (!identifier | !password) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "ID, " : ""}${
            !email ? "email, " : ""
          }${!name ? "name " : ""}${!phone_number ? "phone number, " : ""}${
            !password ? "password" : ""
          }`.slice(0, -2),
        });
      }

      // Call the AuthService to authenticate the patient using the provided credentials
      const result = await AuthService.login({
        identifier,
        password,
        role: "patient", // Ensure the role is 'patient'
      });

      // Return the result of the login (usually a token)
      res.status(200).json(result);
    } catch (error) {
      // Catch any errors during login and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `patientAuthController-Login:${error.message}` });
    }
  }
}

module.exports = PatientAuthController;
