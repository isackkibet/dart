import { Response } from "express";

export function ok(res: Response, data: any, statusCode: number = 200) {
  return res.status(statusCode).json({
    success: true,
    data,
  });
}

export function fail(
  res: Response,
  statusCode: number,
  code: string,
  message: string,
  error?: any
) {
  console.error(`[${code}] ${message}`, error);
  return res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
      ...(error && process.env.NODE_ENV === "development" && { details: error }),
    },
  });
}
