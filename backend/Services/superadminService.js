const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

class SuperAdminService {
  /**
   * Finds a superadmin by their Firestore document ID.
   * @param {string} superAdminId - The Firestore document ID of the superadmin.
   * @returns {Object} The found superadmin data.
   * @throws Throws an error if the superadmin is not found or the ID is invalid.
   */
  static async findSuperAdmin(superAdminId) {
    if (!superAdminId) {
      throw new Error(
        "superAdminService-findSuperAdmin: Invalid superadmin id"
      );
    }

    const superAdminDoc = await db
      .collection("superadmins")
      .doc(superAdminId)
      .get();

    if (!superAdminDoc.exists) {
      throw new Error("superAdminService-findSuperAdmin: Superadmin not found");
    }

    return { id: superAdminDoc.id, ...superAdminDoc.data() };
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

    return { message: "Superadmin successfully deleted", superAdminId };
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

    if (updateFields.pers_id) {
      await checkUniqueness("pers_id", updateFields.pers_id);
    }
    if (updateFields.email) {
      await checkUniqueness("email", updateFields.email);
    }
    if (updateFields.mobile_number) {
      await checkUniqueness("mobile_number", updateFields.mobile_number);
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
      message: "Superadmin updated successfully",
      id: superAdminId,
      ...updateFields,
    };
  }
}

module.exports = SuperAdminService;
