// controllers/patientController.js
const AuthService = require("../../Services/authService");

class PatientController {
  static async register(req, res) {
    try {
      const {
        pers_id,
        name,
        password,
        mobile_number,
        email,
        status,
        problem,
        dateOfBirth,
        medicalHistory,
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
        !dateOfBirth ||
        !medicalHistory
      ) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "ID, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${
            !mobile_number ? "mobile_number, " : ""
          }${!email ? "email, " : ""}${!status ? "status, " : ""}${
            !problem ? "problem, " : ""
          }${!dateOfBirth ? "dateOfBirth, " : ""}${
            !medicalHistory ? "medicalHistory, " : ""
          }`.slice(0, -2),
        });
      }

      // Register the patient
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "patient",
        mobile_number,
        email,
        status,
        problem,
        dateOfBirth,
        medicalHistory,
      });
      res.status(201).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `patientAuthController-Register: ${error.message}` });
    }
  }

  static async login(req, res) {
    try {
      const { pers_id, name, phone_number, email, password } = req.body;

      // Determine the login identifier
      const loginIdentifier = pers_id || email || name || phone_number;

      // Check for required fields for login
      if (!loginIdentifier | !password) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "ID, " : ""}${
            !email ? "email, " : ""
          }${!name ? "name " : ""}${!phone_number ? "phone number, " : ""}${
            !password ? "password" : ""
          }`.slice(0, -2),
        });
      }

      // Authenticate the patient
      const result = await AuthService.login({
        loginIdentifier,
        password,
        role: "patient",
      });

      // Return the token
      res.status(200).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `patientAuthController-Login:${error.message}` });
    }
  }
}

module.exports = PatientController;
