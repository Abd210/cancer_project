const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");

class PatientService {
  /**
   * Fetch a patient's full data from Firestore.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async getPatientData(patientId) {
    const patientDoc = await db.collection("patients").doc(patientId).get();
    if (!patientDoc.exists) throw new Error("Patient not found");

    return { id: patientDoc.id, ...patientDoc.data() };
  }

  /**
   * Get a patient's diagnosis field.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async getPatientDiagnosis(patientId) {
    const patient = await this.getPatientData(patientId);
    return { diagnosis: patient.diagnosis || "Not Diagnosed" };
  }

  static async findPatient(patientId, email, mobileNumber) {
    if (!patientId && !email && !mobileNumber) {
      throw new Error("patientService-findPatient: Invalid input parameters");
    }

    let patientDoc;

    if (patientId) {
      patientDoc = await db.collection("patients").doc(patientId).get();
      if (!patientDoc.exists) {
        throw new Error("patientService-findPatient: Invalid Patient Id");
      }
      return patientDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("patients")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("patients")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        throw new Error(
          "patientService-findPatient: Invalid Email or Mobile Number"
        );
      }

      return querySnapshot.docs[0].data();
    }
  }

  /**
   * Fetch all patients from Firestore.
   */
  static async findAllPatients() {
    const snapshot = await db.collection("patients").get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetch all patients belonging to a specific hospital.
   * @param {string} hospitalId - The Firestore ID of the hospital.
   */
  static async findAllPatientsByHospital(hospitalId) {
    const snapshot = await db
      .collection("patients")
      .where("hospital", "==", hospitalId)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Retrieves a list of patients assigned to a specific doctor.
   *
   * @param {String} doctorId - The ID of the doctor to filter patients by.
   * @returns {Array} - An array of patient records assigned to the specified doctor.
   */
  static async findAllPatientsByDoctor(doctorId) {
    const snapshot = await db
      .collection("patients")
      .where("doctor", "==", doctorId)
      .get();

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Ensures uniqueness across collections (patients, doctors, admins, superadmins).
   * @param {string} field - The field to check (e.g., email, persId, mobileNumber).
   * @param {string} value - The value to check for uniqueness.
   * @param {string} excludeId - (Optional) The ID to exclude (for updates).
   */
  // static async checkUniqueness(field, value, excludeId = null) {
  //   const collections = ["patients", "doctors", "admins", "superadmins"];
  //   for (const collection of collections) {
  //     const snapshot = await db
  //       .collection(collection)
  //       .where(field, "==", value)
  //       .get();
  //     for (const doc of snapshot.docs) {
  //       if (doc.id !== excludeId) {
  //         throw new Error(`The ${field} '${value}' is already in use`);
  //       }
  //     }
  //   }
  // }
  static async checkUniqueness(field, value, excludeId = null) {
    // Include hospitals too
    const collections = [
      "patients",
      "doctors",
      "admins",
      "superadmins",
      "hospitals",
    ];

    let field_updated;
    switch (field) {
      case "email":
        field_updated = "emails";
        break;
      case "mobileNumber":
        field_updated = "mobileNumbers";
        break;
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

  /**
   * Update a patient's data securely.
   * @param {string} patientId - The Firestore ID of the patient.
   * @param {Object} updateFields - The fields to update.
   * @param {Object} user - The authenticated user making the request.
   */
  static async updatePatient(patientId, updateFields, user) {
    const patientRef = db.collection("patients").doc(patientId);
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) throw new Error("Patient not found");

    const currentPatientData = patientDoc.data(); // Get current patient data

    // ░░░ 1. Define allowed fields for patient updates ░░░
    const ALLOWED_FIELDS = [
      "persId",
      "password",
      "name",
      "email",
      "mobileNumber",
      "birthDate",
      "hospital",
      "status",
      "diagnosis",
      "medicalHistory",
      "doctor",
      "suspended",
    ];

    // ░░░ 2. Remove extra or undefined fields ░░░
    Object.keys(updateFields).forEach((key) => {
      if (updateFields[key] === undefined) {
        delete updateFields[key];
      } else if (!ALLOWED_FIELDS.includes(key)) {
        // Either throw an error or silently remove the extra field.
        throw new Error(`Field '${key}' is not allowed`);
        // delete updateFields[key];
      }
    });

    if (updateFields.id) delete updateFields.id;
    if (updateFields.role !== undefined) throw new Error("Cannot change role");

    // if (updateFields.email)
    //   await this.checkUniqueness("email", updateFields.email, patientId);
    if (updateFields.email !== undefined) {
      if (typeof updateFields.email !== "string") {
        throw new Error("Invalid email: must be a string");
      }
      await this.checkUniqueness("email", updateFields.email, patientId);
    }

    // if (updateFields.mobileNumber)
    //   await this.checkUniqueness(
    //     "mobileNumber",
    //     updateFields.mobileNumber,
    //     patientId
    //   );
    if (updateFields.mobileNumber !== undefined) {
      if (typeof updateFields.mobileNumber !== "string") {
        throw new Error("Invalid mobileNumber: must be a string");
      }
      await this.checkUniqueness(
        "mobileNumber",
        updateFields.mobileNumber,
        patientId
      );
    }

    if (updateFields.birthDate !== undefined) {
      const parsedDate = new Date(updateFields.birthDate);
      if (isNaN(parsedDate.getTime())) {
        throw new Error("Invalid birthDate: must be a valid Date string");
      }
      updateFields.birthDate = parsedDate;
    }

    // if (updateFields.persId)
    //   await this.checkUniqueness("persId", updateFields.persId, patientId);
    if (updateFields.persId !== undefined) {
      if (typeof updateFields.persId !== "string") {
        throw new Error("Invalid persId: must be a string");
      }
      await this.checkUniqueness("persId", updateFields.persId, patientId);
    }

    if (updateFields.hospital !== undefined) {
      if (typeof updateFields.hospital !== "string") {
        throw new Error(
          "Invalid hospital: must be a Firestore document reference string"
        );
      }
      const hospitalDoc = await db
        .collection("hospitals")
        .doc(updateFields.hospital)
        .get();
      if (!hospitalDoc.exists) {
        throw new Error("Invalid hospital: Hospital does not exist");
      }
    }

    // if (updateFields.password) {
    //   const salt = await bcrypt.genSalt(10);
    //   updateFields.password = await bcrypt.hash(updateFields.password, salt);
    // }
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

    // if (updateFields.suspended && user.role !== "superadmin") {
    //   throw new Error("Only superadmins can suspend patients");
    // }
    if (updateFields.suspended !== undefined) {
      if (typeof updateFields.suspended !== "boolean") {
        throw new Error("Invalid suspended: must be a boolean");
      }
      if (updateFields.suspended && user.role !== "superadmin") {
        throw new Error("Only superadmins can suspend patients");
      }
    }

    if (updateFields.status !== undefined) {
      const STATUSES = ["recovering", "recovered", "active", "inactive"];
      if (
        typeof updateFields.status !== "string" ||
        !STATUSES.includes(updateFields.status)
      ) {
        throw new Error(
          `Invalid status: ${updateFields.status}. Allowed: ${STATUSES.join(
            ", "
          )}`
        );
      }
    }

    if (updateFields.diagnosis !== undefined) {
      if (typeof updateFields.diagnosis !== "string") {
        throw new Error("Invalid diagnosis: must be a string");
      }
    }

    if (updateFields.medicalHistory !== undefined) {
      if (
        !Array.isArray(updateFields.medicalHistory) ||
        !updateFields.medicalHistory.every((item) => typeof item === "string")
      ) {
        throw new Error("Invalid medicalHistory: must be an array of strings");
      }
    }

    // if (
    //   updateFields.doctor &&
    //   updateFields.doctor !== currentPatientData.doctor
    // ) {
    //   const previousDoctorId = currentPatientData.doctor;
    //   const newDoctorId = updateFields.doctor;

    //   await db.runTransaction(async (transaction) => {
    //     // Read all necessary data first
    //     let prevDoctorRef, newDoctorRef;
    //     if (previousDoctorId)
    //       prevDoctorRef = db.collection("doctors").doc(previousDoctorId);
    //     if (newDoctorId)
    //       newDoctorRef = db.collection("doctors").doc(newDoctorId);

    //     if (previousDoctorId) {
    //       transaction.update(prevDoctorRef, {
    //         patients: admin.firestore.FieldValue.arrayRemove(patientId),
    //       });
    //     }

    //     if (newDoctorId) {
    //       transaction.update(newDoctorRef, {
    //         patients: admin.firestore.FieldValue.arrayUnion(patientId),
    //       });
    //     }

    //     // Update the patient's document
    //     updateFields.updatedAt = new Date();
    //     transaction.update(patientRef, updateFields);
    //   });
    // } else {
    //   // If the doctor field is NOT being updated, update the patient normally
    //   updateFields.updatedAt = new Date();
    //   await patientRef.update(updateFields);
    // }

    if (
      updateFields.doctor &&
      updateFields.doctor !== currentPatientData.doctor
    ) {
      // Validate that the new doctor exists.
      const newDoctorDoc = await db
        .collection("doctors")
        .doc(updateFields.doctor)
        .get();
      if (!newDoctorDoc.exists) {
        throw new Error("Invalid doctor: new doctor not found");
      }

      await db.runTransaction(async (transaction) => {
        let prevDoctorRef, newDoctorRef;
        if (currentPatientData.doctor) {
          prevDoctorRef = db
            .collection("doctors")
            .doc(currentPatientData.doctor);
        }
        newDoctorRef = db.collection("doctors").doc(updateFields.doctor);

        if (currentPatientData.doctor) {
          transaction.update(prevDoctorRef, {
            patients: admin.firestore.FieldValue.arrayRemove(patientId),
          });
        }
        transaction.update(newDoctorRef, {
          patients: admin.firestore.FieldValue.arrayUnion(patientId),
        });
        updateFields.updatedAt = new Date();
        transaction.update(patientRef, updateFields);
      });
    } else {
      updateFields.updatedAt = new Date();
      await patientRef.update(updateFields);
    }

    const updatedPatientDoc = await patientRef.get();
    return { id: updatedPatientDoc.id, ...updatedPatientDoc.data() };
  }

  /**
   * Delete a patient from Firestore.
   * @param {string} patientId - The Firestore ID of the patient.
   */
  static async deletePatient(patientId) {
    const patientRef = db.collection("patients").doc(patientId);
    const patientDoc = await patientRef.get();

    if (!patientDoc.exists) throw new Error("Patient not found");

    // Start Firestore batch operation
    const batch = db.batch();

    const patientData = patientDoc.data();
    const doctorId = patientData?.doctor; // Safely get doctor ID

    // 🔹 Remove patient from doctor's patients array before deletion
    if (doctorId && typeof doctorId === "string" && doctorId.trim() !== "") {
      const doctorRef = db.collection("doctors").doc(doctorId);
      batch.update(doctorRef, {
        patients: admin.firestore.FieldValue.arrayRemove(patientId),
      });
    }

    // 🔹 Delete all appointments and tests where "patient" field matches patientId
    const deleteAppointmentsAndTests = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("patient", "==", patientId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments");
    await deleteAppointmentsAndTests("tests");

    // 🔹 Delete the patient itself
    batch.delete(patientRef);

    // Commit batch
    await batch.commit();

    return { message: "Patient deleted successfully" };
  }
}

module.exports = PatientService;
