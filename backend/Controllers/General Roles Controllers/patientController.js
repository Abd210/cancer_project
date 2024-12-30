const PatientService = require("../../Services/patientService");

/**
 * Fetches patient data based on the provided _id from the request headers.
 * Handles authorization logic, ensuring that patients can only access their own data.
 */
class PatientController {

  /**
   * Fetches patient data based on the provided _id from the request headers.
   * Handles authorization logic, ensuring that patients can only access their own data.
   * 
   * @param {Object} req - The Express request object, containing headers with the patient’s _id, user information, and role.
   * @param {Object} res - The Express response object, used to send the patient data or error messages.
   * 
   * @returns {Object} A JSON response containing the patient’s data or an error message.
   */
  static async getData(req, res) {
    try {
      // Destructure _id, user, and role from the request headers
      const { _id, user, patientid } = req.headers;

      // Check if the _id is provided in the headers, return error if missing
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Data: Missing pers_id", // Specific error for missing _id
        });
      }

      let patient_id = _id;

       // If the user's role is "patient", ensure they can only access their own data
      if (user.role === "patient") {
        // If the _id in the headers doesn't match the logged-in user's _id, return a 403 Forbidden error
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized", // Unauthorized access error
          });
        }
      } else if (user.role === "superadmin") {
        // If the user is a superadmin
        if (patientid) {
          patient_id = patientid; // Retrieve specific patient's data
        } else {
          // Retrieve all patients' data if no patientid is provided
          console.log("Superadmin requesting all patient data");
          const allPatients = await PatientService.findAllPatients();
          return res.status(200).json(allPatients); // Return all patient data
        }
      } else {
        // If the role is neither 'patient' nor 'superadmin', deny access
        return res.status(403).json({
          error: "PatientController- Get Patient Data: Access denied", // Access denied error
        });
      }

      console.log("PatientController- Get Patient Data: Fetching patient data");
      // Call the PatientService to find the patient data based on the _id
      const patient_data = await PatientService.findPatient(patient_id);

      // Check if the patient data exists
      if (!patient_data) {
        return res.status(404).json({ error: "Patient not found" });
      }

      // Return the fetched patient data with a 200 status code
      res.status(200).json(patient_data);
    } catch (fetchPatientDataError) {
      // Catch any errors during the data fetching process and return a 500 status with the error message
      res.status(500).json({ error: fetchPatientDataError.message });
    }
  }

  /**
   * Fetches the diagnosis data for a specific patient based on their _id.
   * Ensures that only authorized users (e.g., the patient themselves) can access their diagnosis.
   * 
   * @param {Object} req - The Express request object, containing headers with the patient’s _id, user information, and role.
   * @param {Object} res - The Express response object, used to send the diagnosis data or error messages.
   * 
   * @returns {Object} A JSON response containing the patient's diagnosis or an error message.
   */
  static async getDiagnosis(req, res) {
    try {
      // Destructure _id, user, and role from the request headers
      const { _id, user, role } = req.headers;

      // Check if the _id is provided in the headers, return error if missing
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Diagnosis: Missing pers_id", // Error for missing _id
        });
      }

       // If the user's role is "patient", ensure they can only access their own diagnosis data
      if (user.role === "patient") {
        // If the _id in the headers doesn't match the logged-in user's _id, return a 403 Forbidden error
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Diagnosis: Unauthorized",
          });
        }
      }

      // Call the PatientService to find the patient data and return their diagnosis
      const patient_data = await PatientService.findPatient(_id);

      // Return the patient's diagnosis data with a 200 status code
      res.status(200).json(patient_data.diagnosis);
    } catch (fetchPatientDiagnosisError) {
      // Catch any errors during the diagnosis data fetching process and return a 500 status with the error message
      res.status(500).json({ error: fetchPatientDiagnosisError.message });
    }
  }


  static async updatePatientData(req, res) {
    try {
      // Destructure role and patientId from the request headers
      const { user, patientid } = req.headers;
  
      // Destructure the fields to update from the request body
      const updateFields = req.body;
  
      // Check if the role is superadmin
      if (user.role !== "superadmin") {
        return res.status(403).json({
          error: "PatientController- Update Patient Data: Access denied",
        });
      }
  
      // Validate if patientId is provided
      if (!patientid) {
        return res.status(400).json({
          error: "PatientController- Update Patient Data: Missing patientId",
        });
      }
  
      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "PatientController- Update Patient Data: No fields to update",
        });
      }
  
      // Call the PatientService to perform the update
      const updatedPatient = await PatientService.updatePatient(patientid, updateFields);
  
      // Check if the patient was found and updated
      if (!updatedPatient) {
        return res.status(404).json({
          error: "PatientController- Update Patient Data: Patient not found",
        });
      }
  
      // Return the updated patient data
      res.status(200).json(updatedPatient);
    } catch (updatePatientError) {
      // Handle errors during the update process
      res.status(500).json({ error: updatePatientError.message });
    }
  }
  
}

module.exports = PatientController;
