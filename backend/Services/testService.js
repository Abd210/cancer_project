const admin = require("firebase-admin");
const db = admin.firestore();
const DoctorService = require("./DoctorService");
const PatientService = require("./PatientService");

class TestService {
  /**
   * Fetch tests based on role (doctor, patient, superadmin)
   */

  /**
   * Check if a given patient ID or doctor ID is valid
   */
  static async checkEntityExists(entityRole, entityId) {
    if (entityRole === "doctor") {
      const doctor = await DoctorService.getDoctorData(entityId);
      return !!doctor;
    } else if (entityRole === "patient") {
      const patient = await PatientService.getPatientData(entityId);
      return !!patient;
    } else {
      throw new Error("testService-isValidUser: Invalid role");
    }
  }

  static async fetchTests({ user_id, role, filterById, filterByRole }) {
    let query;

    if (role === "doctor") {
      query = db.collection("tests").where("doctor", "==", user_id);
    } else if (role === "patient") {
      query = db.collection("tests").where("patient", "==", user_id);
    } else if (role === "superadmin") {
      if (filterById && filterByRole) {
        if (filterByRole === "patient") {
          query = db.collection("tests").where("patient", "==", filterById);
        } else {
          query = db.collection("tests").where("doctor", "==", filterById);
        }
        // query = db.collection("tests").where(filterByRole, "==", filterById);
      } else {
        query = db.collection("tests"); // Fetch all tests
      }
    } else {
      throw new Error("testService-fetchTests: Invalid role");
    }

    const snapshot = await query.get();
    if (snapshot.empty) return [];

    let tests = [];
    for (let doc of snapshot.docs) {
      let testData = doc.data();

      // Fetch related data
      const doctor = await DoctorService.getDoctorData(testData.doctor);
      const patient = await PatientService.getPatientData(testData.patient);

      tests.push({
        id: doc.id, // Firestore-generated ID
        ...testData,
        doctor: doctor || null,
        patient: patient || null,
      });
    }

    return tests;
  }

  /**
   * Create a new test record
   */
  static async createTest({
    patient,
    doctor,
    device = null, // Have not implemented devices yet
    resultDate,
    purpose,
    status = "in progress",
    review,
    suspended = false,
  }) {
    const doctorDoc = await DoctorService.getDoctorData(doctor);
    const patientDoc = await PatientService.getPatientData(patient);

    if (
      !(await this.checkEntityExists("patient", patient)) ||
      !(await this.checkEntityExists("doctor", doctor))
    ) {
      throw new Error("testService-createTest: Invalid doctor or patient ID");
    }

    const newTestRef = db.collection("tests").doc();
    const testData = {
      doctor,
      patient,
      device,
      resultDate,
      purpose,
      status,
      review,
      createdAt: new Date(),
      suspended,
    };

    await newTestRef.set(testData);
    return {
      message: "Test created successfully",
      test: { id: newTestRef.id, ...testData },
    };
  }

  /**
   * Find a single test by ID
   */
  static async findTest(testId) {
    const testDoc = await db.collection("tests").doc(testId).get();
    if (!testDoc.exists) {
      throw new Error("testService-findTest: Test not found");
    }

    let testData = testDoc.data();

    // Fetch related doctor and patient details
    testData.doctor = await DoctorService.getDoctorData(testData.doctor);
    testData.patient = await PatientService.getPatientData(testData.patient);

    return { id: testDoc.id, ...testData };
  }

  /**
   * Delete a test by ID
   */
  static async deleteTest(testId) {
    const testDoc = await db.collection("tests").doc(testId).get();
    if (!testDoc.exists) {
      throw new Error("testService-deleteTest: Test not found");
    }

    await db.collection("tests").doc(testId).delete();
    return;
  }

  /**
   * Update a test record
   */
  static async updateTest(testId, updateFields, user) {
    const testDoc = await db.collection("tests").doc(testId).get();
    if (!testDoc.exists) {
      throw new Error("testService-updateTest: Test not found");
    }

    // Prevent changing the Firestore document ID
    if (updateFields.id) {
      throw new Error(
        "testService-updateTest: Changing the 'id' field is not allowed"
      );
    }

    // Check if the doctor ID is valid
    if (updateFields.doctor) {
      const doctorDoc = await DoctorService.getDoctorData(updateFields.doctor);
      if (!doctorDoc) {
        throw new Error("testService-updateTest: Invalid doctor ID");
      }
    }

    // Check if the patient ID is valid
    if (updateFields.patient) {
      const patientDoc = await PatientService.getPatientData(
        updateFields.patient
      );
      if (!patientDoc) {
        throw new Error("testService-updateTest: Invalid patient ID");
      }
    }

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error(
        "testService-updateTest: Only superadmins can suspend tests"
      );
    }

    await db.collection("tests").doc(testId).update(updateFields);
    const updatedTest = await db.collection("tests").doc(testId).get();
    return { id: updatedTest.id, ...updatedTest.data() };
  }
}

module.exports = TestService;
