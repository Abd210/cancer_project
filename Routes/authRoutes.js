// routes/authRoutes.js
const express = require("express");
const router = express.Router();
const RedirectAuthController = require("../Controllers/redirectAuthController.js");

router.post("/register", RedirectAuthController.register);
router.post("/login", RedirectAuthController.login);

module.exports = router;
