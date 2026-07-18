/** Extract a user-facing message from Supabase / Postgrest / generic errors. */
export function extractApiErrorMessage(err: unknown, fallback = 'Something went wrong'): string {
  if (err == null) return fallback;

  if (typeof err === 'string') {
    const trimmed = err.trim();
    return trimmed || fallback;
  }

  if (err instanceof Error && err.message.trim()) {
    return err.message.trim();
  }

  if (typeof err === 'object') {
    const obj = err as Record<string, unknown>;
    for (const key of ['message', 'error_description', 'error', 'details', 'hint'] as const) {
      const val = obj[key];
      if (typeof val === 'string' && val.trim()) {
        return val.trim();
      }
    }
  }

  return fallback;
}
