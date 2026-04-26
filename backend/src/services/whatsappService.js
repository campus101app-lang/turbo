// src/services/whatsappService.js
//
// sendInvoiceWhatsApp()
// Sends a WhatsApp message to the client using Twilio's WhatsApp API.
//
// Prerequisites:
//   npm install twilio
//   Set env vars: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM
//   TWILIO_WHATSAPP_FROM format: "whatsapp:+14155238886"  (Twilio sandbox number or approved sender)
//
// For production, apply for a WhatsApp Business API sender at:
//   https://www.twilio.com/whatsapp

import twilio from 'twilio';

let _client = null;

function getClient() {
  if (!_client) {
    if (!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN) {
      throw new Error('Twilio credentials not configured (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)');
    }
    _client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  }
  return _client;
}

/**
 * Normalise a phone number to E.164 format for WhatsApp.
 * Strips spaces, dashes; prepends +234 for bare Nigerian numbers.
 *
 * @param {string} phone
 * @returns {string}  e.g. "+2348012345678"
 */
function normalisePhone(phone) {
  let p = phone.replace(/[\s\-().]/g, '');
  if (p.startsWith('0') && !p.startsWith('00')) {
    p = '+234' + p.slice(1);      // 08012… → +23481…
  }
  if (!p.startsWith('+')) {
    p = '+' + p;
  }
  return p;
}

/**
 * @param {string} toPhone  - Client phone number (any reasonable format)
 * @param {{
 *   clientName: string,
 *   businessName: string,
 *   totalAmount: number,
 *   currency: 'NGNT' | 'USDC',
 *   paymentLink: string,
 * }} data
 */
export async function sendInvoiceWhatsApp(toPhone, data) {
  const { clientName, businessName, totalAmount, currency, paymentLink } = data;
  const client = getClient();

  const sym             = currency === 'USDC' ? '$' : '₦';
  const formattedAmount = `${sym}${Number(totalAmount).toLocaleString('en-NG', { minimumFractionDigits: 2 })}`;
  const normalised      = normalisePhone(toPhone);

  const body =
    `Hi ${clientName} 👋\n\n` +
    `*${businessName}* sent you an invoice for *${formattedAmount}*.\n\n` +
    `Pay securely here:\n${paymentLink}\n\n` +
    `_Powered by Dayfi_`;

  await client.messages.create({
    from: process.env.TWILIO_WHATSAPP_FROM,   // "whatsapp:+14155238886"
    to:   `whatsapp:${normalised}`,
    body,
  });
}