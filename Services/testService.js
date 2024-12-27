const Doctor = require("../Models/Doctor");
const Patient = require("../Models/Patient");
const Test = require("../Models/Test");
const mongoose = require("mongoose");

class TestService {
  // static async getTestReview({ test_id, role }) {
  //   try {
  //     if (!mongoose.isValidObjectId(test_id)) {
  //       throw new Error("testService-get test review: Invalid test id");
  //     }

  //     const query =
  //       role === "doctor" ? { doctor: user_id } : { patient: user_id };
  //     const test = await this.findTest(test_id);

  //     return test.review;
  //   } catch (fetchTestReviewError) {
  //     throw new Error(
  //       `testService-get test review: ${fetchTestReviewError.message}`
  //     );
  //   }
  // }

  // static async getTestResults({ user_id, role }) {
  //   try {
  //     if (!mongoose.isValidObjectId(test_id)) {
  //       throw new Error("testService-get test review: Invalid test id");
  //     }

  //     const query =
  //       role === "doctor" ? { doctor: user_id } : { patient: user_id };
  //     const test = await this.findTest(test_id);

  //     return test.results;
  //   } catch (fetchTestReviewError) {
  //     throw new Error(
  //       `testService-get test review: ${fetchTestReviewError.message}`
  //     );
  //   }
  // }

  static async fetchTests({ user_id, role }) {
    try {
      if (!mongoose.isValidObjectId(user_id)) {
        throw new Error("testService-fetchTests: Invalid user ID");
      }
  
      // Build the query based on the user's role
      const query = role === "doctor" ? { doctor: user_id } : { patient: user_id };
  
      // Fetch tests with the query, apply population and sorting if needed
    const tests = await Test.find({
      ...query,
      status: { $ne: "completed" }, // Example: Exclude completed tests
    })
      .populate("patient", "name email") // Populate patient details
      .populate("doctor", "name email") // Populate doctor details
      .sort("status"); // Example: Sort by status

    // Return the tests or an empty array if none found
    return tests || [];
    } catch (error) {
      // Handle errors
      console.error("testService-fetchTests Error: ", error.message);
      throw new Error(`testService-fetchTests: ${error.message}`);
    }
  }
  

  static async createTest({
    patient_id,
    doctor_id,
    device_id,
    result_date,
    purpose,
    status = "in progress",
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
      return { message: "Test created successfully", test };
    } catch (saveAppointmentError) {
      throw new Error(
        `testService-create test: ${saveAppointmentError.message}`
      );
    }
  }

  static async findTest(test_id) {
    try {
      if (!mongoose.isValidObjectId(test_id)) {
        throw new Error("testService-find test: Invalid test id");
      }

      return await Test.findOne({ _id: test_id });
    } catch (findTestError) {
      throw new Error(`testService-find test: ${findTestError.message}`);
    }
  }
}

module.exports = TestService;
