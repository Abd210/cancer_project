// services/authService.js
const Patient = require("../Models/Patient");
const Doctor = require("../Models/Doctor");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Device = require("../Models/Device");

const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";

class AuthService {
  //Register any type of user
  static async register(userRegistrationData) {
    let newUser, msg;
    try {
      let existingEmail = false;
      let existingMobileNumber = false;
      let existingPersId = false;
      let existingDeviceId = false;

      // Create the user based on role
      const { role } = userRegistrationData;
      switch (role) {
        case "patient":
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
          throw new Error("authService-Register: Invalid role");
      }

      // Check if email is already registered
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
    } catch (registrationError) {
      msg = registrationError.message;
    }

    return { message: msg };
  }

  //Login any type of user
  static async login({ role, identifier, password }) {
    let user;

    try {
      // Fetch the user based on role

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
      if (!user) {
        throw new Error(`authService-Login: ${role} not found`);
      }

      // Verify password
      const isMatch = await user.comparePassword(password); // Ensure the model has a `comparePassword` method
      if (!isMatch) {
        throw new Error("authService-Login: Invalid password");
      }

      // Generate JWT

      const token = jwt.sign({ _id: user._id, role }, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN,
      });
      return { token, message: "Login successful" };
    } catch (err) {
      return { message: err.message };
    }
  }

  //If the user forgets their password, send an email or SMS to reset it
  static async forgotPassword({ role, email, mobile_number }) {
    //Logic for sending an email or SMS to reset the password
  }

  //Reset the user's password provided the token is valid
  static async resetPassword({ role, email, new_password }) {
    let user;

    try {
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
      if (!user) {
        throw new Error("authService-Reset Pass: User not found");
      }

      // Update the password
      user.password = new_password;
      await user.save();

      return { message: "Password reset successful" };
    } catch (error) {
      return { message: error.message };
    }
  }
}

module.exports = AuthService;
