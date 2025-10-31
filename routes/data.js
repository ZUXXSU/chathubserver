import express from "express";
import { sendData } from "../controllers/data.js";
import { checkAuth } from "../middlewares/auth.js";
import { sendDataValidator, validateHandler } from "../lib/validators.js";

const app = express.Router();

// This is a public route, but it uses checkAuth to try to identify the user
app.post("/send", checkAuth, sendDataValidator(), validateHandler, sendData);

export default app;