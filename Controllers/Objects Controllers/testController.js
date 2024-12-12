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

      const test = await TestService.findTest(_id);

      if (user.role === "patient") {
        if (test.patient._id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      res.status(200).json(test.review);
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

      const test = await TestService.findTest(_id);

      if (user.role === "patient") {
        if (test.patient._id !== user._id) {
          return res.status(403).json({
            error: "TestController- Get Test Review: Unauthorized",
          });
        }
      }

      res.status(200).json(test.results);
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
      if (!patient_id || !doctor_id || !purpose) {
        return res.status(400).json({
          error: `Missing required fields: ${
            !patient_id ? "patient_id, " : ""
          }${!doctor_id ? "doctor_id, " : ""}${
            !purpose ? "purpose" : ""
          }`.slice(0, -2),
        });
      }

      if (status && !["pending", "reviewed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "TestController-Create: Invalid Status" });
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
