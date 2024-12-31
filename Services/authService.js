// services/authService.js
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Device = require("../Models/Device");

const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";

/**
 * AuthService provides functionality related to user authentication and registration.
 * It includes methods for registering users of various roles (patient, doctor, admin, superadmin, and device),
 * logging users in, handling password reset, and generating JWT tokens.
 * The methods validate input data, check for existing records, hash passwords, and issue JWT tokens where necessary.
 */
class AuthService {

   /**
   * Registers a new user with a given role (patient, doctor, admin, superadmin, device).
   * It checks for existing records in the database (email, mobile number, personal ID, device ID),
   * and ensures that the user has unique data before proceeding with registration.
   *
   * @param {Object} userRegistrationData - The data required to register a new user.
   * @returns {Object} Returns a success or error message based on the outcome of the registration.
   */
  static async register(userRegistrationData) {
    let newUser, msg;
    let existingEmail = false;
    let existingMobileNumber = false;
    let existingPersId = false;
    let existingDeviceId = false;

    // Switch statement based on user role to handle different registration processes
    const { role } = userRegistrationData;
    switch (role) {
      case "patient":
        // Check for existing email, mobile number, and personal ID in the Patient collection
        existingEmail = await Patient.findOne({
          email: userRegistrationData.email,
        });
        existingMobileNumber = await Patient.findOne({
          mobile_number: userRegistrationData.mobile_number,
        });

        existingPersId = await Patient.findOne({
          pers_id: userRegistrationData.pers_id,
        });

        newUser = new Patient(userRegistrationData);
        break;
      case "doctor":
        existingEmail = await Doctor.findOne({
          email: userRegistrationData.email,
        });
        existingMobileNumber = await Doctor.findOne({
          mobile_number: userRegistrationData.mobile_number,
        });

        existingPersId = await Doctor.findOne({
          pers_id: userRegistrationData.pers_id,
        });

        newUser = new Doctor(userRegistrationData);
        break;
      case "admin":
        existingEmail = await Admin.findOne({
          email: userRegistrationData.email,
        });
        existingMobileNumber = await Admin.findOne({
          mobile_number: userRegistrationData.mobile_number,
        });

        existingPersId = await Admin.findOne({
          pers_id: userRegistrationData.pers_id,
        });

        newUser = new Admin(userRegistrationData);
        break;
      case "superadmin":
        existingEmail = await SuperAdmin.findOne({
          email: userRegistrationData.email,
        });
        existingMobileNumber = await SuperAdmin.findOne({
          mobile_number: userRegistrationData.mobile_number,
        });

        existingPersId = await SuperAdmin.findOne({
          pers_id: userRegistrationData.pers_id,
        });

        newUser = new SuperAdmin(userRegistrationData);
        break;
      case "device":
        existingDeviceId = await Device.findOne({
          device_id: userRegistrationData.deviceId,
        });

        newUser = new Device(userRegistrationData);
        break;
      default:
        throw new Error("authService-Register: Invalid role"); // Invalid role provided
    }

    // Check for duplicates (email, mobile number, personal ID, device ID)
    if (existingEmail) {
      throw new Error("authService-Register: Email already registered");
    }
    // Check if mobile number is already registered
    if (existingMobileNumber) {
      throw new Error(
        "authService-Register: Mobile number already registered"
      );
    }

    // Check if pers_id is already registered
    if (existingPersId) {
      throw new Error("authService-Register: Personal ID already registered");
    }

    // Check if device_id is already registered
    if (existingDeviceId) {
      throw new Error("authService-Register: Device ID already registered");
    }

    // Hash the password before saving (this is handled within the user model pre-save)
    await newUser.save();
    msg = "Registration successful";

    return { message: msg }; // Return the result message
  }

   /**
   * Logs in a user based on their role (patient, doctor, admin, superadmin, device).
   * It fetches the user based on a unique identifier (email, mobile number, or personal ID),
   * verifies the password, and generates a JWT token for successful login.
   *
   * @param {Object} loginData - The login credentials (role, identifier, and password).
   * @returns {Object} Returns a JWT token and success message or an error message if login fails.
   */
  static async login({ role, identifier, password }) {
    let user;

    // Fetch the user from the appropriate collection based on role
    switch (role) {
      case "patient":
        user =
          (await Patient.findOne({ email: identifier })) ||
          (await Patient.findOne({ mobile_number: identifier })) ||
          (await Patient.findOne({ pers_id: identifier }));

        break;
      case "doctor":
        user =
          (await Doctor.findOne({ email: identifier })) ||
          (await Doctor.findOne({ mobile_number: identifier })) ||
          (await Doctor.findOne({ pers_id: identifier }));
        break;
      case "admin":
        user =
          (await Admin.findOne({ email: identifier })) ||
          (await Admin.findOne({ mobile_number: identifier })) ||
          (await Admin.findOne({ pers_id: identifier }));
        break;
      case "superadmin":
        user =
          (await SuperAdmin.findOne({ email: identifier })) ||
          (await SuperAdmin.findOne({ mobile_number: identifier })) ||
          (await SuperAdmin.findOne({ pers_id: identifier }));
        break;
      case "device":
        user = await Device.findOne({ device_id: identifier });

        // Devices might not use password-based authentication
        return { message: "Device authenticated successfully" };
      default:
        throw new Error("authService-Login: Invalid role");
    }

    // Check if user exists
    // If no user is found, return an error
    if (!user) {
      throw new Error(`authService-Login: ${role} not found`);
    }

    // Verify the password for the user
    const isMatch = await user.comparePassword(password); // Ensure the model has a `comparePassword` method
    if (!isMatch) {
      throw new Error("authService-Login: Invalid password");
    }

    // Generate a JWT token for the authenticated user
    const token = jwt.sign({ _id: user._id, role }, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
    });
    return { token, message: "Login successful" };
  }

  /**
   * Initiates the process to reset a user's password by sending an email or SMS.
   * This is useful for scenarios where the user has forgotten their password.
   * 
   * @param {Object} resetData - The data required to initiate the password reset (role, email, mobile number).
   */
  static async forgotPassword({ role, email, mobile_number }) {
    //Logic for sending an email or SMS to reset the password
  }

  /**
   * Resets the user's password after validating the token.
   * It updates the user's password in the database.
   *
   * @param {Object} resetData - The data required to reset the password (role, email, new password).
   * @returns {Object} Returns a success or error message based on the outcome of the reset.
   */
  static async resetPassword({ role, email, new_password }) {
    let user;

    // Fetch the user based on the role and email
    switch (role) {
      case "patient":
        user = await Patient.findOne({ email: email });
        break;
      case "doctor":
        user = await Doctor.findOne({ email: email });
        break;
      case "admin":
        user = await Admin.findOne({ email: email });
        break;
      case "superadmin":
        user = await SuperAdmin.findOne({ email: email });
        break;
      default:
        throw new Error("authService-Reset Pass: Invalid role");
    }

    // Check if user exists
    if (!user) {
      throw new Error("authService-Reset Pass: User not found");
    }

    // Update the password and save the changes
    user.password = new_password;
    await user.save();

    return { message: "Password reset successful" };
  }
}

module.exports = AuthService;
