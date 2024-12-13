// controllers/superAdminController.js
const AuthService = require("../../Services/authService");

class SuperAdminAuthController {
  static async register(req, res) {
    try {
      const { pers_id, name, password, mobile_number, email } = req.body;

      // Check for required fields for SuperAdmin
      if (!pers_id || !name || !password || !mobile_number || !email) {
        return res.status(400).json({
          error: `Missing required fields: ${!pers_id ? "personal id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${
            !mobile_number ? "mobile number, " : ""
          }${!email ? "email" : ""}`,
        });
      }

      // Register the SuperAdmin
      const result = await AuthService.register({
        pers_id,
        name,
        password,
        role: "superadmin",
        mobile_number,
        email,
      });
      res.status(201).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `SuperAdminAuthController-Register: ${error.message}` });
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
          error:
            `SuperAdminAuthController - Login SuperAdmin: Missing required fields:${
              !pers_id ? "personal id, " : ""
            }${!email ? "email, " : ""}${
              !mobile_number ? "mobile number, " : ""
            }${!password ? "password, " : ""}`.split(0, -2),
        });
      }

      // Authenticate the SuperAdmin
      const result = await AuthService.login({
        identifier,
        password,
        role: "superadmin",
      });

      // Return the token
      res.status(200).json(result);
    } catch (error) {
      res
        .status(400)
        .json({ error: `SuperAdminAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = SuperAdminAuthController;
