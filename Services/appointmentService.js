const Doctor = require("../Models/Doctor");
const Patient = require("../Models/Patient");
const Appointment = require("../models/Appointment");
const mongoose = require("mongoose");

/**
 * AppointmentService provides functionality related to managing appointments.
 * It includes methods for creating, updating, deleting, and fetching appointments.
 * The service ensures that appointment times are valid, doctors and patients are available,
 * and appointments are properly linked to users.
 */
class AppointmentService {

  /**
   * Fetches upcoming appointments for a specific user based on their role (doctor or patient).
   * The function filters appointments that are scheduled and in the future, 
   * ensuring that only valid appointments are returned.
   *
   * @param {Object} params - The request parameters, including user_id and role.
   * @param {string} params.user_id - The unique identifier of the user.
   * @param {string} params.role - The role of the user (either "doctor" or "patient").
   * @returns {Array} - Returns an array of upcoming appointments for the user.
   * @throws {Error} - Throws an error if the user_id is invalid or if no appointments are found.
   */
  static async getUpcomingAppointments({ user_id, role }) {
    // Check if the provided user_id is valid
    if (!mongoose.isValidObjectId(user_id)) {
      throw new Error(
        "appointmentService-get appointment history:Invalid user_id"
      );
    }

    // Build the query based on the user's role
    const query =
      role === "doctor" ? { doctor: user_id } : { patient: user_id };

      // Fetch upcoming appointments, scheduled in the future
    const appointments = await Appointment.find({
      ...query,
      appointment_date: { $gte: new Date() }, // Only future appointments
      status: "scheduled", // Ensure the appointment is scheduled
    })
      .populate("patient", "name email") // Populate patient details
      .populate("doctor", "name email") // Populate doctor details
      .sort("appointment_date"); // Sort appointments by date

    return appointments;
  }

  /**
   * Fetches past appointments for a specific user based on their role (doctor or patient).
   * The function filters appointments that have already occurred.
   *
   * @param {Object} params - The request parameters, including user_id and role.
   * @param {string} params.user_id - The unique identifier of the user.
   * @param {string} params.role - The role of the user (either "doctor" or "patient").
   * @returns {Array} Returns an array of past appointments for the user.
   * @throws Throws an error if the user_id is invalid or if no appointments are found.
   */
  static async getAppointmentHistory({ user_id, role, filterById, filterByRole }) {
    // Validate the user_id for correctness
    if (!mongoose.isValidObjectId(user_id)) {
      throw new Error(
        "appointmentService-get appointment history:Invalid user_id"
      );
    }

    // Build the query based on the user's role
    let query;

    if (role === "doctor") {
      query = { doctor: user_id }; // Doctors can only see their own appointments
    } else if (role === "patient") {
      query = { patient: user_id }; // Patients can only see their own appointments
    } else if (role === "superadmin") {
      // Superadmin can retrieve all appointments or filter by a specific doctor or patient
      if (filterById && filterByRole) {
        // Validate filterById
        if (!mongoose.isValidObjectId(filterById)) {
          throw new Error(
            "appointmentService-get appointment history: Invalid filterById"
          );
        }

        // Adjust query based on filterByRole
        if (filterByRole === "doctor") {
          query = { doctor: filterById }; // Filter by specific doctor
        } else if (filterByRole === "patient") {
          query = { patient: filterById }; // Filter by specific patient
        } else {
          throw new Error(
            "appointmentService-get appointment history: Invalid filterByRole"
          );
        }
      } else {
        query = {}; // No filter, retrieve all appointments
      }
    } else {
      throw new Error(
        "appointmentService-get appointment history: Invalid role"
      );
    }

      // Fetch past appointments, appointments that are in the past
    const appointments = await Appointment.find({
      ...query,
      appointment_date: { $lt: new Date() }, // Only past appointments
    })
      .populate("patient", "name email") // Populate patient details
      .populate("doctor", "name email") // Populate doctor details
      .sort("-appointment_date"); // Sort appointments by date in descending order

    return appointments;
  }

  /**
   * Cancels an appointment by updating its status to 'cancelled'.
   * The function first checks if the appointment exists, and if so, updates its status.
   *
   * @param {string} appointment_id - The unique identifier of the appointment.
   * @returns {Object} Returns the updated appointment or an error message if the appointment cannot be found.
   * @throws Throws an error if the appointment does not exist or if the update fails.
   */
  static async cancelAppointment(appointment_id) {
    // Check if the appointment exists in the database
    const appointmentExists = await AppointmentService.findAppointment(
      appointment_id
    );
    if (!appointmentExists) {
      throw new Error(
        "appointmentService-cancel appointment: Appointment not found"
      );
    }

    // Update the status of the appointment to 'cancelled'
    const appointment = await Appointment.findByIdAndUpdate(
      appointment_id,
      { status: "cancelled" },
      { new: true }
    );

    // If the appointment update fails, return an error
    if (!appointment) {
      throw new Error(
        "appointmentService-cancel appointment: Appointment not found"
      );
    }

    return appointment;
  }

