// controllers/doctorAuthController.js
const AuthService = require("../../Services/authService");

class DoctorAuthController {
  static async register(req, res) {
    try {
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
      } = req.body;

      // Check for required fields for Doctor
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

      // Register the Doctor
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "doctor",
        email,
        mobile_number,
        birth_date,
        licenses,
        description,
        hospital,
      });
      res.status(201).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `DoctorAuthController-Register: ${error.message}` });
    }
  }

  static async login(req, res) {
    try {
      const { pers_id, email, mobile_number, password } = req.body;

      // Determine the login identifier
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

      // Authenticate the Doctor
      const result = await AuthService.login({
        identifier,
        password,
        role: "doctor",
      });

      // Return the token
      res.status(200).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `DoctorAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = DoctorAuthController;
