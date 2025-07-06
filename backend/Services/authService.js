const admin = require("firebase-admin");
const db = admin.firestore();
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1h";

class AuthService {
  /**
   * Registers a new user and ensures uniqueness across collections.
   */
  static async register(userRegistrationData) {
    let newUser, msg;
    const { role, email, mobileNumber, persId, deviceId, password, hospital } =
      userRegistrationData;

    // Function to check for duplicates across Firestore collections
    const checkForDuplicates = async (field, value) => {
      const collections = [
        "patients",
        "doctors",
        "admins",
        "superadmins",
        "devices",
      ];
      for (const collection of collections) {
        const snapshot = await db
          .collection(collection)
          .where(field, "==", value)
          .get();
        if (!snapshot.empty) return true;
      }
      return false;
    };

    // Check if hospital exists
    if (hospital) {
      const hospitalRef = db.collection("hospitals").doc(hospital);
      const hospitalSnapshot = await hospitalRef.get();
      if (!hospitalSnapshot.exists) {
        throw new Error("authService-Register: Hospital not found");
      }
    }

    // Check for existing email, mobile number, and personal ID across collections
    if (email && (await checkForDuplicates("email", email))) {
      throw new Error("authService-Register: Email already registered");
    }
    if (
      mobileNumber &&
      (await checkForDuplicates("mobileNumber", mobileNumber))
    ) {
      throw new Error("authService-Register: Mobile number already registered");
    }
    if (persId && (await checkForDuplicates("persId", persId))) {
      throw new Error("authService-Register: Personal ID already registered");
    }
    if (
      role === "device" &&
      deviceId &&
      (await checkForDuplicates("device_id", deviceId))
    ) {
      throw new Error("authService-Register: Device ID already registered");
    }

    // Hash password before saving
    const hashedPassword = await bcrypt.hash(password, 10);
    const userData = { ...userRegistrationData, password: hashedPassword };

    // For admin role, ensure hospital field is always present (set to null if not provided)
    if (role === "admin" && (userData.hospital === undefined || userData.hospital === "")) {
      userData.hospital = null;
    }

    // Determine the correct Firestore collection
    let collectionRef;
    switch (role) {
      case "patient":
        collectionRef = db.collection("patients");
        break;
      case "doctor":
        collectionRef = db.collection("doctors");
        break;
      case "admin":
        collectionRef = db.collection("admins");
        break;
      case "superadmin":
        collectionRef = db.collection("superadmins");
        break;
      case "device":
        collectionRef = db.collection("devices");
        break;
      default:
        throw new Error("authService-Register: Invalid role");
    }

    // Save the user to Firestore
    const userRef = await collectionRef.add(userData);
    newUser = { id: userRef.id, ...userData };
    msg = "Registration successful";

    // Handle bidirectional admin-hospital relationship if admin is being created with hospital
    if (role === "admin" && hospital) {
      const HospitalService = require("./hospitalService");
      await HospitalService._manageBidirectionalHospitalAdminRelation(hospital, userRef.id, null);
    }

    // Add entity ID to hospital arrays for doctors and patients
    if (hospital && (role === "doctor" || role === "patient")) {
      try {
        const HospitalService = require("./hospitalService");
        await HospitalService.addEntityToHospital(hospital, userRef.id, role === "doctor" ? "doctors" : "patients");
      } catch (error) {
        console.error(`Error adding ${role} ${userRef.id} to hospital ${hospital}:`, error);
        // Don't throw error here as the user was already created successfully
      }
    }

    return { message: msg, user: newUser };
  }

  /**
   * Logs in a user by verifying their credentials and issuing a JWT token.
   */
  static async login({ role, identifier, password }) {
    let user, collection;

    // Determine the correct Firestore collection
    switch (role) {
      case "patient":
        collection = "patients";
        break;
      case "doctor":
        collection = "doctors";
        break;
      case "admin":
        collection = "admins";
        break;
      case "superadmin":
        collection = "superadmins";
        break;
      case "device":
        collection = "devices";
        break;
      default:
        throw new Error("authService-Login: Invalid role");
    }

    // Run all queries in parallel
    const [emailQuery, phoneQuery, persIdQuery] = await Promise.all([
      db.collection(collection).where("email", "==", identifier).get(),
      db.collection(collection).where("mobileNumber", "==", identifier).get(),
      db.collection(collection).where("persId", "==", identifier).get(),
    ]);

    let userSnapshot;

    if (!emailQuery.empty) {
      userSnapshot = emailQuery;
    } else if (!phoneQuery.empty) {
      userSnapshot = phoneQuery;
    } else if (!persIdQuery.empty) {
      userSnapshot = persIdQuery;
    } else {
      throw new Error(`authService-Login: ${role} not found`);
    }

    // Extract user data
    user = { id: userSnapshot.docs[0].id, ...userSnapshot.docs[0].data() };

    // Suspension check (skip for superadmin & device)
    if (role !== "superadmin" && role !== "device" && user.suspended) {
      throw new Error(
        `authService-Login: Your account is suspended and cannot log in.`
      );
    }

    // Skip password verification for devices
    if (role === "device") {
      return { message: "Device authenticated successfully" };
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new Error("authService-Login: Invalid password");
    }

    // Generate JWT token
    const tokenPayload = { id: user.id, role };
    
    // Include hospital field in token for admin users
    if (role === "admin" && user.hospital) {
      tokenPayload.hospital = user.hospital;
    }
    
    const token = jwt.sign(tokenPayload, JWT_SECRET, {
      expiresIn: JWT_EXPIRES_IN,
    });

    return { token, message: "Login successful", user };
  }

  /**
   * Initiates a password reset process.
   */
  static async forgotPassword({ role, email }) {
    const collectionMap = {
      patient: "patients",
      doctor: "doctors",
      admin: "admins",
      superadmin: "superadmins",
    };

    const collection = collectionMap[role];
    if (!collection)
      throw new Error("authService-ForgotPassword: Invalid role");

    const userSnapshot = await db
      .collection(collection)
      .where("email", "==", email)
      .get();
    if (userSnapshot.empty)
      throw new Error("authService-ForgotPassword: User not found");

    // Send password reset email or generate token (implement actual reset logic)
    return { message: "Password reset initiated. Check your email." };
  }

  /**
   * Resets a user's password.
   */
  static async resetPassword({ role, email, new_password }) {
    const collectionMap = {
      patient: "patients",
      doctor: "doctors",
      admin: "admins",
      superadmin: "superadmins",
    };

    const collection = collectionMap[role];
    if (!collection) throw new Error("authService-ResetPassword: Invalid role");

    const userSnapshot = await db
      .collection(collection)
      .where("email", "==", email)
      .get();
    if (userSnapshot.empty)
      throw new Error("authService-ResetPassword: User not found");

    const userRef = userSnapshot.docs[0].ref;

    // Hash new password before saving
    const hashedPassword = await bcrypt.hash(new_password, 10);
    await userRef.update({ password: hashedPassword });

    return { message: "Password reset successful" };
  }
}

module.exports = AuthService;
