const PatientService = require("../../Services/patientService");
const SuspendController = require("../suspendController");

/**
 * Fetches patient data based on the provided _id from the request headers.
 * Handles authorization logic, ensuring that patients can only access their own data.
 */
class PatientController {
  /**
   * Fetches patient personal data.
   * Based on the user's role and provided parameters, retrieves patient data.
   *
   * @param {Object} req - The Express request object
   * @param {Object} res - The Express response object
   * @returns {Object} - JSON object containing patient data
   */
  static async getPatientData(req, res) {
    try {
      // Destructure _id, user, and role from the request headers
      const { user, patientid, filter, hospitalid, doctorid } = req.headers;

      // If the user's role is "patient", ensure they can only access their own data
      if (user.role === "patient") {
        const patient_data = await PatientService.getPatientData(user.id);
        // Check if the patient data exists
        if (!patient_data) {
          return res.status(404).json({ error: "Patient not found" });
        }

        // Return the fetched patient data with a 200 status code
        return res.status(200).json(patient_data);
      } else if (user.role === "superadmin" || user.role === "doctor") {
        // If the user is a superadmin/doctor and a specific patient's ID was not provided
        if (!patientid) {
          if (filter) {
            // Check if doctor filter is applied
            if (doctorid) {
              // Retrieve all patients' data assigned to specified doctor
              const allPatients = await PatientService.findAllPatientsByDoctor(
                doctorid
              );

              const filtered_data = await SuspendController.filterData(
                allPatients,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return filtered patient data
            }
            // Check if hospital filter is applied
            else if (hospitalid) {
              // Retrieve all patients' data from specified hospital if no patientid is given and hospitalid is provided
              const allPatients =
                await PatientService.findAllPatientsByHospital(hospitalid);

              const filtered_data = await SuspendController.filterData(
                allPatients,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all patient data
            } else {
              // Retrieve all patients' data if no patientid is provided
              const allPatients = await PatientService.findAllPatients();

              const filtered_data = await SuspendController.filterData(
                allPatients,
                user.role,
                filter
              );
              return res.status(200).json(filtered_data); // Return all patient data
            }
          } else {
            return res.status(400).json({
              error:
                "PatientController- Get Patient Data: Please provide either a filter or a patient's id", // Specific error for missing filter
            });
          }
        } else {
          // If patientid is provided for superadmin/doctor, proceed to fetch specific patient data
          const patient_data = await PatientService.getPatientData(patientid);

          // Check if the patient data exists
          if (!patient_data) {
            return res.status(404).json({ error: "Patient not found" });
          }

          // Return the fetched patient data with a 200 status code
          return res.status(200).json(patient_data);
        }
      } else {
        // If the role is neither 'patient' nor 'superadmin', deny access
        return res.status(403).json({
          error: "PatientController- Get Patient Data: Access denied", // Access denied error
        });
      }
    } catch (fetchPatientDataError) {
      res.status(500).json({ error: fetchPatientDataError.message });
    }
  }

  /**
   * Fetches the diagnosis data for a specific patient based on their _id.
   * Ensures that only authorized users (e.g., the patient themselves) can access their diagnosis.
   *
   * @param {Object} req - The Express request object, containing headers with the patient's _id, user information, and role.
   * @param {Object} res - The Express response object, used to send the diagnosis data or error messages.
   *
   * @returns {Object} A JSON response containing the patient's diagnosis or an error message.
   */
  static async getDiagnosis(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      // Destructure patientid, user, and role from the request headers
      const { patientid, user } = req.headers;

      // Check if the patientid is provided in the headers, return error if missing
      if (!patientid) {
        return res.status(400).json({
          error: "PatientController- Get Patient Diagnosis: Missing patientid", // Error for missing patientid
        });
      }

      // If the user's role is "patient", ensure they can only access their own diagnosis data
      if (user.role === "patient") {
        // If the patientid in the headers doesn't match the logged-in user's patientid, return a 403 Forbidden error
        if (patientid !== user.id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Diagnosis: Unauthorized",
          });
        }
      }

      // Call the PatientService to find the patient data and return their diagnosis
      const patient_data = await PatientService.getPatientDiagnosis(patientid);

      // Return the patient's diagnosis data with a 200 status code
      res.status(200).json(patient_data.diagnosis);
    } catch (fetchPatientDiagnosisError) {
      console.error("Error in getDiagnosis:", fetchPatientDiagnosisError);
      res.status(500).json({ error: fetchPatientDiagnosisError.message });
    }
  }

  static async updatePatientData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      // Destructure role and patientId from the request headers
      const { user, patientid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Validate if patientId is provided
      if (!patientid) {
        return res.status(400).json({
          error: "PatientController- Update Patient Data: Missing patientId",
        });
      }

      // Check if the user is authorized to update the test data when its suspended
      if (user.role !== "superadmin") {
        const patient = await PatientService.findPatient(patientid, null, null);
        if (patient.suspended) {
          return res.status(403).json({
            error: "PatientController-update patient: Unauthorized",
          });
        }
      }

      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "PatientController- Update Patient Data: No fields to update",
        });
      }

      // Call the PatientService to perform the update
      const updatedPatient = await PatientService.updatePatient(
        patientid,
        updateFields,
        user
      );

      // Check if the patient was found and updated
      if (!updatedPatient) {
        return res.status(404).json({
          error: "PatientController- Update Patient Data: Patient not found",
        });
      }

      // Return the updated patient data
      res.status(200).json(updatedPatient);
    } catch (updatePatientError) {
      console.error("Error in updatePatientData:", updatePatientError);
      res.status(500).json({ error: updatePatientError.message });
    }
  }

  static async deletePatientData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { patientid } = req.headers;

      // Validate if patientId is provided
      if (!patientid) {
        return res.status(400).json({
          error: "PatientController-delete patient: Missing patientId",
        });
      }

      // Call the PatientService to perform the deletion
      const result = await PatientService.deletePatient(patientid);

      // Check if the service returned an error
      if (result.error) {
        return res.status(400).json({ error: result.error });
      }

      // Respond with success
      return res.status(200).json({ message: "Patient deleted successfully" });
    } catch (deletePatientError) {
      console.error("Error in deletePatientData:", deletePatientError);
      res.status(500).json({ error: deletePatientError.message });
    }
  }
}

module.exports = PatientController;
