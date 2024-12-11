const Doctor = require("../Models/Doctor");
const Patient = require("../Models/Patient");
const Appointment = require("../models/Appointment");
const mongoose = require("mongoose");

class AppointmentService {
  static async getUpcomingAppointments({ user_id, role }) {
    if (!mongoose.isValidObjectId(user_id)) {
      throw new Error(
        "appointmentService-get appointment history:Invalid user_id"
      );
    }

    const query =
      role === "doctor" ? { doctor: user_id } : { patient: user_id };
    const appointments = await Appointment.find({
      ...query,
      appointment_date: { $gte: new Date() }, // Only future appointments
      status: "scheduled",
    })
      .populate("patient", "name email")
      .populate("doctor", "name email")
      .sort("appointment_date");

    return appointments;
  }

  static async getAppointmentHistory({ user_id, role }) {
    if (!mongoose.isValidObjectId(user_id)) {
      throw new Error(
        "appointmentService-get appointment history:Invalid user_id"
      );
    }

    const query =
      role === "doctor" ? { doctor: user_id } : { patient: user_id };
    const appointments = await Appointment.find({
      ...query,
      appointment_date: { $lt: new Date() }, // Only past appointments
    })
      .populate("patient", "name email")
      .populate("doctor", "name email")
      .sort("-appointment_date");

    return appointments;
  }

  static async cancelAppointment(appointment_id) {
    const appointmentExists = await AppointmentService.findAppointment(
      appointment_id
    );
    if (!appointmentExists) {
      throw new Error(
        "appointmentService-cancel appointment: Appointment not found"
      );
    }

    const appointment = await Appointment.findByIdAndUpdate(
      appointment_id,
      { status: "cancelled" },
      { new: true }
    );

    if (!appointment) {
      throw new Error(
        "appointmentService-cancel appointment: Appointment not found"
      );
    }

    return appointment;
  }

  static async createAppointment({
    patient_id,
    doctor_id,
    appointment_date,
    purpose,
    status = "scheduled",
  }) {
    try {
      const appointment = new Appointment({
        patient: patient_id,
        doctor: doctor_id,
        appointment_date,
        purpose,
        status,
      });

      const validationError = appointment.validateSync();
      if (validationError) {
        throw new Error(
          `appointmentService-create appointment: ${validationError.message}`
        );
      }

      appointment.save();
    } catch (saveAppointmentError) {
      throw new Error(
        `appointmentService-create appointment: ${saveAppointmentError.message}`
      );
    }
  }

  static async findAppointment(appointment_id) {
    if (!mongoose.isValidObjectId(appointment_id)) {
      throw new Error(
        "appointmentService-appointment exists: Invalid appointment_id"
      );
    }

    return await Appointment.findOne({ _id: appointment_id });
  }
}

module.exports = AppointmentService;
