const DoctorService = require("../../Services/doctorService");

/**
 * Fetches public data for a doctor using their unique identifier (_id) from the request headers.
 * Handles missing _id error and interacts with the DoctorService to retrieve the data.
 */
class DoctorController {

  /**
   * Fetches public data for a doctor using their unique identifier (_id) from the request headers.
   * Handles missing _id error and interacts with the DoctorService to retrieve the data.
   * 
   * @param {Object} req - The Express request object, containing the _id in the headers.
   * @param {Object} res - The Express response object used to send the result or errors.
   * 
   * @returns {Object} A JSON response containing the doctor’s public data or an error message.
   */
  static async getPublicData(req, res) {
    try {
      // Extract the _id from the request headers
      const { _id } = req.headers;

      // Check if the _id is provided in the headers, otherwise return an error
      if (!_id) {
        return res.status(400).json({
          error: "DoctorController- Get Doctor Public Data: Missing _id",
        });
      }

      // Call the DoctorService to fetch the public data for the doctor
      const public_data = await DoctorService.getPublicData({ _id });

      // Respond with the doctor’s public data and a 200 status
      res.status(200).json(public_data);
    } catch (fetchDoctorPublicDataError) {
      // Handle any errors that occur during the data fetching process
      res.status(500).json({ error: fetchDoctorPublicDataError.message });
    }
  }
}

module.exports = DoctorController;
