import { Dialog, Notify } from 'quasar';
import { extractApiErrorMessage } from '../utils/apiError';
import { i18n } from '../boot/i18n';

export type ToastOptions = {
  timeout?: number;
  caption?: string;
};

/** Centered modal for hard / API errors. Closes only via OK. */
export function showError(message: string, title?: string): Promise<void> {
  const displayTitle = title || i18n.global.t('feedback.errorTitle');
  return new Promise((resolve) => {
    Dialog.create({
      title: `<div class="row items-center q-pb-xs">
        <div class="q-pa-xs rounded-borders bg-red-1 text-red-9 flex flex-center q-mr-sm" style="width: 36px; height: 36px; border-radius: 50%;">
          <i class="q-icon material-icons" style="font-size: 20px;">error_outline</i>
        </div>
        <span class="text-weight-bold text-subtitle1 text-grey-9">${displayTitle}</span>
      </div>`,
      message,
      html: true,
      persistent: true,
      ok: {
        label: i18n.global.t('feedback.ok'),
        color: 'negative',
        unelevated: true,
        class: 'q-px-md cursor-pointer text-weight-bold rounded-borders',
      },
    }).onOk(() => resolve());
  });
}

/** Parse API/unknown error and show as error dialog. */
export function showApiError(err: unknown, fallback?: string, title?: string): Promise<void> {
  const fallbackMsg = fallback || i18n.global.t('feedback.somethingWentWrong');
  const displayTitle = title || i18n.global.t('feedback.errorTitle');
  return showError(extractApiErrorMessage(err, fallbackMsg), displayTitle);
}

export function showSuccess(message: string, options?: ToastOptions): void {
  const config: Record<string, unknown> = {
    type: 'positive',
    message,
    position: 'top',
    timeout: options?.timeout ?? 2500,
  };
  if (options?.caption !== undefined) {
    config.caption = options.caption;
  }
  Notify.create(config);
}

export function showInfo(message: string, options?: ToastOptions): void {
  const config: Record<string, unknown> = {
    type: 'info',
    message,
    position: 'top',
    timeout: options?.timeout ?? 2500,
  };
  if (options?.caption !== undefined) {
    config.caption = options.caption;
  }
  Notify.create(config);
}

export function showWarning(message: string, options?: ToastOptions): void {
  const config: Record<string, unknown> = {
    type: 'warning',
    message,
    position: 'top',
    timeout: options?.timeout ?? 3000,
  };
  if (options?.caption !== undefined) {
    config.caption = options.caption;
  }
  Notify.create(config);
}

/** Composable alias — same helpers, usable in setup(). */
export function useFeedback() {
  return {
    showError,
    showApiError,
    showSuccess,
    showInfo,
    showWarning,
  };
}
