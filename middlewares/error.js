import { envMode } from "../app.js";

const errorMiddleware = (err, req, res, next) => {
  err.message ||= "Internal Server Error";
  err.statusCode ||= 500;

  // Firebase errors will be caught here.
  // You can add specific checks for Firebase error codes if needed.
  // Example: if (err.code === 'auth/id-token-expired') { ... }

  const response = {
    success: false,
    message: err.message,
  };

  if (envMode === "DEVELOPMENT") {
    response.error = err;
  }

  return res.status(err.statusCode).json(response);
};

// Wrapper for async functions to catch errors and pass them to errorMiddleware
const TryCatch = (passedFunc) => async (req, res, next) => {
  try {
    await passedFunc(req, res, next);
  } catch (error) {
    console.error("Caught API Controller Error:", error);
    next(error);
  }
};

export { errorMiddleware, TryCatch };