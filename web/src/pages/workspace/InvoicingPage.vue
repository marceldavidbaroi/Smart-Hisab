<template>
  <q-page class="q-pa-md q-pa-sm-lg">
    <!-- Header -->
    <div class="row items-center justify-between q-mb-lg q-mb-sm-xl">
      <div>
        <h1 class="text-h5 text-sm-h4 text-weight-bold q-my-none flex items-center text-grey-9">
          <q-icon name="receipt" color="primary" size="36px" class="q-mr-sm" />
          Invoices & Billing
        </h1>
        <p class="text-grey-7 text-subtitle2 q-mt-xs q-mb-none">
          Track organization bills, payments, and client receipts for
          <span class="text-primary text-weight-bold">{{ tenantStore.activeTenant?.name }}</span>
        </p>
      </div>
      <div>
        <q-btn
          unelevated
          color="primary"
          icon="add"
          label="Create Invoice"
          no-caps
          class="q-px-md text-weight-bold cursor-pointer action-btn"
          style="border-radius: 8px"
          @click="showCreateInvoiceDialog = true"
        />
      </div>
    </div>

    <!-- KPI Summary cards -->
    <div class="row q-col-gutter-sm q-col-gutter-sm-md q-mb-lg">
      <div class="col-12 col-sm-6 col-md-3" v-for="stat in invoiceStats" :key="stat.title">
        <q-card flat bordered class="bg-white">
          <q-card-section class="q-pa-md flex justify-between items-center">
            <div>
              <div class="text-grey-7 text-xs text-weight-bold uppercase tracking-wider q-mb-xs">
                {{ stat.title }}
              </div>
              <div class="text-h5 text-weight-bold" :class="stat.valueClass">{{ stat.value }}</div>
            </div>
            <q-avatar :color="stat.avatarBg" size="42px">
              <q-icon :name="stat.icon" size="24px" :class="stat.iconColor" />
            </q-avatar>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Filter and Invoice List -->
    <q-card flat bordered class="bg-white">
      <q-card-section class="row items-center justify-between q-pb-md border-bottom">
        <div class="row items-center q-col-gutter-sm col-12 col-sm-auto q-mb-sm q-mb-sm-none">
          <div class="text-subtitle1 text-weight-bold q-mr-md text-grey-9">Invoice Registry</div>
          <!-- Simple search input -->
          <q-input
            dense
            outlined
            v-model="searchQuery"
            placeholder="Search client or ID..."
            class="bg-white search-input"
          >
            <template v-slot:append>
              <q-icon name="search" class="text-grey-6" size="18px" />
            </template>
          </q-input>
        </div>

        <!-- Filter Chips -->
        <div class="row q-gutter-xs col-12 col-sm-auto justify-start justify-sm-end">
          <q-btn
            v-for="filter in ['all', 'paid', 'sent', 'overdue', 'draft']"
            :key="filter"
            unelevated
            dense
            no-caps
            :label="filter"
            :color="activeFilter === filter ? 'primary' : 'transparent'"
            :text-color="activeFilter === filter ? 'white' : 'grey-7'"
            class="q-px-sm text-caption text-weight-bold cursor-pointer filter-btn"
            @click="activeFilter = filter"
          />
        </div>
      </q-card-section>

      <!-- Invoices List -->
      <q-card-section class="q-pa-none">
        <q-list separator class="text-grey-9">
          <q-item
            v-if="filteredInvoices.length === 0"
            class="q-py-xl text-center flex flex-col justify-center items-center text-grey-6"
          >
            <q-icon name="receipt_long" size="48px" class="q-mb-sm" />
            <div class="text-subtitle1 text-weight-medium">No invoices match your query.</div>
          </q-item>

          <q-item v-for="inv in filteredInvoices" :key="inv.id" class="q-py-md hover-row">
            <q-item-section avatar>
              <q-avatar color="grey-2" text-color="primary" class="text-weight-bold text-xs">
                INV
              </q-avatar>
            </q-item-section>

            <q-item-section>
              <div class="row items-center">
                <span class="text-weight-bold text-subtitle2 q-mr-sm text-grey-9">{{
                  inv.id
                }}</span>
                <q-badge
                  :color="getInvoiceStatusColor(inv.status)"
                  class="text-weight-bold text-uppercase text-xxs"
                  outline
                >
                  {{ inv.status }}
                </q-badge>
              </div>
              <q-item-label caption class="text-grey-7 q-mt-xs">
                Client: <span class="text-grey-9 text-weight-medium">{{ inv.client }}</span>
              </q-item-label>
            </q-item-section>

            <q-item-section class="gt-xs">
              <q-item-label caption class="text-grey-7">Issued: {{ inv.issuedDate }}</q-item-label>
              <q-item-label caption class="text-grey-7">Due: {{ inv.dueDate }}</q-item-label>
            </q-item-section>

            <q-item-section side>
              <div class="text-right">
                <div class="text-weight-bold text-grey-9 text-subtitle1">{{ inv.amount }}</div>
                <div class="row q-gutter-xs q-mt-xs justify-end">
                  <q-btn
                    flat
                    round
                    dense
                    size="sm"
                    icon="visibility"
                    color="grey-7"
                    class="cursor-pointer action-btn"
                    @click="mockPreviewInvoice(inv.id)"
                  />
                  <q-btn
                    flat
                    round
                    dense
                    size="sm"
                    icon="mail"
                    color="grey-7"
                    class="cursor-pointer action-btn"
                    @click="mockSendInvoice(inv.id)"
                  />
                </div>
              </div>
            </q-item-section>
          </q-item>
        </q-list>
      </q-card-section>
    </q-card>

    <!-- Create Invoice Mock Dialog -->
    <q-dialog v-model="showCreateInvoiceDialog">
      <q-card class="bg-white text-grey-9 q-pa-md" style="width: 100%; max-width: 440px">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6 text-weight-bold text-grey-9">Create Invoice</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup class="text-grey-6 cursor-pointer" />
        </q-card-section>

        <q-card-section class="q-pt-md q-gutter-y-sm">
          <q-input outlined dense v-model="newInvoice.client" label="Client Business Name" />
          <q-input
            outlined
            dense
            v-model="newInvoice.amount"
            label="Invoice Total Amount ($)"
            type="number"
          />
          <q-input
            outlined
            dense
            v-model="newInvoice.dueDate"
            label="Due Date"
            type="date"
            stack-label
          />
          <q-select
            outlined
            dense
            v-model="newInvoice.status"
            :options="['Paid', 'Sent', 'Draft']"
            label="Initial Invoice Status"
          />
        </q-card-section>

        <q-card-actions align="right" class="q-pt-md">
          <q-btn flat label="Cancel" no-caps v-close-popup color="grey-7" class="cursor-pointer" />
          <q-btn
            unelevated
            color="primary"
            label="Generate Invoice"
            no-caps
            @click="handleCreateInvoice"
            class="text-weight-bold cursor-pointer"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useTenantStore } from '../../stores/tenant';
