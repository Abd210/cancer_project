const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");
const Hospital = require("../Models/Hospital");

class HospitalService {
  /**
   * Registers a new hospital while ensuring uniqueness of name, emails, and mobile numbers.
   * @param {Object} hospitalData - The hospital data.
   * @param {string} hospitalData.name - The name of the hospital.
   * @param {string} hospitalData.address - The address of the hospital.
   * @param {Array<string>} hospitalData.mobileNumbers - The mobile numbers of the hospital.
   * @param {Array<string>} hospitalData.emails - The emails of the hospital.
   * @param {string} [hospitalData.admin] - The Firestore ID of the hospital's admin.
   * @param {boolean} [hospitalData.suspended] - The suspended status of the hospital.
   * @returns {Promise<Object>} The newly registered hospital data including its ID.
   * @throws {Error} If a hospital with the same name and address already exists or if emails/mobile numbers are not unique.
   */
  static async register({ name, address, mobileNumbers, emails, admin: adminId, suspended }) {
    const hospitalRef = db.collection("hospitals");

    // Check if a hospital with the same name and address already exists
    const existingHospitals = await hospitalRef
      .where("name", "==", name)
      .where("address", "==", address)
      .get();

    if (!existingHospitals.empty) {
      throw new Error(
        "Hospital already exists with the same name and address."
      );
    }

    // Check uniqueness of emails and mobile numbers
    await this._checkUniqueFields("emails", emails);
    await this._checkUniqueFields("mobileNumbers", mobileNumbers);

    // Validate admin if provided
    if (adminId !== undefined && adminId !== null && adminId !== "") {
      if (typeof adminId !== "string") {
        throw new Error("Invalid admin: must be a string");
      }
      
      // Check if the admin exists in the admins collection
      const adminDoc = await db.collection("admins").doc(adminId).get();
      if (!adminDoc.exists) {
        throw new Error("Admin not found with the provided ID");
      }
    }

    // Add new hospital
    const newHospital = {
      name,
      address,
      mobileNumbers,
      emails,
      admin: adminId || "", // Default to empty string
      createdAt: admin.firestore.Timestamp.now(),
      suspended: suspended || false,
    };

    const docRef = await hospitalRef.add(newHospital);
    const hospitalId = docRef.id;

    // Handle bidirectional relationship if admin is provided and not empty
    if (adminId && adminId !== "") {
      await this._manageBidirectionalHospitalAdminRelation(hospitalId, adminId, null);
    }

    return { id: hospitalId, ...newHospital };
  }

  /**
   * Retrieves hospital data by ID.
   * @param {string} hospitalId - The ID of the hospital.
   * @returns {Promise<Object>} The hospital data including its ID.
   * @throws {Error} If the hospital is not found.
   */
  static async getHospitalData(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    return { id: hospitalDoc.id, ...hospitalDoc.data() };
  }

  /**
   * Helper function to manage bidirectional hospital-admin relationship
   * @param {string} hospitalId - The hospital's ID
   * @param {string|null} newAdminId - The new admin ID (null to clear)
   * @param {string|null} oldAdminId - The previous admin ID (null if none)
   */
  static async _manageBidirectionalHospitalAdminRelation(hospitalId, newAdminId, oldAdminId) {
    const batch = db.batch();

    // 1. Clear the hospital field from the old admin (if any)
    if (oldAdminId) {
      const oldAdminRef = db.collection("admins").doc(oldAdminId);
      batch.update(oldAdminRef, { hospital: null });
    }

    // 2. If there's a new admin, handle the assignment
    if (newAdminId) {
      const newAdminRef = db.collection("admins").doc(newAdminId);
      const newAdminDoc = await newAdminRef.get();
      
      if (newAdminDoc.exists) {
        const adminData = newAdminDoc.data();
        
        // 3. If the new admin already has a hospital, clear that hospital's admin field
        if (adminData.hospital && adminData.hospital !== hospitalId) {
          const previousHospitalRef = db.collection("hospitals").doc(adminData.hospital);
          batch.update(previousHospitalRef, { admin: null });
        }
        
        // 4. Set this hospital as the admin's hospital
        batch.update(newAdminRef, { hospital: hospitalId });
      }
    }

    // Execute all updates atomically
    await batch.commit();
  }

