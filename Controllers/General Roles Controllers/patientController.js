// controllers/patientController.js
const patientService = require("../../Services/patientService");

class PatientController {
  static async getPatientData(req, res) {
    try {
      const { patient_id } = req.query;
      const result = await patientService.getPatientData({ patient_id });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getDoctorPublicData(req, res) {
    try {
      const { doctor_id } = req.query;
      const result = await patientService.getDoctorPublicData({ doctor_id });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getDiagnosis(req, res) {
    try {
      const { patient_id } = req.query;
      const result = await patientService.getDiagnosis({ patient_id });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getAppointmentHistory(req, res) {
    try {
      const { patient_id } = req.query;
      const result = await patientService.getAppointmentHistory({ patient_id });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getUpcomingAppointments(req, res) {
    try {
      const { patient_id } = req.query;
      const result = await patientService.getUpcomingAppointments({
        patient_id,
      });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async cancelAppointment(req, res) {
    try {
      const { patient_id, appointment_id } = req.body;
      const result = await patientService.cancelAppointment({
        patient_id,
        appointment_id,
      });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async createAppointment(req, res) {
    try {
      const { patient_id, doctor_id, appointment_date, purpose } = req.body;
      const result = await patientService.createAppointment({
        patient_id,
        doctor_id,
        appointment_date,
        purpose,
      });
      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getTestResults(req, res) {
    try {
      const { patient_id } = req.query;
      const result = await patientService.getTestResults({ patient_id });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async getTestInterpretation(req, res) {
    try {
      const { patient_id, doctor_id, test_id } = req.query;
      const result = await patientService.getTestInterpretation({
        patient_id,
        doctor_id,
        test_id,
      });
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async requestTestInterpretation(req, res) {
    try {
      const { patient_id, doctor_id, test_id } = req.body;
      const result = await patientService.requestTestInterpretation({
        patient_id,
        doctor_id,
        test_id,
      });
      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }

  static async createTicket(req, res) {
    try {
      const { patient_id, account_type, issue } = req.body;
      const result = await patientService.createTicket({
        patient_id,
        account_type,
        issue,
      });
      res.status(201).json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = PatientController;
