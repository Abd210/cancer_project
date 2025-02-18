const admin = require("firebase-admin");
const db = admin.firestore();
const DoctorService = require("./DoctorService");
const PatientService = require("./PatientService");

class TestService {
  /**
   * Fetch tests based on role (doctor, patient, superadmin)
   */
  static async fetchTests({ user_id, role, filterById, filterByRole }) {
    let query;

    if (role === "doctor") {
      query = db.collection("tests").where("doctor_id", "==", user_id);
    } else if (role === "patient") {
      query = db.collection("tests").where("patient_id", "==", user_id);
    } else if (role === "superadmin") {
      if (filterById && filterByRole) {
        if (filterByRole === "patient") {
          query = db.collection("tests").where("patient_id", "==", filterById);
        } else {
          query = db.collection("tests").where("doctor_id", "==", filterById);
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
      const doctor = await DoctorService.getDoctorData(testData.doctor_id);
      const patient = await PatientService.getPatientData(testData.patient_id);

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
    patient_id,
    doctor_id,
    device_id = null, // Have not implemented devices yet
    result_date,
    purpose,
    status = "in progress",
    review,
    suspended = false,
  }) {
    console.log("doctor_id is ", doctor_id);
    const doctor = await DoctorService.getDoctorData(doctor_id);
    console.log("found");
    const patient = await PatientService.getPatientData(patient_id);

    if (!doctor || !patient) {
      throw new Error("testService-createTest: Invalid doctor or patient ID");
    }

    const newTestRef = db.collection("tests").doc();
    const testData = {
      doctor_id,
      patient_id,
      device_id,
      result_date,
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
    testData.doctor = await DoctorService.getDoctorData(testData.doctor_id);
    testData.patient = await PatientService.getPatientData(testData.patient_id);

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
    return { message: "Test successfully deleted" };
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

    if (updateFields.suspended && user.role !== "superadmin") {
      throw new Error(
        "testService-updateTest: Only superadmins can suspend tests"
      );
    }

    await db.collection("tests").doc(testId).update(updateFields);
    return { message: "Test updated successfully" };
  }
}

module.exports = TestService;
