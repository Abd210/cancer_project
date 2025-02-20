require("dotenv").config();

const express = require("express");
const { db } = require("./firebase"); // Import shared Firebase instance
const authRoutes = require("./Routes/authRoutes");
const patientRoutes = require("./Routes/patientRoutes");
const hospitalRoutes = require("./Routes/hospitalRoutes");
const appointmentRoutes = require("./Routes/appointmentRoutes");
const doctorRoutes = require("./Routes/doctorRoutes");
const testRoutes = require("./Routes/testRoutes");
const ticketRoutes = require("./Routes/ticketRoutes");
const adminRoutes = require("./Routes/adminRoutes");

const bodyParser = require("body-parser");
const helmet = require("helmet");
const cors = require("cors");

const app = express();

// Middleware setup
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());

// Auth Routes
app.use("/api/auth", authRoutes);

// API Routes
app.use("/api", patientRoutes);
app.use("/api", hospitalRoutes);
app.use("/api", appointmentRoutes);
app.use("/api", doctorRoutes);
app.use("/api", testRoutes);
app.use("/api", ticketRoutes);
app.use("/api", adminRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
