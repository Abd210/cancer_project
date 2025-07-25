const HospitalService = require("../../Services/hospitalService");
const SuspendController = require("../suspendController");

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
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      // Destructure the hospital registration details from the request body
      const { name, address, mobileNumbers, emails, admin, suspended } = req.body;

      // Validate if all required fields are provided
      if (!name || !address || !mobileNumbers || !emails) {
        return res.status(400).json({
          error: `Missing required fields: ${!name ? "name, " : ""}${
            !address ? "address, " : ""
          }${!mobileNumbers ? "mobileNumbers, " : ""}${
            !emails ? "emails, " : ""
          }`.slice(0, -2), // Generate a dynamic error message listing missing fields
        });
      }

      // Call the HospitalService to process the hospital registration
      const hospital = await HospitalService.register({
        name,
        address,
        mobileNumbers,
        emails,
        admin,
        suspended,
      });

      // Respond with the hospital data if the registration was successful
      res.status(201).json(hospital);
    } catch (error) {
      console.error("Error in register:", error);
      res.status(500).json({
        error: `HospitalController - Register Hospital: ${error.message}`,
      });
    }
  }

  static async getHospitalData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      // Destructure user, and role from the request headers
      const { user, hospitalid, filter } = req.headers;

      // Check if the hospitalid is provided in the headers, return error if missing
      if (!hospitalid && !filter) {
        return res.status(400).json({
          error:
            "HospitalController - Get Hospital Data: hospitalid or filter must be provided", // Specific error for missing hospitalid
        });
      }

      //If there's no hospital ID, return all hospitals' data
      if (!hospitalid) {
        // Retrieve all hospitals' data if no hospitalid is provided
        const allHospitals = await HospitalService.findAllHospitals();

        const filtered_data = await SuspendController.filterData(
          allHospitals,
          user.role,
          filter
        );
        return res.status(200).json(filtered_data); // Return all hospital data
      }

      //Admin or Superadmin can access specific hospital data
      let hospital_id = hospitalid;

      console.log(
        "HospitalController - Get Hospital Data: Fetching hospital data"
      );
      // Call the HospitalService to find the hospital data based on the _id
      const hospital_data = await HospitalService.getHospitalData(hospital_id);

      // Check if the hospital data exists
      if (!hospital_data) {
        return res.status(404).json({ error: "Hospital not found" });
      }

      // Return the fetched hospital data with a 200 status code
      res.status(200).json(hospital_data);
    } catch (fetchHospitalDataError) {
      console.error("Error in getHospitalData:", fetchHospitalDataError);
      res.status(500).json({
        error: `HospitalController - Fetch Hospital Data: ${fetchHospitalDataError.message}`,
      });
    }
  }

  static async updateHospitalData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { user, hospitalid } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Validate if hospitalId is provided
      if (!hospitalid) {
        return res.status(400).json({
          error: "HospitalController - Update Hospital: Missing hospitalId",
        });
      }

      // Check if the user is authorized to update the hospital when its suspended
      if (user.role !== "superadmin") {
        const hospital = await HospitalService.findHospital(hospitalid);
        if (hospital.suspended) {
          return res.status(403).json({
            error: "HospitalController-update hospital: Unauthorized",
          });
        }
      }

      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error:
            "HospitalController - Update Hospital: No fields provided to update",
        });
      }

      // Call the HospitalService to perform the update
      const updatedHospital = await HospitalService.updateHospital(
        hospitalid,
        updateFields,
        user
      );

      // Check if the hospital was found and updated
      if (!updatedHospital) {
        return res.status(404).json({
          error:
            "HospitalController - Update Hospital Data: Hospital not found",
        });
      }

      // Respond with the updated hospital data
      return res.status(200).json(updatedHospital);
    } catch (updateHospitalError) {
      console.error("Error in updateHospitalData:", updateHospitalError);
      res.status(500).json({
        error: `HospitalController - Update Hospital: ${updateHospitalError.message}`,
      });
    }
  }

  static async deleteHospital(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
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
      return res.status(200).json({
        message: "Hospital and all associated data successfully deleted",
      });
    } catch (deleteHospitalError) {
      console.error("Error in deleteHospital:", deleteHospitalError);
      res.status(500).json({
        error: `HospitalController - Delete Hospital: ${deleteHospitalError.message}`,
      });
    }
  }
}

// Export the HospitalController class to make it accessible in other parts of the application
module.exports = HospitalController;
