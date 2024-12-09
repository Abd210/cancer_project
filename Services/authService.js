// services/authService.js
const Patient = require("../models/Patient");
const Doctor = require("../models/Doctor");
const Admin = require("../models/Admin");
const SuperAdmin = require("../models/SuperAdmin");
const Device = require("../models/Device");

const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";

class AuthService {
  //Register any type of user
  static async register(userRegistrationData) {
    let existingEmail = false;
    let existingMobileNumber = false;
    let existingLicense = false;
    let existingName = false;
    let existingPersId = false;
    let existingDeviceId = false;

    let newUser;

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
        existingName = await Patient.findOne({
          name: userRegistrationData.name,
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
        existingName = await Doctor.findOne({
          name: userRegistrationData.name,
        });
        existingPersId = await Doctor.findOne({
          pers_id: userRegistrationData.pers_id,
        });

        existingLicense = await Doctor.findOne({
          license: userRegistrationData.license,
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
        existingName = await Admin.findOne({
          name: userRegistrationData.name,
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
        existingName = await SuperAdmin.findOne({
          name: userRegistrationData.name,
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
        throw new Error("Invalid role");
    }

    // Check if email is already registered
    if (existingEmail) {
      throw new Error("Email already registered");
    }
    // Check if mobile number is already registered
    if (existingMobileNumber) {
      throw new Error("Mobile number already registered");
    }
    // Check if name is already registered
    if (existingName) {
      throw new Error("Name already registered");
    }
    // Check if pers_id is already registered
    if (existingPersId) {
      throw new Error("Personal ID already registered");
    }
    // Check if license is already registered
    if (existingLicense) {
      throw new Error("License already registered");
    }
    // Check if device_id is already registered
    if (existingDeviceId) {
      throw new Error("Device ID already registered");
    }

    // Hash the password before saving (this is handled within the user model pre-save)
    await newUser.save();

    return { message: "User registered successfully" };
  }

  static async login({ username, password }) {
    // Check if user exists
    const user = await User.findOne({ username });
    if (!user) {
      throw new Error("User not found");
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      throw new Error("Invalid credentials");
    }

    // Generate JWT
    const token = jwt.sign(
      { id: user._id, username: user.username },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return { token };
  }
}

module.exports = AuthService;
