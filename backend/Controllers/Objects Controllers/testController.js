const TestService = require("../../Services/testService");
const SuspendController = require("../suspendController");

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
   * Retrieves the details of a specific test for the authenticated user.
   * Verifies user role and permissions before fetching the test.
   *
   * @param {Object} req - The HTTP request object containing the test ID and user details in the headers.
   * @param {Object} res - The HTTP response object used to send back the test details or errors.
   *
   * @returns {Object} Returns a JSON response with the test details or an error message.
   */
  static async getTestDetails(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { user, filterbyid, filterbyrole, suspendfilter } = req.headers;

      // Validate filterByRole if provided
      if (
        filterbyrole &&
        !["doctor", "patient"].includes(filterbyrole) &&
        user.role === "superadmin"
      ) {
        return res.status(400).json({
          error:
            "AppointmentController- Get Appointment History: Invalid filterByRole",
        });
      }

      // Fetch the test data from the TestService
      const test = await TestService.fetchTests({
        role: user.role,
        user_id: user.id,
        filterById: filterbyid || null, // Use filterById from query parameters, default to null
        filterByRole: filterbyrole || null, // Use filterByRole from query parameters, default to null
      });

      const filtered_data = await SuspendController.filterData(
        test,
        user.role,
        suspendfilter
      );
      // Return the entire test object in the response
      res.status(200).json(filtered_data);
    } catch (fetchTestDetailsError) {
      console.error("Error in getTestDetails:", fetchTestDetailsError);
      res.status(500).json({ error: fetchTestDetailsError.message });
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
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const {
        patient,
        doctor,
        device,
        resultDate,
        purpose,
        review,
        status,
        suspended,
      } = req.body;

      const { user } = req.headers;

      // Validate required fields in the request body
      if (!patient || !doctor || !purpose) {
        return res.status(400).json({
          error: `Missing required fields: ${!patient ? "patient, " : ""}${
            !doctor ? "doctor, " : ""
          }${!purpose ? "purpose" : ""}`.slice(0, -2),
        });
      }

      // Ensure the status is either 'pending' or 'reviewed' if provided
      if (status && !["pending", "reviewed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "TestController-Create: Invalid Status" });
      }

      if (status === "reviewed" && !review) {
        return res.status(400).json({
          error:
            "TestController-Create: Review is required when status is reviewed",
        });
      }

      if (review && !status) {
        req.body.status = "reviewed";
      }

      // Create the test record using the TestService
      const test = await TestService.createTest({
        patient,
        doctor,
        device,
        resultDate,
        purpose,
        status,
        review,
        suspended,
      });

      // Return the created test record in the response
      res.status(201).json(test);
    } catch (error) {
      console.error("Error in createTest:", error);
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * Deletes a specific test by its ID if the authenticated user has the necessary permissions.
   * Validates the test ID and ensures the test exists before deletion.
   *
   * @param {Object} req - The HTTP request object containing the test ID and user details in the headers.
   * @param {Object} res - The HTTP response object used to send back the result of the deletion or errors.
   *
   * @returns {Object} A JSON response with a success message or an error message.
   */
  static async deleteTest(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { testid } = req.headers;

      // Validate if the test ID is provided in the request
      if (!testid) {
        return res.status(400).json({
          error: "TestController-deleteTest: Missing test ID",
        });
      }

      // Call the TestService to delete the test
      const result = await TestService.deleteTest(testid);

      // Check if the service returned an error
      if (result.error) {
        return res.status(400).json({ error: result.error });
      }

      // Respond with success
      return res.status(200).json({ message: "Test deleted successfully" });
    } catch (deleteTestError) {
      console.error("Error in deleteTest:", deleteTestError);
      res.status(500).json({
        error: `TestController-deleteTest: ${deleteTestError.message}`,
      });
    }
  }

  static async updateTestData(req, res) {
    console.log(`[${req.method}] ${req.originalUrl}`);
    try {
      const { testid, user } = req.headers;

      // Destructure the fields to update from the request body
      const updateFields = req.body;

      // Validate if testId is provided
      if (!testid) {
        return res.status(400).json({
          error: "TestController-update test: Missing testId",
        });
      }

      // Check if the user is authorized to update the test data when its suspended
      if (user.role !== "superadmin") {
        const test = await TestService.findTest(testid);
        if (test.suspended) {
          return res.status(403).json({
            error: "TestController-update test: Unauthorized",
          });
        }
      }

      // Validate if updateFields are provided
      if (!updateFields || Object.keys(updateFields).length === 0) {
        return res.status(400).json({
          error: "TestController-update test: No fields provided to update",
        });
      }

      // Call the TestService to perform the update
      const updatedTest = await TestService.updateTest(
        testid,
        updateFields,
        user
      );

      // Check if the patient was found and updated
      if (!updatedTest) {
        return res.status(404).json({
          error: "TestController- Update Test Data: Test not found",
        });
      }

      // Respond with the updated test data
      return res.status(200).json(updatedTest);
    } catch (updateTestError) {
      console.error("Error in updateTestData:", updateTestError);
      res.status(500).json({
        error: `TestController-update test: ${updateTestError.message}`,
      });
    }
  }
}

module.exports = TestController;
