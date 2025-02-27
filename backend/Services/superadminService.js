const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

class SuperAdminService {
  /**
   * Finds an admin by their Firestore document ID.
   * @param {string} superAdminId - The Firestore document ID of the admin.
   * @param {string} email - The email of the admin.
   * @param {string} mobileNumber - The mobile number of the admin
   * @returns {Object} The found admin data.
   * @throws Throws an error if the admin is not found or the ID is invalid.
   */
  static async findSuperAdmin(superAdminId, email, mobileNumber) {
    if (!superAdminId && !email && !mobileNumber) {
      throw new Error(
        "superAdminService-findSuperAdmin: Invalid input parameters"
      );
    }

    let superAdminDoc;

    if (superAdminId) {
      superAdminDoc = await db
        .collection("superadmins")
        .doc(superAdminId)
        .get();
      if (!superAdminDoc.exists) {
        return null;
      }
      return superAdminDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("superadmins")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("superadmins")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        return null;
      }

      let superAdminData = querySnapshot.docs[0].data();

      return superAdminData;
    }
  }

  /**
   * Fetches all superadmin accounts.
   * @returns {Array} A list of all superadmins in Firestore.
   */
  static async findAllSuperAdmins() {
    const snapshot = await db.collection("superadmins").get();

    if (snapshot.empty) {
      return [];
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Deletes a superadmin account using their Firestore document ID.
   * @param {string} superAdminId - The Firestore document ID of the superadmin to be deleted.
   * @returns {Object} A success message or an error if the superadmin is not found.
   */
  static async deleteSuperAdmin(superAdminId) {
    if (!superAdminId) {
      throw new Error(
        "superAdminService-deleteSuperAdmin: Invalid superAdminId"
      );
    }

    const superAdminRef = db.collection("superadmins").doc(superAdminId);
    const superAdminDoc = await superAdminRef.get();

    if (!superAdminDoc.exists) {
      throw new Error(
        "superAdminService-deleteSuperAdmin: Superadmin not found"
      );
    }

    await superAdminRef.delete();

    return;
  }

  /**
   * Updates a superadmin account in Firestore.
   * @param {string} superAdminId - The Firestore document ID of the superadmin.
   * @param {Object} updateFields - Fields to update.
   * @param {Object} user - The current user making the update.
   * @returns {Object} The updated superadmin data.
   */
  static async updateSuperAdmin(superAdminId, updateFields, user) {
    if (!superAdminId) {
      throw new Error(
        "superAdminService-updateSuperAdmin: Invalid superAdminId"
      );
    }

    if (updateFields._id) {
      throw new Error(
        "superAdminService-updateSuperAdmin: Changing '_id' is not allowed"
      );
    }

    if (updateFields.role) {
      throw new Error(
        "superAdminService-updateSuperAdmin: Changing 'role' is not allowed"
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
            `superAdminService-updateSuperAdmin: The ${field} '${value}' is already in use by another user`
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

    const superAdminRef = db.collection("superadmins").doc(superAdminId);
    const superAdminDoc = await superAdminRef.get();

    if (!superAdminDoc.exists) {
      throw new Error(
        "superAdminService-updateSuperAdmin: Superadmin not found"
      );
    }

    await superAdminRef.update(updateFields);

    return {
      id: superAdminId,
      ...updateFields,
    };
  }
}

module.exports = SuperAdminService;
