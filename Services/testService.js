const Doctor = require("../Models/Doctor");
const Patient = require("../Models/Patient");
const Test = require("../Models/Test");
const mongoose = require("mongoose");

class TestService {
  static async getTestReview({ user_id, role }) {
    try {
      if (!mongoose.isValidObjectId(user_id)) {
        throw new Error("testService-get test review: Invalid user_id");
      }

      const query =
        role === "doctor" ? { doctor: user_id } : { patient: user_id };
      const tests = await Test.find({ ...query, status: "reviewed" })
        .populate("patient", "name email")
        .populate("doctor", "name email")
        .populate("device", "name")
        .sort("result_date");

      return tests;
    } catch (fetchTestReviewError) {
      throw new Error(
        `testService-get test review: ${fetchTestReviewError.message}`
      );
    }
  }

  static async getTestResults({ user_id, role }) {
    if (!mongoose.isValidObjectId(user_id)) {
      throw new Error("testService-get test results: Invalid user_id");
    }

    const query =
      role === "doctor" ? { doctor: user_id } : { patient: user_id };
    const tests = await Test.find({ ...query })
      .populate("patient", "name email")
      .populate("doctor", "name email")
      .populate("device", "name")
      .sort("result_date");

    return tests;
  }
  static async createTest({
    patient_id,
    doctor_id,
    device_id,
    result_date,
    purpose,
    status = "scheduled",
    review,
  }) {
    try {
      const test = new Test({
        patient: patient_id,
        doctor: doctor_id,
        device: device_id,
        result_date,
        purpose,
        status,
        review,
      });

      const validationError = test.validateSync();
      if (validationError) {
        throw new Error(`testService-create test: ${validationError.message}`);
      }

      test.save();
    } catch (saveAppointmentError) {
      throw new Error(
        `testService-create test: ${saveAppointmentError.message}`
      );
    }
  }

  static async findTest(test_id) {
    if (!mongoose.isValidObjectId(test_id)) {
      throw new Error("testService-find test: Invalid test id");
    }

    return await Test.findOne({ _id: test_id });
  }
}

module.exports = TestService;