  /**
   * Updates hospital details, ensuring uniqueness for emails and mobile numbers.
   * @param {string} hospitalId - The ID of the hospital to update.
   * @param {Object} updateFields - The fields to update.
   * @param {Array<string>} [updateFields.emails] - The new emails of the hospital.
   * @param {Array<string>} [updateFields.mobileNumbers] - The new mobile numbers of the hospital.
   * @param {string} [updateFields.admin] - The Firestore ID of the hospital's admin.
   * @returns {Promise<Object>} A message indicating the hospital was updated successfully.
   * @throws {Error} If the hospital is not found or if emails/mobile numbers are not unique.
   */
  static async updateHospital(hospitalId, updateFields, user) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }

    // 1. Whitelist allowed fields
    const ALLOWED_FIELDS = ["name","address","mobileNumbers","emails","admin","suspended"];
    Object.keys(updateFields).forEach(key => {
      if (!ALLOWED_FIELDS.includes(key)) {
        throw new Error(`Field '${key}' is not allowed`);
      }
    });

    // Prevent updating `_id`
    // if (updateFields._id) {
    //   throw new Error("Changing '_id' is not allowed.");
    // }

    if (updateFields.name !== undefined) {
      if (typeof updateFields.name !== "string") {
        throw new Error("Invalid name: must be a string");
      }
    }

    if (updateFields.address !== undefined) {
      if (typeof updateFields.address !== "string") {
        throw new Error("Invalid address: must be a string");
      }
    }

    // Check uniqueness of emails and mobile numbers if updated
    // if (updateFields.emails)
    //   await this._checkUniqueFields("emails", updateFields.emails, hospitalId);

    if (updateFields.emails !== undefined) {
      if (
        !Array.isArray(updateFields.emails) ||
        !updateFields.emails.every(email => typeof email === "string")
      ) {
        throw new Error("Invalid emails: must be an array of strings");
      }
      await this._checkUniqueFields("emails", updateFields.emails, hospitalId);
    }
    // if (updateFields.mobileNumbers)
    //   await this._checkUniqueFields(
    //     "mobileNumbers",
    //     updateFields.mobileNumbers,
    //     hospitalId
    //   );
    if (updateFields.mobileNumbers !== undefined) {
      if (
        !Array.isArray(updateFields.mobileNumbers) ||
        !updateFields.mobileNumbers.every(num => typeof num === "string")
      ) {
        throw new Error("Invalid mobileNumbers: must be an array of strings");
      }
      await this._checkUniqueFields("mobileNumbers", updateFields.mobileNumbers, hospitalId);
    }

    if (updateFields.suspended !== undefined) {
      if (typeof updateFields.suspended !== "boolean") {
        throw new Error("Invalid suspended: must be a boolean");
      }
      if (updateFields.suspended && user.role !== "superadmin") {
        throw new Error("Only superadmins can suspend doctors");
      }
    }

    if (updateFields.admin !== undefined) {
      if (updateFields.admin === null || updateFields.admin === "") {
        // Allow clearing the admin field - convert to empty string for consistency
        updateFields.admin = "";
      } else {
        if (typeof updateFields.admin !== "string") {
          throw new Error("Invalid admin: must be a string or null");
        }
        
        // Check if the admin exists in the admins collection
        const adminDoc = await db.collection("admins").doc(updateFields.admin).get();
        if (!adminDoc.exists) {
          throw new Error("Admin not found with the provided ID");
        }
      }
    }

    // Handle bidirectional admin-hospital relationship if admin field is being updated
    if (updateFields.admin !== undefined) {
      const currentHospitalData = hospitalDoc.data();
      const oldAdminId = currentHospitalData.admin || "";
      const newAdminId = updateFields.admin || "";
      
      // Only manage bidirectional relationship if the admin is actually changing
      if (oldAdminId !== newAdminId) {
        // Pass null for empty strings to the relationship manager
        const oldAdminForRelation = oldAdminId === "" ? null : oldAdminId;
        const newAdminForRelation = newAdminId === "" ? null : newAdminId;
        await this._manageBidirectionalHospitalAdminRelation(hospitalId, newAdminForRelation, oldAdminForRelation);
      }
    }

    updateFields.updatedAt = admin.firestore.Timestamp.now
    ? admin.firestore.Timestamp.now()
    : new Date();
    await hospitalRef.update(updateFields);
    return "Hospital updated successfully.";
  }

  /**
   * Deletes a hospital and all associated data (patients, doctors, admins, appointments, tests).
   * @param {string} hospitalId - The ID of the hospital to delete.
   * @returns {Promise<Object>} A message indicating the hospital and all associated records were successfully deleted.
   * @throws {Error} If the hospital is not found.
   */
  static async deleteHospital(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();
    if (!hospitalDoc.exists) {
      throw new Error("Hospital not found.");
    }
  
    const batch = db.batch();
  
    // Helper to collect all IDs in a collection where hospital==hospitalId
    const collectIds = async (collection) => {
      const snap = await db
        .collection(collection)
        .where("hospital", "==", hospitalId)
        .get();
      return snap.docs.map(d => d.id);
    };
  
    const patientIds = await collectIds("patients");
    const doctorIds  = await collectIds("doctors");
  
    // Delete Patients, Doctors, Admins linked to this hospital
    for (const coll of ["patients","doctors","admins"]) {
      const snap = await db
        .collection(coll)
        .where("hospital", "==", hospitalId)
        .get();
      snap.forEach(d => batch.delete(d.ref));
    }
  
    // 🔹 Delete Appointments by patient IDs
    if (patientIds.length > 0) {
      const apptByPatient = await db
        .collection("appointments")
        .where("patient", "in", patientIds)
        .get();
      apptByPatient.forEach(d => batch.delete(d.ref));
  
      const testsByPatient = await db
        .collection("tests")
        .where("patient", "in", patientIds)
        .get();
      testsByPatient.forEach(d => batch.delete(d.ref));
    }
  
    // 🔹 Delete Appointments by doctor IDs
    if (doctorIds.length > 0) {
      const apptByDoctor = await db
        .collection("appointments")
        .where("doctor", "in", doctorIds)
        .get();
      apptByDoctor.forEach(d => batch.delete(d.ref));
  
      const testsByDoctor = await db
        .collection("tests")
        .where("doctor", "in", doctorIds)
        .get();
      testsByDoctor.forEach(d => batch.delete(d.ref));
    }
  
    // Finally, delete the hospital itself
    batch.delete(hospitalRef);
    await batch.commit();
  
    return { message: "Hospital and all associated records deleted successfully." };
  }
  
  static async findHospital(hospitalId) {
    const hospitalRef = db.collection("hospitals").doc(hospitalId);
    const hospitalDoc = await hospitalRef.get();

    if (!hospitalDoc.exists) {
      throw new Error("hospitalService-findHospital: Invalid Hospital ID");
    }

    return { id: hospitalDoc.id, ...hospitalDoc };
  }

  /**
   * Retrieves all hospitals.
   * @returns {Promise<Array<Object>>} An array of all hospitals including their IDs.
   * @throws {Error} If no hospitals are found.
   */
  static async findAllHospitals() {
    const snapshot = await db.collection("hospitals").get();
    if (snapshot.empty) {
      throw new Error("No hospitals found.");
    }

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  static async _checkUniqueFields(field, values, hospitalId = null) {
    const collections = ["patients", "doctors", "admins", "superadmins", "hospitals"];
  
    let field_updated;
    switch (field) {
      case "emails":
        field_updated = "email";
        break;
      case "mobileNumbers":
        field_updated = "mobileNumber";
        break;
      default:
        throw new Error("Invalid field provided.");
    }
  
    // Helper to chunk values into groups of 10
    const chunkArray = (arr, size) => {
      const result = [];
      for (let i = 0; i < arr.length; i += size) {
        result.push(arr.slice(i, i + size));
      }
      return result;
    };
  
    for (const coll of collections) {
      if (coll === "hospitals") {
        // Only one query needed since we're using `array-contains-any`
        const snapshot = await db
          .collection(coll)
          .where(field, "array-contains-any", values)
          .get();
  
        snapshot.docs.forEach((doc) => {
          if (hospitalId && doc.id === hospitalId) return;
          throw new Error(`One of the ${field} is already in use.`);
        });
      } else {
        const valueChunks = chunkArray(values, 10);
  
        for (const chunk of valueChunks) {
          const snapshot = await db
            .collection(coll)
            .where(field_updated, "in", chunk)
            .get();
  
          snapshot.docs.forEach((doc) => {
            throw new Error(`One of the ${field} is already in use.`);
          });
        }
      }
    }
  }  
  
  /**
   * Add an entity ID to a hospital's array (doctors, patients, or appointments)
   * @param {string} hospitalId - The hospital ID
   * @param {string} entityId - The entity ID to add  
   * @param {string} arrayType - The array type ('doctors', 'patients', or 'appointments')
   */
  static async addEntityToHospital(hospitalId, entityId, arrayType) {
    if (!hospitalId || !entityId || !arrayType) {
      throw new Error("HospitalService-addEntityToHospital: Missing required parameters");
    }

    const validArrayTypes = ['doctors', 'patients', 'appointments'];
    if (!validArrayTypes.includes(arrayType)) {
      throw new Error(`HospitalService-addEntityToHospital: Invalid array type. Must be one of: ${validArrayTypes.join(', ')}`);
    }

    try {
      const hospitalRef = db.collection("hospitals").doc(hospitalId);
      const hospitalDoc = await hospitalRef.get();
      
      if (!hospitalDoc.exists) {
        throw new Error("HospitalService-addEntityToHospital: Hospital not found");
      }

      // Use arrayUnion to add the entity ID if it doesn't already exist
      await hospitalRef.update({
        [arrayType]: admin.firestore.FieldValue.arrayUnion(entityId),
        updatedAt: new Date()
      });

      console.log(`Added ${entityId} to hospital ${hospitalId} ${arrayType} array`);
    } catch (error) {
      console.error("Error in addEntityToHospital:", error);
      throw new Error(`HospitalService-addEntityToHospital: ${error.message}`);
    }
  }

  /**
   * Remove an entity ID from a hospital's array (doctors, patients, or appointments)
   * @param {string} hospitalId - The hospital ID
   * @param {string} entityId - The entity ID to remove
   * @param {string} arrayType - The array type ('doctors', 'patients', or 'appointments')
   */
  static async removeEntityFromHospital(hospitalId, entityId, arrayType) {
    if (!hospitalId || !entityId || !arrayType) {
      throw new Error("HospitalService-removeEntityFromHospital: Missing required parameters");
    }

    const validArrayTypes = ['doctors', 'patients', 'appointments'];
    if (!validArrayTypes.includes(arrayType)) {
      throw new Error(`HospitalService-removeEntityFromHospital: Invalid array type. Must be one of: ${validArrayTypes.join(', ')}`);
    }

    try {
      const hospitalRef = db.collection("hospitals").doc(hospitalId);
      const hospitalDoc = await hospitalRef.get();
      
      if (!hospitalDoc.exists) {
        throw new Error("HospitalService-removeEntityFromHospital: Hospital not found");
      }

      // Use arrayRemove to remove the entity ID
      await hospitalRef.update({
        [arrayType]: admin.firestore.FieldValue.arrayRemove(entityId),
        updatedAt: new Date()
      });

      console.log(`Removed ${entityId} from hospital ${hospitalId} ${arrayType} array`);
    } catch (error) {
      console.error("Error in removeEntityFromHospital:", error);
      throw new Error(`HospitalService-removeEntityFromHospital: ${error.message}`);
    }
  }

  /**
   * Move an entity from one hospital to another
   * @param {string} oldHospitalId - The current hospital ID
   * @param {string} newHospitalId - The new hospital ID
   * @param {string} entityId - The entity ID to move
   * @param {string} arrayType - The array type ('doctors', 'patients')
   */
  static async moveEntityBetweenHospitals(oldHospitalId, newHospitalId, entityId, arrayType) {
    if (!oldHospitalId || !newHospitalId || !entityId || !arrayType) {
      throw new Error("HospitalService-moveEntityBetweenHospitals: Missing required parameters");
    }

    const validArrayTypes = ['doctors', 'patients']; // appointments can't be moved
    if (!validArrayTypes.includes(arrayType)) {
      throw new Error(`HospitalService-moveEntityBetweenHospitals: Invalid array type. Must be one of: ${validArrayTypes.join(', ')}`);
    }

    try {
      // Remove from old hospital
      await this.removeEntityFromHospital(oldHospitalId, entityId, arrayType);
      
      // Add to new hospital
      await this.addEntityToHospital(newHospitalId, entityId, arrayType);

      console.log(`Moved ${entityId} from hospital ${oldHospitalId} to ${newHospitalId} in ${arrayType} array`);
    } catch (error) {
      console.error("Error in moveEntityBetweenHospitals:", error);
      throw new Error(`HospitalService-moveEntityBetweenHospitals: ${error.message}`);
    }
  }

  /**
   * Get entities from hospital arrays
   * @param {string} hospitalId - The hospital ID
   * @param {string} arrayType - The array type ('doctors', 'patients', or 'appointments')
   * @returns {Promise<Array>} Array of entity IDs
   */
  static async getHospitalEntities(hospitalId, arrayType) {
    if (!hospitalId || !arrayType) {
      throw new Error("HospitalService-getHospitalEntities: Missing required parameters");
    }

    const validArrayTypes = ['doctors', 'patients', 'appointments'];
    if (!validArrayTypes.includes(arrayType)) {
      throw new Error(`HospitalService-getHospitalEntities: Invalid array type. Must be one of: ${validArrayTypes.join(', ')}`);
    }

    try {
      const hospitalRef = db.collection("hospitals").doc(hospitalId);
      const hospitalDoc = await hospitalRef.get();
      
      if (!hospitalDoc.exists) {
        throw new Error("HospitalService-getHospitalEntities: Hospital not found");
      }

      const hospitalData = hospitalDoc.data();
      return hospitalData[arrayType] || [];
    } catch (error) {
      console.error("Error in getHospitalEntities:", error);
      throw new Error(`HospitalService-getHospitalEntities: ${error.message}`);
    }
  }

  /**
   * Get full entity data for entities in a hospital array
   * @param {string} hospitalId - The hospital ID
   * @param {string} arrayType - The array type ('doctors', 'patients', or 'appointments')
   * @returns {Promise<Array>} Array of entity objects with full data
   */
  static async getHospitalEntitiesWithData(hospitalId, arrayType) {
    if (!hospitalId || !arrayType) {
      throw new Error("HospitalService-getHospitalEntitiesWithData: Missing required parameters");
    }

    const validArrayTypes = ['doctors', 'patients', 'appointments'];
    if (!validArrayTypes.includes(arrayType)) {
      throw new Error(`HospitalService-getHospitalEntitiesWithData: Invalid array type. Must be one of: ${validArrayTypes.join(', ')}`);
    }

    try {
      // Get the entity IDs from the hospital array
      const entityIds = await this.getHospitalEntities(hospitalId, arrayType);
      
      if (entityIds.length === 0) {
        return [];
      }

      // Fetch the full data for each entity
      const entities = [];
      for (const entityId of entityIds) {
        try {
          const entityDoc = await db.collection(arrayType).doc(entityId).get();
          if (entityDoc.exists) {
            entities.push({ id: entityDoc.id, ...entityDoc.data() });
          }
        } catch (error) {
          console.error(`Error fetching ${arrayType} ${entityId}:`, error);
          // Continue with other entities even if one fails
        }
      }

      return entities;
    } catch (error) {
      console.error("Error in getHospitalEntitiesWithData:", error);
      throw new Error(`HospitalService-getHospitalEntitiesWithData: ${error.message}`);
    }
  }
}

module.exports = HospitalService;
