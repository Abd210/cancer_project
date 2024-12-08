const Patient = require("../Models/Patient");
const Device = require("../Models/Device");
const Admin = require("../Models/Admin");
const SuperAdmin = require("../Models/SuperAdmin");
const Doctor = require("../Models/Doctor");
const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";

class AuthService {
  //Register any type of user
  static async register(userRegistrationData) {
    const username =
      userRegistrationData["email"] ||
      userRegistrationData["pers_id"] ||
      userRegistrationData["name"] ||
      userRegistrationData["mobile_number"];
    let existingUser = false;

    let newUser;

    // Create the user based on role
    switch (role) {
      case "patient":
        existingUser = await Patient.findOne({ username });

        newUser = new Patient(userRegistrationData);
        break;
      case "doctor":
        existingUser = await Doctor.findOne({ username });

        newUser = new Doctor(userRegistrationData);
        break;
      case "admin":
        existingUser = await Admin.findOne({ username });

        newUser = new Admin(userRegistrationData);
        break;
      case "superadmin":
        existingUser = await SuperAdmin.findOne({ username });

        newUser = new SuperAdmin(userRegistrationData);
        break;
      case "device":
        existingUser = await Device.findOne({ username });

        newUser = new Device(userRegistrationData);
        break;
      default:
        newUser = new User({ username, password, role });
    }

    // Check if user already exists
    if (existingUser) {
      throw new Error("Username is already taken");
    }
    // Hash the password before saving (this is handled within the user model pre-save)
    await newUser.save();

    return {
      message: `${
        role.charAt(0).toUpperCase() + role.slice(1)
      } registered successfully`,
    };
  }

  //Login any type of user
  static async login({ username, password, role }) {
    // Check if user exists based on the role
    let user;
    switch (role) {
      case "patient":
        user = await Patient.findOne({ username });
        break;
      case "doctor":
        user = await Doctor.findOne({ username });
        break;
      // Add other roles if necessary
      default:
        user = await User.findOne({ username });
    }

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
      { id: user._id, username: user.name, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return { token };
  }
}

module.exports = AuthService;
