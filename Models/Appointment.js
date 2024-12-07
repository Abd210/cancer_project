// models/Appointment.js
const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
    patient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    doctor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    appointment_date: { type: Date, required: true },
    purpose: { type: String, required: true },
    status: { type: String, enum: ['scheduled', 'canceled', 'completed'], default: 'scheduled' }
});

appointmentSchema.index({ patient: 1, appointment_date: 1 }); // For efficient queries

module.exports = mongoose.model('Appointment', appointmentSchema);
