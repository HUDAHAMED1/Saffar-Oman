import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "addmin.saffaroman@gmail.com",
    pass: "abcdefghijklmnop",
  },
});

function normalizeEmail(email?: string): string | undefined {
  return typeof email === "string" ? email.trim().toLowerCase() : undefined;
}

function normalizeCode(code?: string): string | undefined {
  return typeof code === "string" ? code.trim() : undefined;
}

function otpKey(email: string): string {
  return email.replace(/\./g, "_");
}

function generateOtp(length = 4): string {
  const min = Math.pow(10, length - 1);
  const max = Math.pow(10, length) - 1;
  return Math.floor(min + Math.random() * (max - min + 1)).toString();
}

/**
 * Send OTP email for password reset
 */
export const sendOtpEmail = functions.https.onCall(async (request) => {
  const data = (request as unknown as {data: unknown}).data as {
    email?: string;
  };

  const email = normalizeEmail(data.email);

  if (!email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email is required"
    );
  }

  try {
    await admin.auth().getUserByEmail(email);
  } catch (error) {
    throw new functions.https.HttpsError(
      "not-found",
      "No account found with this email"
    );
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 5 * 60 * 1000;

  await admin
    .database()
    .ref("passwordOtps")
    .child(otpKey(email))
    .set({
      otp,
      expiresAt,
    });

  await transporter.sendMail({
    from: "Saffar Oman <addmin.saffaroman@gmail.com>",
    to: email,
    subject: "Your verification code",
    text:
      "Your verification code is: " +
      otp +
      "\nThis code will expire in 5 minutes.",
  });

  return {success: true};
});

/**
 * Verify OTP code for password reset
 */
export const verifyOtp = functions.https.onCall(async (request) => {
  const data = (request as unknown as {data: unknown}).data as {
    email?: string;
    code?: string;
  };

  const email = normalizeEmail(data.email);
  const code = normalizeCode(data.code);

  if (!email || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email and code are required"
    );
  }

  const snap = await admin
    .database()
    .ref("passwordOtps")
    .child(otpKey(email))
    .get();

  if (!snap.exists()) {
    throw new functions.https.HttpsError("not-found", "OTP not found");
  }

  const val = snap.val() as {otp: string; expiresAt: number};

  if (Date.now() > val.expiresAt) {
    await snap.ref.remove();
    throw new functions.https.HttpsError(
      "deadline-exceeded",
      "OTP expired"
    );
  }

  if (val.otp !== code) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Invalid code"
    );
  }

  await snap.ref.remove();

  return {verified: true};
});

/**
 * Send OTP email for payment verification
 */
export const requestPaymentOtp = functions.https.onCall(async (request) => {
  const data = (request as unknown as {data: unknown}).data as {
    email?: string;
  };

  const email = normalizeEmail(data.email);

  if (!email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email is required"
    );
  }

  try {
    await admin.auth().getUserByEmail(email);
  } catch (error) {
    throw new functions.https.HttpsError(
      "not-found",
      "No account found with this email"
    );
  }

  const otp = generateOtp(4);
  const expiresAt = Date.now() + 5 * 60 * 1000;

  await admin
    .database()
    .ref("paymentOtps")
    .child(otpKey(email))
    .set({
      otp,
      expiresAt,
    });

  await transporter.sendMail({
    from: "Saffar Oman <addmin.saffaroman@gmail.com>",
    to: email,
    subject: "Payment verification code",
    text:
      "Your payment verification code is: " +
      otp +
      "\nThis code will expire in 5 minutes.",
  });

  return {success: true};
});

/**
 * Verify OTP code for payment verification
 */
export const verifyPaymentOtp = functions.https.onCall(async (request) => {
  const data = (request as unknown as {data: unknown}).data as {
    email?: string;
    code?: string;
  };

  const email = normalizeEmail(data.email);
  const code = normalizeCode(data.code);

  if (!email || !code) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email and code are required"
    );
  }

  const snap = await admin
    .database()
    .ref("paymentOtps")
    .child(otpKey(email))
    .get();

  if (!snap.exists()) {
    throw new functions.https.HttpsError("not-found", "OTP not found");
  }

  const val = snap.val() as {otp: string; expiresAt: number};

  if (Date.now() > val.expiresAt) {
    await snap.ref.remove();
    throw new functions.https.HttpsError(
      "deadline-exceeded",
      "OTP expired"
    );
  }

  if (val.otp !== code) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Invalid code"
    );
  }

  await snap.ref.remove();

  return {verified: true};
});