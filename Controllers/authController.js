// controllers/authController.js
const AuthService = require('../Services/authService');

class AuthController {
    static async register(req, res) {
        try {
            console.log('reached auth controller');
            const { username, password } = req.body; // Destructure here first
            console.log('username', username);        // Then log username after it's declared
            console.log(req.body);
    
            const result = await AuthService.register({ username, password });
            res.status(201).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
    

    static async login(req, res) {
        try {
            console.log('reached auth controller');
            const { username, password } = req.body;
            console.log('username', username);
            const result = await AuthService.login({ username, password });
            res.status(200).json(result);
        } catch (error) {
            res.status(400).json({ error: error.message });
        }
    }
}

module.exports = AuthController;
