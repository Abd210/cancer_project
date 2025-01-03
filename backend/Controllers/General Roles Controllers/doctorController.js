const DoctorService = require("../../Services/doctorService");
const SuspendController = require("../suspendController");

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
      // Destructure _id, user, and role from the request headers
      const { _id, user, doctorid, filter } = req.headers;

      // Check if the _id is provided in the headers, return error if missing
      if (!_id) {
        return res.status(400).json({
          error: "DoctorController- Get Doctor Data: Missing _id", // Specific error for missing _id
        });
      }

      let doctor_id = _id;

       // If the user's role is "doctor", ensure they can only access their own data
      if (user.role === "doctor") {
        // If the _id in the headers doesn't match the logged-in user's _id, return a 403 Forbidden error
        if (_id !== user._id) {
          return res.status(403).json({
            error: "DoctorController- Get Doctor Data: Unauthorized", // Unauthorized access error
          });
        }
      } else if (user.role === "superadmin" || user.role === "admin") {
        // If the user is a superadmin
        if (doctorid) {
          doctor_id = doctorid; // Retrieve specific doctor's data
        } else {
          // Retrieve all doctors' data if no doctorid is provided
          const allDoctors = await DoctorService.findAllDoctors();

          const filtered_data = await SuspendController.filterData(allDoctors, user.role, filter);
          return res.status(200).json(filtered_data); // Return all doctor data
        }
      } else {
        // If the role is neither 'doctor' nor 'superadmin', deny access
        return res.status(403).json({
          error: "DoctorController- Get Doctor Data: Access denied", // Access denied error
        });
      }

      console.log("DoctorController- Get Doctor Data: Fetching doctor data");
      // Call the DoctorService to find the doctor data based on the _id
      const doctor_data = await DoctorService.getDoctorData(doctor_id);

      // Check if the doctor data exists
      if (!doctor_data) {
        return res.status(404).json({ error: "Doctor not found" });
      }

      // Return the fetched doctor data with a 200 status code
      res.status(200).json(doctor_data);
    } catch (fetchDoctorDataError) {
      // Catch any errors during the data fetching process and return a 500 status with the error message
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
      const updatedDoctor = await DoctorService.updateDoctor(doctorid, updateFields, user);
  
      // Check if the doctor was found and updated
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
