const Device = require("../Models/Device");
const mongoose = require("mongoose");

class DeviceService {
  static async createDevice(deviceData) {
    const device = new Device(deviceData);

    const validationError = device.validateSync();
    if (validationError) {
      throw new Error(`Validation Error: ${validationError.message}`);
    }

    await device.save();
    return { message: "Device created successfully", device };
  }

  static async updateDevice(deviceId, updateFields) {
    if (!mongoose.isValidObjectId(deviceId)) {
      throw new Error("Invalid Device ID");
    }

    const updatedDevice = await Device.findByIdAndUpdate(
      deviceId,
      updateFields,
      {
        new: true,
        runValidators: true,
      }
    );

    if (!updatedDevice) {
      throw new Error("Device not found");
    }

    return updatedDevice;
  }

  static async deleteDevice(deviceId) {
    if (!mongoose.isValidObjectId(deviceId)) {
      throw new Error("Invalid Device ID");
    }

    const deletedDevice = await Device.findByIdAndDelete(deviceId);

    if (!deletedDevice) {
      throw new Error("Device not found");
    }

    return { message: "Device deleted successfully", deletedDevice };
  }

  static async uploadDeviceData(deviceId, testData) {
    if (!mongoose.isValidObjectId(deviceId)) {
      throw new Error("Invalid Device ID");
    }

    const device = await Device.findById(deviceId);

    if (!device) {
      throw new Error("Device not found");
    }

    // Assuming there's a field for device data
    device.data = testData;
    await device.save();

    return { message: "Data uploaded successfully", device };
  }

  static async getDeviceData(deviceId) {
    if (!mongoose.isValidObjectId(deviceId)) {
      throw new Error("Invalid Device ID");
    }

    const device = await Device.findById(deviceId);

    if (!device) {
      throw new Error("Device not found");
    }

    return device;
  }
}

module.exports = DeviceService;
