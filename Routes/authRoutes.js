// routes/authRoutes.js
const express = require("express");
const router = express.Router();
const AuthController = require("../Controllers/redirectAuthController");

router.post("/register", AuthController.register);
router.post("/login", AuthController.login);
router.post("/forgot-password", AuthController.forgotPassword);
router.put("/reset-password", AuthController.resetPassword);

module.exports = router;
