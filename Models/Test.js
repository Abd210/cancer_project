// models/Test.js
const mongoose = require('mongoose');

const interpretationSchema = new mongoose.Schema({
    doctor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    interpretation: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
});

const testSchema = new mongoose.Schema({
    patient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    testResults: { type: String, required: true }, // maybe a lab result string
    interpretations: [interpretationSchema] // multiple doctors can interpret
});

module.exports = mongoose.model('Test', testSchema);
