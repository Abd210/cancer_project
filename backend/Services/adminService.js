const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

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
      return { id: adminDoc.id, ...adminDoc.data() };
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

      const doc = querySnapshot.docs[0];
      return { id: doc.id, ...doc.data() };
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

    return { message: "Doctor deleted successfully" };
  }

  /**
   * Helper function to manage bidirectional admin-hospital relationship
   * @param {string} adminId - The admin's ID
   * @param {string|null} newHospitalId - The new hospital ID (null to clear)
   * @param {string|null} oldHospitalId - The previous hospital ID (null if none)
   */
  static async _manageBidirectionalAdminHospitalRelation(adminId, newHospitalId, oldHospitalId) {
    const batch = db.batch();

    // 1. Clear the admin field from the old hospital (if any)
    if (oldHospitalId) {
      const oldHospitalRef = db.collection("hospitals").doc(oldHospitalId);
      batch.update(oldHospitalRef, { admin: null });
    }

    // 2. If there's a new hospital, handle the assignment
    if (newHospitalId) {
      const newHospitalRef = db.collection("hospitals").doc(newHospitalId);
      const newHospitalDoc = await newHospitalRef.get();
      
      if (newHospitalDoc.exists) {
        const hospitalData = newHospitalDoc.data();
        
        // 3. If the new hospital already has an admin, clear that admin's hospital field
        if (hospitalData.admin && hospitalData.admin !== adminId) {
          const previousAdminRef = db.collection("admins").doc(hospitalData.admin);
          batch.update(previousAdminRef, { hospital: null });
        }
        
        // 4. Set this admin as the hospital's admin
        batch.update(newHospitalRef, { admin: adminId });
      }
    }

    // Execute all updates atomically
    await batch.commit();
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

    const adminRef = db.collection("admins").doc(adminId);
    const adminDoc = await adminRef.get();

    if (!adminDoc.exists) {
      throw new Error("adminService-updateAdmin: Admin not found");
    }

    // 1) Whitelist allowed fields
    const ALLOWED = [
      "persId",
      "password",
      "name",
      "email",
      "mobileNumber",
      "hospital",
      "suspended"
    ];
    Object.keys(updateFields).forEach(key => {
      if (!ALLOWED.includes(key)) {
        throw new Error(`Field '${key}' is not allowed`);
      }
    });

    if (updateFields.hospital !== undefined) {
      if (updateFields.hospital === null || updateFields.hospital === "") {
        // Allow clearing the hospital assignment
        updateFields.hospital = null;
      } else {
        if (typeof updateFields.hospital !== "string") {
          throw new Error("Invalid hospital: must be a Firestore document reference");
        }
        // Check the hospital exists
        const hospitalDoc = await db
          .collection("hospitals")
          .doc(updateFields.hospital)
          .get();
        if (!hospitalDoc.exists) {
          throw new Error("adminService-updateAdmin: Hospital not found");
        }
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
    // const checkUniqueness = async (field, value) => {
    //   const collections = ["patients", "doctors", "admins", "superadmins"];
    //   for (const collection of collections) {
    //     const snapshot = await db
    //       .collection(collection)
    //       .where(field, "==", value)
    //       .get();
    //     if (!snapshot.empty) {
    //       throw new Error(
    //         `adminService-updateAdmin: The ${field} '${value}' is already in use by another user`
    //       );
    //     }
    //   }
    // };
    // Internal helper function to check uniqueness across collections,

    // const checkUniqueness = async (field, value, excludeId=null) => {
    //   const collections = ["patients", "doctors", "admins", "superadmins"];
    //   for (const col of collections) {
    //     const snapshot = await db
    //       .collection(col)
    //       .where(field, "==", value)
    //       .get();

    //     for (const doc of snapshot.docs) {
    //       if (doc.id !== excludeId) {
    //         throw new Error(
    //           `adminService-updateAdmin: The ${field} '${value}' is already in use`
    //         );
    //       }
    //     }
    //   }
    // };
    const checkUniqueness = async (field, value, excludeId = null) => {
      // Include hospitals too
      const collections = ["patients", "doctors", "admins", "superadmins", "hospitals"];
  
      let field_updated;
      switch (field) {
        case "email":
          field_updated = "emails";
          break;
        case "mobileNumber":
          field_updated = "mobileNumbers";
          break;
        case "persId":
          // persId is only checked in user collections, not hospitals
          for (const collection of ["patients", "doctors", "admins", "superadmins"]) {
            const snapshot = await db
              .collection(collection)
              .where(field, "==", value)
              .get();
            
            for (const doc of snapshot.docs) {
              // If we're excluding our own record, skip it
              if (doc.id !== excludeId) {
                throw new Error(`The ${field} '${value}' is already in use`);
              }
            }
          }
          return; // Exit early for persId since it doesn't need the rest of the logic
        default:
          throw new Error("Invalid field provided.");
      }
      
      for (const collection of collections) {
        let snapshot;
        
        if (collection === "hospitals") {
          // In hospitals, emails and mobileNumbers are arrays
          snapshot = await db
            .collection(collection)
            .where(field_updated, "array-contains", value)
            .get();
        } else {
          // In other collections these fields are scalars
          snapshot = await db
            .collection(collection)
            .where(field, "==", value)
            .get();
        }
        
        for (const doc of snapshot.docs) {
          // If we're excluding our own record, skip it
          if (doc.id !== excludeId) {
            throw new Error(`The ${field} '${value}' is already in use`);
          }
        }
      }
    }


    if (updateFields.persId !== undefined) {
      if (typeof updateFields.persId !== "string") {
        throw new Error("Invalid persId: must be a string");
      }
      await checkUniqueness("persId", updateFields.persId, adminId);
    }

    if (updateFields.email !== undefined) {
      if (typeof updateFields.email !== "string") {
        throw new Error("Invalid email: must be a string");
      }
      await checkUniqueness("email", updateFields.email, adminId);
    }

    if (updateFields.mobileNumber !== undefined) {
      if (typeof updateFields.mobileNumber !== "string") {
        throw new Error("Invalid mobileNumber: must be a string");
      }
      await checkUniqueness("mobileNumber", updateFields.mobileNumber, adminId);
    }

    if (updateFields.password !== undefined) {
      if (typeof updateFields.password !== "string") {
        throw new Error("Invalid password: must be a string");
      }
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.name !== undefined) {
      if (typeof updateFields.name !== "string") {
        throw new Error("Invalid name: must be a string");
      }
    }

    if (updateFields.suspended !== undefined) {
      if (typeof updateFields.suspended !== "boolean") {
        throw new Error("Invalid suspended: must be a boolean");
      }
      if (updateFields.suspended && user.role !== "superadmin") {
        throw new Error("adminService-updateAdmin: Only superadmins can suspend admins");
      }
    }

    // Handle bidirectional hospital-admin relationship if hospital field is being updated
    if (updateFields.hospital !== undefined) {
      const currentAdminData = adminDoc.data();
      const oldHospitalId = currentAdminData.hospital;
      const newHospitalId = updateFields.hospital;
      
      // Only manage bidirectional relationship if the hospital is actually changing
      if (oldHospitalId !== newHospitalId) {
        await this._manageBidirectionalAdminHospitalRelation(adminId, newHospitalId, oldHospitalId);
      }
    }

    updateFields.updatedAt = new Date()
    await adminRef.update(updateFields);

    const updatedAdminDoc = await adminRef.get();
    const updatedAdmin = { id: updatedAdminDoc.id, ...updatedAdminDoc.data() };
    return "Admin updated successfully";
  }
}

module.exports = AdminService;
