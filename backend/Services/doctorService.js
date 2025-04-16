const admin = require("firebase-admin");
const db = admin.firestore();
const bcrypt = require("bcrypt");
const PatientService = require("./patientService");

class DoctorService {
  /**
   * Get public doctor data (excluding sensitive fields)
   */
  static async getPublicData(doctorId) {
    const doctorDoc = await db.collection("doctors").doc(doctorId).get();
    if (!doctorDoc.exists) throw new Error("Doctor not found");

    const doctorData = doctorDoc.data();
    delete doctorData.password; // Remove sensitive data
    delete doctorData.persId;
    delete doctorData.role;
    delete doctorData.createdAt;
    delete doctorData.updatedAt;

    return { id: doctorDoc.id, ...doctorData };
  }

  static async findDoctor(doctorId, email, mobileNumber) {
    if (!doctorId && !email && !mobileNumber) {
      throw new Error("doctorService-findDoctor: Invalid input parameters");
    }

    let doctorDoc;

    if (doctorId) {
      doctorDoc = await db.collection("doctors").doc(doctorId).get();
      if (!doctorDoc.exists) {
        throw new Error("doctorService-findDoctor: Invalid Doctor Id");
      }
      return doctorDoc.data();
    } else {
      let querySnapshot;

      if (email) {
        querySnapshot = await db
          .collection("doctors")
          .where("email", "==", email)
          .get();
      } else if (mobileNumber) {
        querySnapshot = await db
          .collection("doctors")
          .where("mobileNumber", "==", mobileNumber)
          .get();
      }

      if (querySnapshot.empty) {
        throw new Error(
          "doctorService-findDoctor: Invalid Email or Mobile Number"
        );
      }

      return querySnapshot.docs[0].data();
    }
  }

  /**
   * Get full doctor data
   */
  static async getDoctorData(doctorId) {
    const doctorDoc = await db.collection("doctors").doc(doctorId).get();
    if (!doctorDoc.exists) throw new Error("Doctor not found");
    return { id: doctorDoc.id, ...doctorDoc.data() };
  }

  /**
   * Retrieves all patients assigned to a specific doctor.
   * It queries the "patients" collection for documents where the "doctor" field equals the provided doctorId.
   * 
   * @param {string} doctorId - The ID of the doctor.
   * @returns {Promise<Array>} A list of patient objects.
   */
  static async getPatientsAssignedToDoctor(doctorId) {
    if (!doctorId) {
      throw new Error("doctorService-getPatientsAssignedToDoctor: Missing doctorId");
    }

    const snapshot = await db.collection("patients")
      .where("doctor", "==", doctorId)
      .get();

    if (snapshot.empty) {
      return []; // No patients found
    }
    
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  }


  /**
   * Fetch all doctors
   */
  static async findAllDoctors() {
    const snapshot = await db.collection("doctors").get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Fetch doctors by hospital ID
   */
  static async findAllDoctorsByHospital(hospitalId) {
    const snapshot = await db
      .collection("doctors")
      .where("hospital", "==", hospitalId)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  /**
   * Ensure uniqueness across collections
   */
  static async checkUniqueness(field, value, excludeId = null) {
    const collections = ["patients", "doctors", "admins", "superadmins"];
    for (const collection of collections) {
      const snapshot = await db
        .collection(collection)
        .where(field, "==", value)
        .get();
      for (const doc of snapshot.docs) {
        if (doc.id !== excludeId) {
          throw new Error(`The ${field} '${value}' is already in use`);
        }
      }
    }
  }

  /**
   * Update doctor data
   */
  static async updateDoctor(doctorId, updateFields, user) {
    const doctorRef = db.collection("doctors").doc(doctorId);
    const doctorDoc = await doctorRef.get();

    if (!doctorDoc.exists) throw new Error("Doctor not found");

    if (updateFields.id) delete updateFields.id;
    if (updateFields.role) throw new Error("Cannot change role");

    if (updateFields.email)
      await this.checkUniqueness("email", updateFields.email, doctorId);
    if (updateFields.mobileNumber)
      await this.checkUniqueness(
        "mobileNumber",
        updateFields.mobileNumber,
        doctorId
      );
    if (updateFields.persId)
      await this.checkUniqueness("persId", updateFields.persId, doctorId);

    if (updateFields.password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(updateFields.password, salt);
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error("Only superadmins can suspend doctors");
    }

    const currentDoctorData = doctorDoc.data(); // Get current doctor data

    if (updateFields.patients) {
      let oldPatients = currentDoctorData.patients || [];
      let newPatients = updateFields.patients || oldPatients; // If no update to patients array, keep the old list

      if (!Array.isArray(newPatients)) {
        throw new Error("updateDoctor: patients field must be an array");
      }

      // Identify removed and added patients
      const removedPatients = oldPatients.filter(
      (patientId) => !newPatients.includes(patientId)
    );
      const addedPatients = newPatients.filter(
      (patientId) => !oldPatients.includes(patientId)
    );

      // Update removed patients (set their doctor attribute to an empty string or null)
      await Promise.all(
        removedPatients.map(async (patientId) => {
          await PatientService.updatePatient(
          patientId,
          { doctor: null },
          { role: "superadmin" }
        );
        })
      );

      // Update added patients (set their doctor attribute to the new doctor's ID)
      await Promise.all(
        addedPatients.map(async (patientId) => {
          await PatientService.updatePatient(
          patientId,
          { doctor: doctorId },
          { role: "superadmin" }
        );
        })
      );
    }

    if (updateFields.schedule) {
      if (
        !Array.isArray(updateFields.schedule) ||
        !updateFields.schedule.every(
          (s) =>
            typeof s.day === "string" &&
            typeof s.start === "string" &&
            typeof s.end === "string"
        )
      ) {
        throw new Error("updateDoctor: schedule must be an array of { day, start, end }");
      }
    }    

    // 🔹 Remove any undefined values before updating Firestore
    Object.keys(updateFields).forEach((key) => {
      if (updateFields[key] === undefined) {
          delete updateFields[key];  // ✅ Removes undefined fields
      }
    });

    await doctorRef.update(updateFields);
    return { message: "Doctor updated successfully" };
  }

  /**
   * Delete a doctor
   */
  static async deleteDoctor(doctorId) {
    const doctorRef = db.collection("doctors").doc(doctorId);
    const doctorDoc = await doctorRef.get();

    if (!doctorDoc.exists) throw new Error("Doctor not found");

    // Start Firestore batch operation
    const batch = db.batch();

    const doctorData = doctorDoc.data();
    const patients = doctorData?.patients || []; // Ensure the patients array exists

    // 🔹 Set `doctor` field to null for all patients in the doctor's list
    const updatePatientDoctorField = async () => {
      if (patients.length > 0) {
          const patientRefs = patients.map(patientId => db.collection("patients").doc(patientId));
          patientRefs.forEach(patientRef => {
              batch.update(patientRef, { doctor: null });
          });
      }
    };

    await updatePatientDoctorField();

    // 🔹 Delete all appointments and tests where "doctor" field matches doctorId
    const deleteAppointmentsAndTests = async (collection) => {
      const snapshot = await db
        .collection(collection)
        .where("doctor", "==", doctorId)
        .get();
      snapshot.forEach((doc) => batch.delete(doc.ref));
    };

    await deleteAppointmentsAndTests("appointments");
    await deleteAppointmentsAndTests("tests");

    // 🔹 Delete the doctor itself
    batch.delete(doctorRef);

    // Commit batch
    await batch.commit();

    return { message: "Doctor deleted successfully" };
  }
}

module.exports = DoctorService;
