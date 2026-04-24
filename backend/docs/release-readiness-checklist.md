# Release Readiness Checklist

## Environment and Config

- [ ] `backend/.env.example` matches all runtime keys.
- [ ] Production secrets are set (`JWT_SECRET`, DB, provider keys, push keys).
- [ ] `FRONTEND_URL`, `HOME_DOMAIN`, `API_DOMAIN`, and `WEB_AUTH_DOMAIN` are correct.

## Database and Migrations

- [ ] Run `npx prisma migrate deploy` in target environment.
- [ ] Confirm latest migration applied successfully.
- [ ] Confirm new `FlutterwavePayment` fields are present.

## API and Mobile Smoke

- [ ] Auth: send OTP -> verify OTP -> token issuance.
- [ ] Wallet: send and swap happy/failure paths.
- [ ] Invoices: create -> send -> public pay page.
- [ ] Requests: create -> public pay page -> cancel/mark-paid.
- [ ] Workflows: create supported action, run, pause/resume, blocked-action response.

## Logging and Observability

- [ ] Error responses include `{ code, message, details }`.
- [ ] Server logs include route failure details for payment/workflow actions.
- [ ] Alert rules exist for:
  - payment provider failures
  - repeated workflow execution failures
  - sustained 5xx rate spikes

## Rollback

- [ ] Previous deploy artifact is available.
- [ ] Rollback command/runbook is documented and tested.
- [ ] Data compatibility confirmed for rollback window.

## Test Execution

- [ ] Run: `npm test` (backend integration suite).
- [ ] Run: lint checks for touched backend and mobile files.
- [ ] Record artifacts/log output for deployment approval.
