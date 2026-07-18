/**
 * Formats a numeric amount as currency using Intl.NumberFormat.
 * Default locale is 'bn' (Bengali) and default currency is 'BDT' (৳).
 */
export function formatMoney(amount: number, locale = 'bn', currency = 'BDT'): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}
