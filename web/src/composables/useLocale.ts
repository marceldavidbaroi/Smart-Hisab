import { computed } from 'vue';
import { i18n } from '../boot/i18n';

const LOCALE_KEY = 'smart-hisab-locale';

export function useLocale() {
  const currentLocale = computed({
    get() {
      return i18n.global.locale.value;
    },
    set(newLocale: 'en-US' | 'bn') {
      i18n.global.locale.value = newLocale;
      localStorage.setItem(LOCALE_KEY, newLocale);
    },
  });

  const localeOptions = [
    { value: 'en-US' as const, short: 'EN', labelKey: 'common.english' },
    { value: 'bn' as const, short: 'বাং', labelKey: 'common.bangla' },
  ];

  return {
    locale: currentLocale,
    localeOptions,
  };
}
