// src/services/flutterwaveService.js
//
// Virtual account data is stored directly on the User model:
//   user.virtualAccountNumber, user.virtualAccountBank, user.virtualAccountName
// There is NO separate VirtualAccount table in the schema.

import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export async function createVirtualAccount({ userId, bvn }) {
  // ── 1. Check user record first ─────────────────────────────────────────────
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new Error('User not found');

  if (user.virtualAccountNumber) {
    console.log(`✅ Virtual account already on user: ${user.virtualAccountNumber}`);
    return {
      accountNumber: user.virtualAccountNumber,
      bankName: user.virtualAccountBank,
      accountName: user.virtualAccountName,
    };
  }

  // ── 2. Stable tx_ref — deterministic so recovery works on duplicate BVN ───
  const orderRef = `dayfi-${userId}`;

  const payload = {
    email: user.email,
    is_permanent: true,
    bvn,
    tx_ref: orderRef,
    amount: 100,
    currency: 'NGN',
    fullname: user.fullName || user.businessName || 'DayFi User',
    phone_number: user.phone || '08000000000',
  };

  // ── 3. Call Flutterwave ────────────────────────────────────────────────────
  const response = await fetch('https://api.flutterwave.com/v3/virtual-account-numbers', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.FLW_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const flwData = await response.json();
  console.log('Flutterwave response:', JSON.stringify(flwData));

  // ── 4. Duplicate BVN — recover existing account via order_ref ─────────────
  const msg = (flwData.message || '').toLowerCase();
  const isDuplicate =
    flwData.status === 'error' &&
    (msg.includes('bvn') || msg.includes('exist') || msg.includes('duplicate') ||
     msg.includes('already') || msg.includes('used') || msg.includes('taken'));

  if (isDuplicate) {
    console.warn(`⚠️  Duplicate BVN for user ${userId}. Recovering via order_ref...`);

    const fetchRes = await fetch(
      `https://api.flutterwave.com/v3/virtual-account-numbers?order_ref=${orderRef}`,
      { headers: { Authorization: `Bearer ${process.env.FLW_SECRET_KEY}` } }
    );
    const fetchData = await fetchRes.json();
    console.log('Flutterwave recovery response:', JSON.stringify(fetchData));

    if (fetchData.status === 'success' && fetchData.data) {
      const { account_number, bank_name, account_name } = fetchData.data;
      await prisma.user.update({
        where: { id: userId },
        data: {
          virtualAccountNumber: account_number,
          virtualAccountBank: bank_name,
          virtualAccountName: account_name,
        },
      });
      console.log(`✅ Recovered: ${account_number} (${bank_name})`);
      return { accountNumber: account_number, bankName: bank_name, accountName: account_name };
    }

    throw new Error(`Could not recover virtual account. Support ref: ${orderRef}`);
  }

  // ── 5. Other errors ────────────────────────────────────────────────────────
  if (flwData.status !== 'success' || !flwData.data) {
    throw new Error(flwData.message || 'Failed to create virtual account');
  }

  // ── 6. Success — save to user record ──────────────────────────────────────
  const { account_number, bank_name, account_name } = flwData.data;
  await prisma.user.update({
    where: { id: userId },
    data: {
      virtualAccountNumber: account_number,
      virtualAccountBank: bank_name,
      virtualAccountName: account_name,
    },
  });

  console.log(`✅ Virtual account created: ${account_number} (${bank_name})`);
  return { accountNumber: account_number, bankName: bank_name, accountName: account_name };
}