// services/authService.js
const User = require('../models/User');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

class AuthService {
    static async register({ username, password }) {
        // Check if user already exists
        const existingUser = await User.findOne({ username });
        if (existingUser) {
            throw new Error('Username is already taken');
        }

        // Create and save the new user
        const newUser = new User({ username, password });
        await newUser.save();

        return { message: 'User registered successfully' };
    }

    static async login({ username, password }) {
        // Check if user exists
        const user = await User.findOne({ username });
        if (!user) {
            throw new Error('User not found');
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            throw new Error('Invalid credentials');
        }

        // Generate JWT
        const token = jwt.sign(
            { id: user._id, username: user.username },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        return { token };
    }
}

module.exports = AuthService;
