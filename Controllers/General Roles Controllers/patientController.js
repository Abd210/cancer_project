const PatientService = require("../../Services/patientService");

class PatientController {
  static async getData(req, res) {
    try {
      const { _id, user, role } = req.headers;
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Data: Missing pers_id",
        });
      }

      if (user.role === "patient") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Data: Unauthorized",
          });
        }
      }

      const public_data = await PatientService.findPatient(_id);
      res.status(200).json(public_data);
    } catch (fetchPatientDataError) {
      res.status(500).json({ error: fetchPatientDataError.message });
    }
  }

  static async getDiagnosis(req, res) {
    try {
      const { _id, user, role } = req.headers;
      console.log(req.headers);
      if (!_id) {
        return res.status(400).json({
          error: "PatientController- Get Patient Diagnosis: Missing pers_id",
        });
      }

      if (user.role === "patient") {
        if (_id !== user._id) {
          return res.status(403).json({
            error: "PatientController- Get Patient Diagnosis: Unauthorized",
          });
        }
      }

      const public_data = await PatientService.findPatient(_id);
      res.status(200).json(public_data.diagnosis);
    } catch (fetchPatientDiagnosisError) {
      res.status(500).json({ error: fetchPatientDiagnosisError.message });
    }
  }
}

module.exports = PatientController;
