const TestService = require("../../Services/testService");

class TestController {
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

      if (status && !["pending", "reviewed"].includes(status)) {
        return res
          .status(400)
          .json({ error: "TestController-Create: Invalid Status" });
      }

      if (test_date < new Date()) {
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
