type MpesaB2CParams = {
  phoneNumber: string;
  amount: number;
  remarks: string;
  occasion: string;
  payoutId: string;
};

function required(name: string) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

export async function getMpesaAccessToken() {
  const key = required('MPESA_CONSUMER_KEY');
  const secret = required('MPESA_CONSUMER_SECRET');
  const auth = Buffer.from(`${key}:${secret}`).toString('base64');
  const url =
    process.env.MPESA_ENV === 'production'
      ? 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
      : 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
  const response = await fetch(url, {
    headers: { Authorization: `Basic ${auth}` },
  });
  if (!response.ok) throw new Error('Failed to get M-Pesa OAuth token');
  const body = await response.json();
  return body.access_token as string;
}

export async function sendMpesaB2C(params: MpesaB2CParams) {
  if (!params.phoneNumber) throw new Error('Payout phoneNumber is required');
  const token = await getMpesaAccessToken();
  const url =
    process.env.MPESA_ENV === 'production'
      ? 'https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest'
      : 'https://sandbox.safaricom.co.ke/mpesa/b2c/v1/paymentrequest';
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      InitiatorName: required('MPESA_INITIATOR_NAME'),
      SecurityCredential: required('MPESA_SECURITY_CREDENTIAL'),
      CommandID: 'BusinessPayment',
      Amount: Math.round(params.amount),
      PartyA: required('MPESA_B2C_SHORTCODE'),
      PartyB: params.phoneNumber,
      Remarks: params.remarks,
      QueueTimeOutURL: `${required('NEXT_PUBLIC_ADMIN_BASE_URL')}/api/mpesa/b2c/timeout`,
      ResultURL: `${required('NEXT_PUBLIC_ADMIN_BASE_URL')}/api/mpesa/b2c/result`,
      Occasion: params.occasion,
    }),
  });
  const body = await response.json();
  if (!response.ok) throw new Error(body.errorMessage || 'M-Pesa B2C request failed');
  return {
    provider: 'mpesa' as const,
    status: 'submitted' as const,
    conversationId: body.ConversationID as string,
    originatorConversationId: body.OriginatorConversationID as string,
    responseCode: body.ResponseCode as string,
    responseDescription: body.ResponseDescription as string,
  };
}
