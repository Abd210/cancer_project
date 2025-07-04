// controllers/doctorAuthController.js
const AuthService = require("../../Services/authService");
const PatientService = require("../../Services/patientService");

/**
 * DoctorAuthController handles the authentication-related actions for doctors.
 * It includes methods for doctor registration and login.
 * The controller communicates with the AuthService to process the registration and login logic.
 */
class DoctorAuthController {
  /**
   * Registers a new doctor by verifying and saving the provided details.
   * It checks if all required fields are present and then calls the AuthService to handle registration logic.
   *
   * @param {Object} req - The Express request object, containing the details to register the doctor.
   * @param {Object} res - The Express response object, used to send the result or error message.
   *
   * @returns {Object} A JSON response containing either the result of the registration or an error message.
   */

  static async register(req, res) {
    try {

      const { user } = req.headers;

      // Destructure the required fields from the request body
      const {
        persId,
        name,
        password,
        email,
        mobileNumber,
        birthDate,
        licenses,
        description,
        hospital,
        suspended,
        patients = [],
        schedule = [
          { day: "Monday", start: "09:00", end: "17:00" },
          { day: "Tuesday", start: "09:00", end: "17:00" },
          { day: "Wednesday", start: "09:00", end: "17:00" },
          { day: "Thursday", start: "09:00", end: "17:00" },
          { day: "Friday", start: "09:00", end: "17:00" },
        ], // Default array if not provided
      } = req.body;

      // Check for required fields for Doctor registration
      if (
        !persId ||
        !name ||
        !password ||
        !email ||
        !mobileNumber ||
        !birthDate ||
        !licenses ||
        !hospital
      ) {
        return res.status(400).json({
          error: `Missing required fields: ${!persId ? "pers. id, " : ""}${
            !name ? "name, " : ""
          }${!password ? "password, " : ""}${!email ? "email, " : ""}${
            !mobileNumber ? "mobile number, " : ""
          }${!birthDate ? "birth date, " : ""}${!licenses ? "licenses, " : ""}${
            !hospital ? "hospital" : ""
          }`.slice(0, -2),
        });
      }

      // Convert to a real Date
      const parsedBirthDate = new Date(birthDate);

      // Validate the parse
      if (isNaN(parsedBirthDate.getTime())) {
        return res.status(400).json({ error: "Invalid birthDate format" });
      }

      // Call the AuthService to handle the doctor registration logic
      const result = await AuthService.register({
        persId,
        name,
        password,
        role: "doctor", // Set the role as 'doctor'
        email,
        mobileNumber,
        birthDate: parsedBirthDate,
        licenses,
        description,
        hospital,
        suspended,
        patients,
        schedule,
      });

      // Correctly extract `id` from `registeredDoctor.user`
      const doctorId = result.user.id;
      console.log(doctorId);

      // If the patients array is not empty, update each patient's doctors field
      if (patients && Array.isArray(patients) && patients.length > 0) {
        await Promise.all(
          patients.map(async (patientId) => {
            // Get current patient data to add this doctor to their doctors array
            const patientDoc = await require("firebase-admin").firestore()
              .collection("patients").doc(patientId).get();
            
            if (patientDoc.exists) {
              const patientData = patientDoc.data();
              const currentDoctors = patientData.doctors || [];
              
              // Add the new doctor if not already in the array
              if (!currentDoctors.includes(doctorId)) {
                const updatedDoctors = [...currentDoctors, doctorId];
                await PatientService.updatePatient(
                  patientId,
                  { doctors: updatedDoctors },
                  { role: user.role } // Ensuring proper role for permission
                );
              }
            }
          })
        );
      }

      // Return the result of the registration
      res.status(201).json(result);
    } catch (error) {
      // Catch any errors during registration and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `DoctorAuthController-Register: ${error.message}` });
    }
  }

  /**
   * Logs in a doctor by verifying the provided credentials (either persId, email, or mobileNumber, along with password).
   * Calls the AuthService to authenticate the doctor and return an authentication token.
   *
   * @param {Object} req - The Express request object, containing the login credentials.
   * @param {Object} res - The Express response object, used to send the authentication result or error message.
   *
   * @returns {Object} A JSON response containing either the login result (token) or an error message.
   */
  static async login(req, res) {
    try {
      // Destructure the login credentials from the request body
      const { persId, email, mobileNumber, password } = req.body;

      // Determine the login identifier (could be persId, email, or mobileNumber)
      const identifier = persId || email || mobileNumber;

      // Check for required fields for login
      if (!identifier || !password) {
        return res.status(400).json({
          error: `Missing required fields: ${!persId ? "persId, " : ""}${
            !email ? "email, " : ""
          }${!mobileNumber ? "mobileNumber, " : ""}${
            !password ? "password" : ""
          }`.slice(0, -2),
        });
      }

      // Call the AuthService to authenticate the doctor using the provided credentials
      const result = await AuthService.login({
        identifier,
        password,
        role: "doctor", // Ensure the role is 'doctor'
      });

      // Return the result of the login (usually a token)
      res.status(200).json(result);
    } catch (error) {
      // Catch any errors during login and return a 400 status with the error message
      res
        .status(400)
        .json({ error: `DoctorAuthController-Login: ${error.message}` });
    }
  }
}

module.exports = DoctorAuthController;
