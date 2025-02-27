const express = require("express");
const router = express.Router();
const deviceController = require("../Controllers/Objects Controllers/deviceController");
const { authenticate } = require("../middlewares/jwtAuth");
const { authorize } = require("../middlewares/roleAuth");
router.post(
  "/device/new",
  authenticate,
  authorize(["admin", "superadmin"]),
  deviceController.createDevice
);

router.put(
  "/device/update",
  authenticate,
  authorize(["admin", "superadmin"]),
  deviceController.updateDevice
);

router.delete(
  "/device/delete",
  authenticate,
  authorize(["superadmin"]),
  deviceController.deleteDevice
);

router.post(
  "/device/upload_data",
  authenticate,
  authorize(["device", "admin", "superadmin"]),
  deviceController.uploadDeviceData
);

router.get(
  "/device/data",
  authenticate,
  authorize(["patient, doctor,admin", "superadmin"]),
  deviceController.getDeviceData
);

module.exports = router;
