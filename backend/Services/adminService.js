const admin = require("firebase-admin");
const db = admin.firestore();

class AdminService {
  /**
   * Finds an admin by their Firestore document ID.
   * @param {string} adminId - The Firestore document ID of the admin.
   * @param {string} email - The email of the admin.
   * @param {string} mobileNumber - The mobile number of the admin
   * @returns {Object} The found admin data.
   * @throws Throws an error if the admin is not found or the ID is invalid.
   */
  static async findAdmin(adminId, email, mobileNumber) {
    if (!adminId && !email && !mobileNumber) {
      throw new Error("adminService-findAdmin: Invalid input parameters");
    }

    let adminDoc;

    if (adminId) {
      adminDoc = await db.collection("admins").doc(adminId).get();
      if (!adminDoc.exists) {
        throw new Error("adminService-findAdmin: Invalid Admin Id");
      }
      return adminDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("admins")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("admins")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        throw new Error(
          "adminService-findAdmin: Invalid Email or Mobile Number"
        );
      }

      return querySnapshot.docs[0].data();
    }
  }

  /**
   * Fetches all admin accounts.
   * @returns {Array} A list of all admins in Firestore.
   */
  static async findAllAdmins() {
    const snapshot = await db.collection("admins").get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetch admins by hospital ID
   */
  static async findAllAdminsByHospital(hospitalId) {
    const snapshot = await db
      .collection("admins")
      .where("hospital", "==", hospitalId)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Deletes an admin account using their Firestore document ID.
   * @param {string} adminId - The Firestore document ID of the admin to be deleted.
   */
  static async deleteAdmin(adminId) {
    if (!adminId) {
      throw new Error("adminService-deleteAdmin: Invalid adminId");
    }

    const adminRef = db.collection("admins").doc(adminId);
    const adminDoc = await adminRef.get();

    if (!adminDoc.exists) {
      throw new Error("adminService-deleteAdmin: Admin not found");
    }

    await adminRef.delete();

    return;
  }

  /**
   * Updates an admin account in Firestore.
   * @param {string} adminId - The Firestore document ID of the admin.
   * @param {Object} updateFields - Fields to update.
   * @param {Object} user - The current user making the update.
   * @returns {Object} The updated admin data.
   */
  static async updateAdmin(adminId, updateFields, user) {
    if (!adminId) {
      throw new Error("adminService-updateAdmin: Invalid adminId");
    }

    // Check if Hospital ID is valid
    if (updateFields.hospital) {
      const hospitalDoc = await db
        .collection("hospitals")
        .doc(updateFields.hospital)
        .get();
      if (!hospitalDoc.exists) {
        throw new Error("adminService-updateAdmin: Hospital not found");
      }
    }

    if (updateFields.id) {
      throw new Error(
        "adminService-updateAdmin: Changing '_id' is not allowed"
      );
    }

    if (updateFields.role) {
      throw new Error(
        "adminService-updateAdmin: Changing 'role' is not allowed"
      );
    }

    // Internal helper function to check uniqueness across collections
    const checkUniqueness = async (field, value) => {
      const collections = ["patients", "doctors", "admins", "superadmins"];
      for (const collection of collections) {
        const snapshot = await db
          .collection(collection)
          .where(field, "==", value)
          .get();
        if (!snapshot.empty) {
          throw new Error(
            `adminService-updateAdmin: The ${field} '${value}' is already in use by another user`
          );
        }
      }
    };

    if (updateFields.persId) {
      await checkUniqueness("persId", updateFields.persId);
    }
    if (updateFields.email) {
      await checkUniqueness("email", updateFields.email);
    }
    if (updateFields.mobileNumber) {
      await checkUniqueness("mobileNumber", updateFields.mobileNumber);
    }

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error(
        "adminService-updateAdmin: Only superadmins can suspend admins"
      );
    }

    const adminRef = db.collection("admins").doc(adminId);
    const adminDoc = await adminRef.get();

    if (!adminDoc.exists) {
      throw new Error("adminService-updateAdmin: Admin not found");
    }

    await adminRef.update(updateFields);

    const updatedAdminDoc = await adminRef.get();
    const updatedAdmin = { id: updatedAdminDoc.id, ...updatedAdminDoc.data() };
    return updatedAdmin;
  }
}

module.exports = AdminService;
