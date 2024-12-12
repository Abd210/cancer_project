const DoctorService = require("../../Services/doctorService");

class DoctorController {
  static async getPublicData(req, res) {
    try {
      const { _id } = req.headers;

      if (!_id) {
        return res.status(400).json({
          error: "DoctorController- Get Doctor Public Data: Missing _id",
        });
      }

      const public_data = await DoctorService.getPublicData({ _id });
      res.status(200).json(public_data);
    } catch (fetchDoctorPublicDataError) {
      res.status(500).json({ error: fetchDoctorPublicDataError.message });
    }
  }
}

module.exports = DoctorController;