import { useQuasar } from 'quasar';

const tenantStore = useTenantStore();
const $q = useQuasar();

interface Invoice {
  id: string;
  client: string;
  status: string;
  amount: string;
  issuedDate: string;
  dueDate: string;
}

const showCreateInvoiceDialog = ref(false);
const searchQuery = ref('');
const activeFilter = ref('all');

const newInvoice = ref<{
  client: string;
  amount: string;
  dueDate: string;
  status: string;
}>({
  client: '',
  amount: '',
  dueDate: '',
  status: 'Sent',
});

const invoiceStats = computed(() => [
  {
    title: 'Total Collected',
    value: '$124,650',
    valueClass: 'text-positive',
    icon: 'check_circle',
    avatarBg: 'green-1',
    iconColor: 'text-positive',
  },
  {
    title: 'Outstanding Balance',
    value: '$34,200',
    valueClass: 'text-warning',
    icon: 'pending',
    avatarBg: 'orange-1',
    iconColor: 'text-warning',
  },
  {
    title: 'Overdue Amount',
    value: '$8,400',
    valueClass: 'text-negative',
    icon: 'warning',
    avatarBg: 'red-1',
    iconColor: 'text-negative',
  },
  {
    title: 'Invoices Issued',
    value: '42 Total',
    valueClass: 'text-primary',
    icon: 'tag',
    avatarBg: 'blue-1',
    iconColor: 'text-primary',
  },
]);

