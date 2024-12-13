const TestService = require("../../Services/testService");

/**
 * TestController handles the operations related to managing tests in the system.
 * It includes functionalities for creating new tests, fetching test results and reviews,
 * and ensuring that the user has the necessary permissions to access or modify test data.
 *
 * Each method ensures that only authorized users (patients or doctors) can access their respective test details,
 * and validates all required fields and statuses before proceeding with actions like test creation or retrieval.
 */
class TestController {

  /**
   * Retrieves the review of a specific test for the authenticated user.
   * Verifies user role and permissions before fetching the review.
   * 
   * @param {Object} req - The HTTP request object containing the test ID and user details in the headers.
   * @param {Object} res - The HTTP response object used to send back the test review or errors.
   * 
   * @returns {Object} Returns a JSON response with the test review or an error message.
   */
  static async getTestReview(req, res) {
    try {
      const { _id, user, role } = req.headers;

      // Check if test ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error: "TestController- Get Test Review: Missing test id",
        });
      }

      // Fetch the test data from the TestService
      const test = await TestService.findTest(_id);

      // Check if the user is a patient and ensure they are authorized to access the test review
      if (user.role === "patient") {
        if (test.patient._id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      // Return the test review in the response
      res.status(200).json(test.review);
    } catch (fetchTestReviewError) {
      // Handle errors in fetching the test review
      res.status(500).json({ error: fetchTestReviewError.message });
    }
  }

   /**
   * Retrieves the results of a specific test for the authenticated user.
   * Verifies user role and permissions before fetching the results.
   * 
   * @param {Object} req - The HTTP request object containing the test ID and user details in the headers.
   * @param {Object} res - The HTTP response object used to send back the test results or errors.
   * 
   * @returns {Object} Returns a JSON response with the test results or an error message.
   */

  static async getTestResults(req, res) {
    try {
      const { _id, user, role } = req.headers;

      // Check if test ID is provided in the request
      if (!_id) {
        return res.status(400).json({
          error: "TestController- Get Test Review: Missing test id",
        });
      }

      // Fetch the test data from the TestService
      const test = await TestService.findTest(_id);

      // Check if the user is a patient and ensure they are authorized to access the test results
      if (user.role === "patient") {
        if (test.patient._id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      // Return the test results in the response
      res.status(200).json(test.results);
    } catch (fetchTestReviewError) {
      // Handle errors in fetching the test results
      res.status(500).json({ error: fetchTestReviewError.message });
    }
  }

  /**
   * Creates a new test record in the system.
   * Validates required fields and ensures the status is valid before creating the test.
   * 
   * @param {Object} req - The HTTP request object containing the test details in the body.
   * @param {Object} res - The HTTP response object used to send back the created test or errors.
   * 
   * @returns {Object} Returns a JSON response with the created test or an error message.
   */
  static async createTest(req, res) {
    try {
      const {
        patient_id,
        doctor_id,
        device_id,
        result_date,
        purpose,
        review,
        status,
      } = req.body;

      const { user } = req.headers;

      // Validate required fields in the request body
      if (!patient_id || !doctor_id || !purpose) {
        return res.status(400).json({
          error: `Missing required fields: ${
            !patient_id ? "patient_id, " : ""
          }${!doctor_id ? "doctor_id, " : ""}${
            !purpose ? "purpose" : ""
          }`.slice(0, -2),
        });
      }

      // Ensure the status is either 'pending' or 'reviewed' if provided
      if (status && !["pending", "reviewed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "TestController-Create: Invalid Status" });
      }

      // Create the test record using the TestService
      const test = await TestService.createTest({
        patient_id,
        doctor_id,
        device_id,
        result_date,
        purpose,
        status,
        review,
      });

      // Return the created test record in the response
      res.status(201).json(test);
    } catch (error) {
      // Handle errors in creating the test
      res
        .status(500)
        .json({ error: `TestController-Create: ${error.message}` });
    }
  }
}

module.exports = TestController;