   /**
   * Creates a new appointment by saving the provided data in the database.
   * The function validates the appointment data and saves it if valid.
   *
   * @param {Object} appointmentData - The data required to create a new appointment.
   * @param {string} appointmentData.patient_id - The ID of the patient.
   * @param {string} appointmentData.doctor_id - The ID of the doctor.
   * @param {Date} appointmentData.appointment_date - The date and time of the appointment.
   * @param {string} appointmentData.purpose - The purpose of the appointment.
   * @param {string} [appointmentData.status='scheduled'] - The status of the appointment (default is 'scheduled').
   * @returns {Object} Returns a success message and the newly created appointment object or an error message if the creation fails.
   * @throws Throws an error if the appointment data is invalid or cannot be saved.
   */
  static async createAppointment({ patient_id, doctor_id, appointment_date, purpose, status = "scheduled",}) {
    // Create a new appointment object
    const appointment = new Appointment({
      patient: patient_id,
      doctor: doctor_id,
      appointment_date,
      purpose,
      status,
    });

    // Validate the appointment data before saving
    const validationError = appointment.validateSync();
    if (validationError) {
      throw new Error(
        `appointmentService-create appointment: ${validationError.message}`
      );
    }

    // Save the appointment to the database
    appointment.save();
    return {
      message: "Appointment created successfully",
      new_appointment: appointment,
    };
  }

  /**
   * Finds an appointment by its unique identifier.
   * The function checks if the provided appointment ID is valid and retrieves the corresponding appointment.
   *
   * @param {string} appointment_id - The unique identifier of the appointment.
   * @returns {Object} Returns the found appointment or an error message if the appointment does not exist.
   * @throws Throws an error if the appointment ID is invalid.
   */
  static async findAppointment(appointment_id) {
    // Validate the provided appointment ID
    if (!mongoose.isValidObjectId(appointment_id)) {
      throw new Error(
        "appointmentService-appointment exists: Invalid appointment_id"
      );
    }
    // Fetch the appointment by ID
    return await Appointment.findOne({ _id: appointment_id });
  }

  /**
   * Deletes an appointment from the database.
   * The function validates the appointment ID and ensures the appointment exists before deletion.
   *
   * @param {string} appointment_id - The unique identifier of the appointment to be deleted.
   * @returns {Object} Returns a success message and the deleted appointment object or an error message if the appointment cannot be found.
   * @throws Throws an error if the appointment ID is invalid or the appointment does not exist.
   */
  static async deleteAppointment(appointment_id) {
    // Validate the provided appointment ID
    if (!mongoose.isValidObjectId(appointment_id)) {
      throw new Error(
        "appointmentService-delete appointment: Invalid appointment_id"
      );
    }

    // Check if the appointment exists in the database
    const appointment = await Appointment.findById(appointment_id);
    if (!appointment) {
      throw new Error(
        "appointmentService-delete appointment: Appointment not found"
      );
    }

    // Delete the appointment
    const deletedAppointment = await Appointment.findByIdAndDelete(
      appointment_id
    );

    if (!deletedAppointment) {
      throw new Error(
        "appointmentService-delete appointment: Failed to delete appointment"
      );
    }

    return {
      message: "Appointment successfully deleted",
      deletedAppointment,
    };
  }

  static async updateAppointment(appointmentId, updateFields) {
      // Validate the appointmentId as a valid MongoDB ObjectId
      if (!mongoose.isValidObjectId(appointmentId)) {
        throw new Error("appointmentService-update appointment: Invalid appointmentId");
      }
  
      // Prevent updating the _id field
      if (updateFields._id) {
          throw new Error("appointmentService-update appointment: Changing the '_id' field is not allowed");
      }
  
      // Perform the update
      const updatedAppointment = await Appointment.findByIdAndUpdate(
          appointmentId,
          { $set: updateFields }, // Update only the provided fields
          { new: true, runValidators: true } // Return the updated document and run schema validators
      );
  
      if (!updatedAppointment) {
          throw new Error("appointmentService-update appointment: Appointment not found");
      }
  
      return updatedAppointment;
    }

}

module.exports = AppointmentService;
