const HospitalService = require("../../Services/hospitalService");

/**
 * HospitalController handles the operations related to managing hospitals in the system.
 * It includes functionality for registering new hospitals, validating input data,
 * and ensuring that required fields are properly provided before proceeding with the registration.
 *
 * Each method ensures that all necessary information is included before registration, 
 * and handles errors effectively in case of missing data or unexpected issues.
 */
class HospitalController {

  /**
   * Registers a new hospital by collecting details from the request body.
   * Validates the required fields and then calls the HospitalService to process the registration.
   * 
   * @param {Object} req - The HTTP request object which contains the data for hospital registration in the body.
   * @param {Object} res - The HTTP response object used to send the response back to the client.
   * 
   * @returns {Object} Returns a JSON response indicating either the success or failure of the registration process.
   */

  static async register(req, res) {
    try {
      // Destructure the hospital registration details from the request body
      const { hospital_name, hospital_address, mobile_numbers, emails } =
        req.body;

      // Validate if all required fields are provided
      if (!hospital_name || !hospital_address || !mobile_numbers || !emails) {
        return res.status(400).json({
          error: `Missing required fields: ${
            !hospital_name ? "hospital_name, " : ""
          }${!hospital_address ? "hospital_address, " : ""}${
            !mobile_numbers ? "mobile_numbers, " : ""
          }${!emails ? "emails, " : ""}`.slice(0, -2), // Generate a dynamic error message listing missing fields
        });
      }

      // Call the HospitalService to process the hospital registration
      const hospital = await HospitalService.register({
        hospital_name,
        hospital_address,
        mobile_numbers,
        emails,
      });

      // Respond with the hospital data if the registration was successful
      res.status(201).json(hospital);
    } catch (error) {
      // Handle unexpected errors and return a 500 error response
      res
        .status(500)
        .json({ error: `HospitalController-Register: ${error.message}` });
    }
  }

  static async deleteHospital(req, res) {
    try {
      const { hospitalid } = req.headers;
  
      // Validate if hospital ID is provided
      if (!hospitalid) {
        return res.status(400).json({
          error: "HospitalController-Delete: Missing hospital ID",
        });
      }
  
      // Call the HospitalService to delete the hospital
      const result = await HospitalService.deleteHospital(hospitalid);
  
      // Check if the service returned an error
      if (result.error) {
        return res.status(400).json({ error: result.error });
      }
  
      // Respond with success
      return res.status(200).json(result);
    } catch (deleteHospitalError) {
      // Handle unexpected errors
      return res.status(500).json({
        error: `HospitalController-Delete: ${deleteHospitalError.message}`,
      });
    }
  }
  
}

// Export the HospitalController class to make it accessible in other parts of the application
module.exports = HospitalController;
