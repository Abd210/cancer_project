const DeviceService = require("../../Services/deviceService");
const TestService = require("../../Services/testService");
const SuspendController = require("../suspendController");

class DeviceController {
  static async createDevice(req, res) {
    try {
      const deviceData = req.body;
      const newDevice = await DeviceService.createDevice(deviceData);
      res.status(201).json(newDevice);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async updateDevice(req, res) {
    try {
      const { deviceId } = req.headers;
      const updateFields = req.body;

      if (!deviceId) {
        return res.status(400).json({ error: "Device ID is required" });
      }

      const updatedDevice = await DeviceService.updateDevice(
        deviceId,
        updateFields
      );
      res.status(200).json(updatedDevice);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async deleteDevice(req, res) {
    try {
      const { deviceId } = req.headers;

      if (!deviceId) {
        return res.status(400).json({ error: "Device ID is required" });
      }

      const result = await DeviceService.deleteDevice(deviceId);
      res.status(200).json({ message: "Device deleted successfully" });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async uploadDeviceData(req, res) {
    try {
      const { deviceId, testData } = req.body;

      if (!deviceId || !testData) {
        return res
          .status(400)
          .json({ error: "Device ID and test data are required" });
      }

      const device = await DeviceService.getDeviceById(deviceId);

      if (!device) {
        return res.status(404).json({ error: "Device not found" });
      }

      const test = await TestService.findTest(device.test);

      if (!test) {
        return res.status(404).json({ error: "Associated test not found" });
      }

      if (test.patient.toString() !== device.patient.toString()) {
        return res
          .status(403)
          .json({ error: "Unauthorized to upload data for this test" });
      }

      test.results.push(testData);
      await test.save();

      res.status(200).json({ message: "Data uploaded successfully", test });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async getDeviceData(req, res) {
    try {
      const { user, suspendfilter } = req.headers;
      const { deviceId } = req.headers;

      if (!deviceId) {
        return res.status(400).json({ error: "Device ID is required" });
      }

      const device = await DeviceService.getDeviceById(deviceId);

      if (!device) {
        return res.status(404).json({ error: "Device not found" });
      }

      // Ensure that only the assigned patient can access the device's data
      if (user.role === "patient" && device.patient.toString() !== user._id) {
        return res
          .status(403)
          .json({ error: "Unauthorized access to this device data" });
      }

      // Apply SuspendController filtering
      const filteredDevice = await SuspendController.filterData(
        device,
        user.role,
        suspendfilter
      );

      res.status(200).json(filteredDevice);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = DeviceController;
