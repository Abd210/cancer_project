require("dotenv").config(".env");

const express = require("express");
const mongoose = require("mongoose");
const authRoutes = require("./Routes/authRoutes");
const patientRoutes = require("./Routes/patientRoutes");
const hospitalRoutes = require("./Routes/hospitalRoutes");
const appointmentRoutes = require("./Routes/appointmentRoutes");
const doctorRoutes = require("./Routes/doctorRoutes");
const testRoutes = require("./Routes/testRoutes");
const ticketRoutes = require("./Routes/ticketRoutes");

const bodyParser = require("body-parser");
const helmet = require("helmet");
const cors = require("cors");

const app = express();

app.use(helmet());
app.use(cors());
app.use(bodyParser.json());

// Auth Routes
app.use("/api/auth", authRoutes);

// Patient Routes
// All patient endpoints prefixed by /api
app.use("/api", patientRoutes);
app.use("/api", hospitalRoutes);
app.use("/api", appointmentRoutes);
app.use("/api", doctorRoutes);
app.use("/api", testRoutes);
app.use("/api", ticketRoutes);

// Connect to MongoDB Atlas
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
