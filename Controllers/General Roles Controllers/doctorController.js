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

  static async getDoctorData(req, res) {
    try {
      // Extract the _id from the request headers
      const { _id } = req.headers;

      // Check if the _id is provided in the headers, otherwise return an error
      if (!_id) {
        return res.status(400).json({
          error: "DoctorController- Get Doctor Data: Missing _id",
        });
      }

      // Call the DoctorService to fetch the public data for the doctor
      const doctor_data = await DoctorService.getDoctorData({ _id });

      // Respond with the doctor’s public data and a 200 status
      res.status(200).json(doctor_data);
    } catch (fetchDoctorDataError) {
      // Handle any errors that occur during the data fetching process
      res.status(500).json({ error: fetchDoctorDataError.message });
    }
  }


  static async updateDoctorData(req, res) {
    try {
      const { user, doctorid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;
  
      // Check if the role is superadmin
      if (user.role !== "superadmin") {
        return res.status(403).json({
          error: "DoctorController- Update Doctor Data: Access denied",
        });
      }

      // Validate if doctorId is provided
      if (!doctorid) {
        return res.status(400).json({
          error: "DoctorController-update doctor: Missing doctorId",
        });
      }
  
      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "DoctorController-update doctor: No fields provided to update",
        });
      }
  
      // Call the DoctorService to perform the update
      const updatedDoctor = await DoctorService.updateDoctor(doctorid, updateFields);
  
      // Check if the patient was found and updated
      if (!updatedDoctor) {
        return res.status(404).json({
          error: "DoctorController- Update Doctor Data: Doctor not found",
        });
      }
  
      // Respond with the updated doctor data
      return res.status(200).json(updatedDoctor);
    } catch (updateDoctorError) {
      // Catch and return errors
      return res.status(500).json({
        error: `DoctorController-update doctor: ${updateDoctorError.message}`,
      });
    }
  }
  
  static async deleteDoctorData(req, res) {
    try {
      const { doctorid } = req.headers;
  
      // Validate if doctorId is provided
      if (!doctorid) {
        return res.status(400).json({
          error: "DoctorController-delete doctor: Missing doctorId",
        });
      }
  
      // Call the DoctorService to perform the deletion
      const result = await DoctorService.deleteDoctor(doctorid);
  
      // Check if the service returned an error
      if (result.error) {
        return res.status(400).json({ error: result.error });
      }
  
      // Respond with success
      return res.status(200).json(result);
    } catch (deleteDoctorError) {
      // Catch and return errors
      return res.status(500).json({
        error: `DoctorController-delete doctor: ${deleteDoctorError.message}`,
      });
    }
  }  

}

module.exports = DoctorController;
