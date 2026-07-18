import { defineBoot } from '#q-app';
import { createI18n } from 'vue-i18n';
import messages from '../i18n';

// Type definition for translations
export type MessageLanguages = keyof typeof messages;
export type MessageSchema = (typeof messages)['en-US'];

/* eslint-disable @typescript-eslint/no-empty-object-type */
declare module 'vue-i18n' {
  // define the locale messages schema
  export interface DefineLocaleMessage extends MessageSchema {}

  // define the datetime format schema
  export interface DefineDateTimeFormat {}

  // define the number format schema
  export interface DefineNumberFormat {}
}
/* eslint-enable @typescript-eslint/no-empty-object-type */

const LOCALE_KEY = 'smart-hisab-locale';
const storedLocale = typeof window !== 'undefined' ? localStorage.getItem(LOCALE_KEY) : null;
const initialLocale =
  storedLocale && ['en-US', 'bn'].includes(storedLocale) ? storedLocale : 'en-US';

export const i18n = createI18n({
  locale: initialLocale,
  fallbackLocale: 'en-US',
  legacy: false,
  globalInjection: true,
  messages,
});

export default defineBoot(({ app }) => {
  // Set i18n instance on app
  app.use(i18n);
});
