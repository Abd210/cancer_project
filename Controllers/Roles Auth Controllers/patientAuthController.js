const AuthService = require("../../Services/authService");

class PatientAuthController {
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
        birth_date,
        medicalHistory,
        hospital: hospital_id,
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
      const { pers_id, name, phone_number, email, device_id, password } =
        req.body;

      // Determine the login identifier
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

      // Authenticate the patient
      const result = await AuthService.login({
        identifier,
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

module.exports = PatientAuthController;
