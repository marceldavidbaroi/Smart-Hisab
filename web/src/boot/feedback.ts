import { defineBoot } from '#q-app';
import { Notify } from 'quasar';

export default defineBoot(() => {
  Notify.setDefaults({
    position: 'top',
    timeout: 2500,
    textColor: 'white',
    actions: [{ icon: 'close', color: 'white', round: true, dense: true }],
  });
});