const invoices = ref<Invoice[]>([
  {
    id: 'INV-2026-041',
    client: 'Alpha Retailers',
    status: 'paid',
    amount: '$12,400',
    issuedDate: '2026-07-01',
    dueDate: '2026-07-15',
  },
  {
    id: 'INV-2026-042',
    client: 'Vortex Global',
    status: 'sent',
    amount: '$8,750',
    issuedDate: '2026-07-05',
    dueDate: '2026-07-20',
  },
  {
    id: 'INV-2026-043',
    client: 'Starlight Corp',
    status: 'overdue',
    amount: '$5,900',
    issuedDate: '2026-06-10',
    dueDate: '2026-06-25',
  },
  {
    id: 'INV-2026-044',
    client: 'Quantum Dynamics',
    status: 'draft',
    amount: '$18,600',
    issuedDate: '2026-07-12',
    dueDate: '2026-07-27',
  },
  {
    id: 'INV-2026-045',
    client: 'Nexus Tech LLC',
    status: 'paid',
    amount: '$32,000',
    issuedDate: '2026-06-20',
    dueDate: '2026-07-05',
  },
  {
    id: 'INV-2026-046',
    client: 'Eldorado Design',
    status: 'overdue',
    amount: '$2,500',
    issuedDate: '2026-06-01',
    dueDate: '2026-06-15',
  },
]);

const getInvoiceStatusColor = (status: string) => {
  switch (status.toLowerCase()) {
    case 'paid':
      return 'positive';
    case 'overdue':
      return 'negative';
    case 'sent':
      return 'info';
    default:
      return 'warning';
  }
};

const filteredInvoices = computed(() => {
  return invoices.value.filter((inv) => {
    // 1. Filter by Status chip
    if (
      activeFilter.value !== 'all' &&
      inv.status.toLowerCase() !== activeFilter.value.toLowerCase()
    ) {
      return false;
    }
    // 2. Filter by search input
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      return inv.id.toLowerCase().includes(q) || inv.client.toLowerCase().includes(q);
    }
    return true;
  });
});

const handleCreateInvoice = () => {
  if (!newInvoice.value.client || !newInvoice.value.amount || !newInvoice.value.dueDate) {
    $q.notify({ type: 'warning', message: 'Please fill in all fields' });
    return;
  }

  const invoiceNum = String(invoices.value.length + 42);
  const val = parseFloat(newInvoice.value.amount);
  const formattedVal = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(val);

  const todayStr = new Date().toISOString().split('T')[0] || '';

  invoices.value.unshift({
    id: `INV-2026-0${invoiceNum}`,
    client: newInvoice.value.client,
    status: newInvoice.value.status.toLowerCase(),
    amount: formattedVal,
    issuedDate: todayStr,
    dueDate: newInvoice.value.dueDate,
  });

  showCreateInvoiceDialog.value = false;
  newInvoice.value = { client: '', amount: '', dueDate: '', status: 'Sent' };

  $q.notify({
    type: 'positive',
    message: 'Invoice successfully generated and logged!',
    position: 'top',
  });
};

const mockPreviewInvoice = (id: string) => {
  $q.notify({
    type: 'info',
    message: `Preview PDF generating for ${id} (Mock Action)`,
    position: 'bottom',
  });
};

const mockSendInvoice = (id: string) => {
  $q.notify({
    type: 'positive',
    message: `Invoice ${id} has been emailed to client (Mock Action)`,
    icon: 'mail',
    position: 'bottom',
  });
};
</script>

<style scoped lang="scss">
.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
}

.hover-row {
  transition: background-color 0.2s ease;
  &:hover {
    background-color: rgba(0, 0, 0, 0.02);
  }
}

.search-input {
  width: 100%;
  max-width: 240px;
}

.filter-btn {
  border-radius: 6px;
  font-size: 11px;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.text-xxs {
  font-size: 9px;
  padding: 2px 6px;
}

@media (max-width: 599.98px) {
  .search-input {
    max-width: 100%;
  }

  .action-btn {
    min-height: 48px;
    min-width: 48px;
  }
}
</style>
