// services/patientService.js
const User = require('../models/User');
const Diagnosis = require('../Models/Diagnosis');
const Appointment = require('../Models/Appointment');
const Test = require('../Models/Test');
const Ticket = require('../Models/Ticket');
const mongoose = require('mongoose');

class PatientService {
    static async getPatientData({ patient_id }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }
        const patient = await User.findOne({ _id: patient_id, role: 'patient' });
        if (!patient) throw new Error('Patient not found');

        return {
            patient_id: patient._id,
            name: patient.name,
            dateOfBirth: patient.dateOfBirth,
            medicalHistory: patient.medicalHistory || []
        };
    }

    static async getDoctorPublicData({ doctor_id }) {
        if (!mongoose.isValidObjectId(doctor_id)) {
            throw new Error('Invalid doctor_id');
        }
        const doctor = await User.findOne({ _id: doctor_id, role: 'doctor' });
        if (!doctor) throw new Error('Doctor not found');

        return {
            doctor_id: doctor._id,
            specialization: doctor.specialization,
            rating: doctor.rating
        };
    }

    static async getDiagnosis({ patient_id }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }
        const diagnoses = await Diagnosis.find({ patient: patient_id }).populate('updatedBy', 'username specialization');
        return diagnoses.map(d => ({
            diagnosis_id: d._id,
            details: d.diagnosisDetails,
            updatedBy: d.updatedBy ? d.updatedBy.username : null,
            updatedAt: d.updatedAt
        }));
    }

    static async getAppointmentHistory({ patient_id }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }
        const now = new Date();
        const pastAppointments = await Appointment.find({ patient: patient_id, appointment_date: { $lt: now } })
            .populate('doctor', 'username specialization')
            .sort({ appointment_date: -1 });

        return pastAppointments.map(a => ({
            appointment_id: a._id,
            doctor: a.doctor ? a.doctor.username : null,
            date: a.appointment_date,
            purpose: a.purpose,
            status: a.status
        }));
    }

    static async getUpcomingAppointments({ patient_id }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }
        const now = new Date();
        const upcoming = await Appointment.find({ patient: patient_id, appointment_date: { $gte: now }, status: 'scheduled' })
            .populate('doctor', 'username specialization')
            .sort({ appointment_date: 1 });

        return upcoming.map(a => ({
            appointment_id: a._id,
            doctor: a.doctor ? a.doctor.username : null,
            date: a.appointment_date,
            purpose: a.purpose,
            status: a.status
        }));
    }

    static async cancelAppointment({ patient_id, appointment_id }) {
        if (!mongoose.isValidObjectId(patient_id) || !mongoose.isValidObjectId(appointment_id)) {
            throw new Error('Invalid patient_id or appointment_id');
        }

        const appointment = await Appointment.findOne({ _id: appointment_id, patient: patient_id });
        if (!appointment) throw new Error('Appointment not found or not yours to cancel');

        if (appointment.status !== 'scheduled') {
            throw new Error('Cannot cancel an appointment that is not scheduled');
        }

        appointment.status = 'canceled';
        await appointment.save();

        return { message: 'Appointment canceled successfully', appointment_id: appointment_id };
    }

    static async createAppointment({ patient_id, doctor_id, appointment_date, purpose }) {
        if (!mongoose.isValidObjectId(patient_id) || !mongoose.isValidObjectId(doctor_id)) {
            throw new Error('Invalid patient_id or doctor_id');
        }

        const doctor = await User.findOne({ _id: doctor_id, role: 'doctor' });
        if (!doctor) throw new Error('Doctor not found');

        const dateObj = new Date(appointment_date);
        if (isNaN(dateObj)) throw new Error('Invalid appointment_date');

        const newAppointment = new Appointment({
            patient: patient_id,
            doctor: doctor_id,
            appointment_date: dateObj,
            purpose
        });
        await newAppointment.save();

        return { message: 'Appointment created successfully', appointment_id: newAppointment._id };
    }

    static async getTestResults({ patient_id }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }

        const tests = await Test.find({ patient: patient_id });
        return tests.map(t => ({
            test_id: t._id,
            testResults: t.testResults,
            interpretations: t.interpretations.map(i => ({
                doctor_id: i.doctor,
                interpretation: i.interpretation,
                createdAt: i.createdAt
            }))
        }));
    }

    static async getTestInterpretation({ patient_id, doctor_id, test_id }) {
        if (!mongoose.isValidObjectId(patient_id) || !mongoose.isValidObjectId(doctor_id) || !mongoose.isValidObjectId(test_id)) {
            throw new Error('Invalid IDs provided');
        }

        const test = await Test.findOne({ _id: test_id, patient: patient_id });
        if (!test) throw new Error('Test not found');

        // Filter interpretations by that doctor
        const interpretation = test.interpretations.find(i => i.doctor.toString() === doctor_id);
        if (!interpretation) {
            return { message: 'No interpretation from this doctor found for this test' };
        }

        return {
            test_id: test_id,
            doctor_id: doctor_id,
            interpretation: interpretation.interpretation,
            createdAt: interpretation.createdAt
        };
    }

    static async requestTestInterpretation({ patient_id, doctor_id, test_id }) {
        if (!mongoose.isValidObjectId(patient_id) || !mongoose.isValidObjectId(doctor_id) || !mongoose.isValidObjectId(test_id)) {
            throw new Error('Invalid IDs');
        }

        // Simulate a request by just returning a message. 
        // In a real scenario, you might create a "TestInterpretationRequest" model or send a notification to the doctor.
        const test = await Test.findOne({ _id: test_id, patient: patient_id });
        if (!test) throw new Error('Test not found');

        // For now, just return a message that interpretation was requested.
        return { message: 'Interpretation request submitted to doctor', test_id, doctor_id };
    }

    static async createTicket({ patient_id, account_type, issue }) {
        if (!mongoose.isValidObjectId(patient_id)) {
            throw new Error('Invalid patient_id');
        }

        const newTicket = new Ticket({
            patient: patient_id,
            account_type,
            issue
        });
        await newTicket.save();

        return { message: 'Ticket created successfully', ticket_id: newTicket._id };
    }
}

module.exports = PatientService;
