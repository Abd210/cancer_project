const DoctorService = require("../../Services/doctorService");
const SuspendController = require("../suspendController");

/**
 * Fetches public data for a doctor using their unique identifier (doctorid) from the request headers.
 * Handles missing doctorid error and interacts with the DoctorService to retrieve the data.
 */
class DoctorController {
  /**
   * Fetches public data for a doctor using their unique identifier (doctorid) from the request headers.
   * Handles missing doctorid error and interacts with the DoctorService to retrieve the data.
   *
   * @param {Object} req - The Express request object, containing the doctorid in the headers.
   * @param {Object} res - The Express response object used to send the result or errors.
   *
   * @returns {Object} A JSON response containing the doctor’s public data or an error message.
   */
  static async getPublicData(req, res) {
    try {
      // Extract the doctorid from the request headers
      const { doctorid } = req.headers;

      // Check if the doctorid is provided in the headers, otherwise return an error
      if (!doctorid) {
        return res.status(400).json({
          error: "DoctorController- Get Doctor Public Data: Missing doctorid",
        });
      }

      // Call the DoctorService to fetch the public data for the doctor
      const public_data = await DoctorService.getPublicData(doctorid);

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
      const { user, doctorid, filter, hospitalid } = req.headers;

      // If the user's role is "doctor", ensure they can only access their own data
      if (user.role === "doctor") {
        const doctor_data = await DoctorService.getDoctorData(user._id);
        // Check if the doctor data exists
        if (!doctor_data) {
          return res.status(404).json({ error: "Doctor not found" });
        }

        // Return the fetched doctor data with a 200 status code
        res.status(200).json(doctor_data);
      } else if (user.role === "superadmin") {
        // If the user is a superadmin and a specific doctor's ID was not provided
        if (!doctorid) {
          if (filter) {
            if (hospitalid) {
              console.log(
                "DoctorController- Get Doctor Data: Fetching doctor data by hospital"
              );
              // Retrieve all doctors' data from specified hospital if no doctorid is given and hospitalid is provided
              const allDoctors = await DoctorService.findAllDoctorsByHospital(
                hospitalid
              );
              console.log(allDoctors);

              const filtered_data = await SuspendController.filterData(
                allDoctors,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all doctor data
            } else {
              // Retrieve all doctors' data if no doctorid is provided
              const allDoctors = await DoctorService.findAllDoctors();

              const filtered_data = await SuspendController.filterData(
                allDoctors,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all doctor data
            }
          } else {
            return res.status(400).json({
              error:
                "DoctorController- Get Doctor Data: Please provide either a filter or a doctor's id", // Specific error for missing filter
            });
          }
        }
      } else {
        // If the role is neither 'doctor' nor 'superadmin', deny access
        return res.status(403).json({
          error: "DoctorController- Get Doctor Data: Access denied", // Access denied error
        });
      }

      console.log("DoctorController- Get Doctor Data: Fetching doctor data");
      // Call the DoctorService to find the doctor data based on the _id
      const doctor_data = await DoctorService.getDoctorData(doctorid);

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

  /**
   * Retrieves all patients assigned to a specific doctor.
   * The doctor id is expected to be provided in the request headers (doctorid).
   *
   * @param {Object} req - The Express request object.
   * @param {Object} res - The Express response object.
   * @returns {Object} A JSON response containing an array of patient data or an error message.
   */
  static async getAssignedPatients(req, res) {
    try {
      const { doctor_id, user, filter } = req.headers;
      if (!doctor_id) {
        return res.status(400).json({
          error: "DoctorController-getAssignedPatients: Missing doctorid",
        });
      }

      // Call the doctor service to retrieve assigned patients.
      const patients = await DoctorService.getPatientsAssignedToDoctor(doctor_id);

      const filtered_data = await SuspendController.filterData(
        patients,
        user.role,
        filter
      );
      return res.status(200).json(filtered_data); // Return the filtered patient data
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  static async updateDoctorData(req, res) {
    try {
      const { user, doctorid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Check if the user is authorized to update the test data when its suspended
      if (user.role !== "superadmin") {
        const doctor = await DoctorService.findDoctor(doctorid, null, null);
        if (doctor.suspended) {
          return res.status(403).json({
            error: "DoctorController-update doctor: Unauthorized",
          });
        }
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
      const updatedDoctor = await DoctorService.updateDoctor(
        doctorid,
        updateFields,
        user
      );

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
      return res.status(200).json({ message: "Doctor deleted successfully" });
    } catch (deleteDoctorError) {
      // Catch and return errors
      return res.status(500).json({
        error: `DoctorController-delete doctor: ${deleteDoctorError.message}`,
      });
    }
  }
}

module.exports = DoctorController;
