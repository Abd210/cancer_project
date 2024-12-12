const TestService = require("../../Services/testService");

class TestController {
  static async getTestReview(req, res) {
    try {
      const { _id, user, role } = req.headers;
      if (!_id) {
        return res.status(400).json({
          error: "TestController- Get Test Review: Missing test id",
        });
      }

      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      const test_review = await TestService.getTestReview({
        test_id: _id,
        role,
      });
      res.status(200).json(test_review);
    } catch (fetchTestReviewError) {
      res.status(500).json({ error: fetchTestReviewError.message });
    }
  }

  static async getTestResults(req, res) {
    try {
      const { _id, user, role } = req.headers;
      if (!_id) {
        return res.status(400).json({
          error: "TestController- Get Test Review: Missing test id",
        });
      }

      if (user.role === "patient" || user.role === "doctor") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      const test_results = await TestService.getTestResults({
        test_id: _id,
        role,
      });
      res.status(200).json(test_results);
    } catch (fetchTestReviewError) {
      res.status(500).json({ error: fetchTestReviewError.message });
    }
  }

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

      // Validate required fields
      if (!patient_id || !test_date || !purpose || !device_id) {
        return res.status(400).json({
          error: `Missing required fields: ${
            !patient_id ? "patient_id, " : ""
          }${!test_date ? "result_date, " : ""}${
            !purpose ? "purpose" : ""
          }`.slice(0, -2),
        });
      }

      // Check if the user is authorized to create the test
      if (user.role === "doctor") {
        if (doctor_id !== user._id) {
          return res.status(403).json({
            error: "TestController- Create Test: Unauthorized",
          });
        }
      }

      if (status && !["pending", "reviewed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "TestController-Create: Invalid Status" });
      }

      if (new Date(result_date) < new Date()) {
        return res.status(400).json({
          error: "TestController-Create: Invalid Result Date",
        });
      }
      // Call the TestService to create the test
      const test = await TestService.createTest({
        patient_id,
        doctor_id,
        device_id,
        result_date,
        purpose,
        status,
        review,
      });

      res.status(201).json(test);
    } catch (error) {
      res
        .status(500)
        .json({ error: `TestController-Create: ${error.message}` });
    }
  }
}

module.exports = TestController;
