import { FastifyInstance } from 'fastify';
import { sendOtpHandler, verifyOtpHandler, googleAuthHandler } from '../controllers/auth.controller.js';

export async function authRoutes(fastify: FastifyInstance) {
  fastify.post('/send-otp', sendOtpHandler);
  fastify.post('/verify-otp', verifyOtpHandler);
  fastify.post('/google', googleAuthHandler);
}
