// models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
    username: { type: String, unique: true, required: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['patient', 'doctor', 'admin', 'superadmin'], default: 'patient', required: true },
    // Patient fields
    name: { type: String },
    dateOfBirth: { type: Date },
    medicalHistory: [{ type: String }], 
    // Doctor fields
    specialization: { type: String },
    rating: { type: Number, default: 4.5 } // For doctors only
}, { timestamps: true });

// Hash the password before saving the user
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Compare given password with the stored hashed password
userSchema.methods.comparePassword = function(candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
