const Doctor = require("../Models/Doctor");
const Patient = require("../Models/Patient");
const Test = require("../Models/Test");
const mongoose = require("mongoose");

class TestService {

  static async fetchTests({ user_id, role }) {
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
  }
  

  static async createTest({patient_id, doctor_id, device_id, result_date, purpose, status = "in progress", review,}) {
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
  }

  static async findTest(test_id) {
    if (!mongoose.isValidObjectId(test_id)) {
      throw new Error("testService-find test: Invalid test id");
    }

    return await Test.findOne({ _id: test_id });
  }

  static async deleteTest(test_id) {
    try {
      // Validate if the provided test ID is a valid MongoDB ObjectId
      if (!mongoose.isValidObjectId(test_id)) {
        throw new Error("testService-deleteTest: Invalid test ID");
      }
  
      // Find and delete the test by its ID
      const deletedTest = await Test.findByIdAndDelete(test_id);
  
      // If the test is not found, throw an error
      if (!deletedTest) {
        throw new Error("testService-deleteTest: Test not found");
      }
  
      // Return a success message along with the deleted test data
      return {
        message: "Test successfully deleted",
        deletedTest, // Optional: Include the deleted test data in the response
      };
    } catch (error) {
      // Catch and rethrow errors
      return { error: error.message };
    }
  }

  static async updateTest(testId, updateFields) {
    // Validate the testId as a valid MongoDB ObjectId
    if (!mongoose.isValidObjectId(testId)) {
      throw new Error("testService-update test: Invalid testId");
    }

    // Prevent updating the _id field
    if (updateFields._id) {
        throw new Error("testService-update test: Changing the '_id' field is not allowed");
    }

    // Perform the update
    const updatedTest = await Test.findByIdAndUpdate(
        testId,
        { $set: updateFields }, // Update only the provided fields
        { new: true, runValidators: true } // Return the updated document and run schema validators
    );

    if (!updatedTest) {
        throw new Error("testService-update test: Test not found");
    }

    return updatedTest;
  }
  
}

module.exports = TestService;
