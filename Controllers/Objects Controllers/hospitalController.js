const HospitalService = require("../../Services/hospitalService");

class HospitalController {
  static async register(req, res) {
    try {
      const { hospital_name, hospital_address, mobile_numbers, emails } =
        req.body;

      // Validate required fields
      if (!hospital_name || !hospital_address || !mobile_numbers || !emails) {
        return res.status(400).json({
          error: `Missing required fields: ${
            !hospital_name ? "hospital_name, " : ""
          }${!hospital_address ? "hospital_address, " : ""}${
            !mobile_numbers ? "mobile_numbers, " : ""
          }${!emails ? "emails, " : ""}`.slice(0, -2),
        });
      }

      const hospital = await HospitalService.register({
        hospital_name,
        hospital_address,
        mobile_numbers,
        emails,
      });
      res.status(201).json(hospital);
    } catch (error) {
      res
        .status(500)
        .json({ error: `HospitalController-Register: ${error.message}` });
    }
  }
}

module.exports = HospitalController;
