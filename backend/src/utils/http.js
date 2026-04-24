export function sendError(res, status, code, message, details) {
  return res.status(status).json({
    code,
    message,
    details: details ?? null,
  });
}

export function sendValidationError(res, details) {
  return sendError(res, 400, 'VALIDATION_ERROR', 'Validation failed.', details);
}

export function sendUnauthorized(res, message = 'Authentication required.') {
  return sendError(res, 401, 'UNAUTHORIZED', message);
}

export function sendForbidden(res, message = 'You do not have permission for this action.') {
  return sendError(res, 403, 'FORBIDDEN', message);
}

export function sendNotFound(res, resource = 'Resource') {
  return sendError(res, 404, 'NOT_FOUND', `${resource} not found.`);
}
