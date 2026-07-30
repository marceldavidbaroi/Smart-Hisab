export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      business_days: {
        Row: {
          business_date: string
          closed_at: string | null
          closed_by_staff_id: string | null
          closed_by_user_id: string | null
          closing_cash: number | null
          created_at: string
          expected_cash: number | null
          id: string
          notes: string | null
          opened_at: string
          opened_by_staff_id: string
          opened_by_user_id: string | null
          opening_cash: number
          status: string
          tenant_id: string
          updated_at: string
          variance: number | null
        }
        Insert: {
          business_date: string
          closed_at?: string | null
          closed_by_staff_id?: string | null
          closed_by_user_id?: string | null
          closing_cash?: number | null
          created_at?: string
          expected_cash?: number | null
          id?: string
          notes?: string | null
          opened_at?: string
          opened_by_staff_id: string
          opened_by_user_id?: string | null
          opening_cash?: number
          status: string
          tenant_id: string
          updated_at?: string
          variance?: number | null
        }
        Update: {
          business_date?: string
          closed_at?: string | null
          closed_by_staff_id?: string | null
          closed_by_user_id?: string | null
          closing_cash?: number | null
          created_at?: string
          expected_cash?: number | null
          id?: string
          notes?: string | null
          opened_at?: string
          opened_by_staff_id?: string
          opened_by_user_id?: string | null
          opening_cash?: number
          status?: string
          tenant_id?: string
          updated_at?: string
          variance?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "business_days_closed_by_staff_id_fkey"
            columns: ["closed_by_staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_days_opened_by_staff_id_fkey"
            columns: ["opened_by_staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_days_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_wallets: {
        Row: {
          created_at: string
          customer_id: string
          id: string
          tenant_id: string
        }
        Insert: {
          created_at?: string
          customer_id: string
          id?: string
          tenant_id: string
        }
        Update: {
          created_at?: string
          customer_id?: string
          id?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_wallets_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: true
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_wallets_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      customers: {
        Row: {
          category: string | null
          contract_daily_rate: number | null
          contract_shifts: string[] | null
          created_at: string
          factory_unit: string | null
          full_name: string
          id: string
          is_active: boolean
          outstanding_balance: number
          phone: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          category?: string | null
          contract_daily_rate?: number | null
          contract_shifts?: string[] | null
          created_at?: string
          factory_unit?: string | null
          full_name: string
          id?: string
          is_active?: boolean
          outstanding_balance?: number
          phone: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          category?: string | null
          contract_daily_rate?: number | null
          contract_shifts?: string[] | null
          created_at?: string
          factory_unit?: string | null
          full_name?: string
          id?: string
          is_active?: boolean
          outstanding_balance?: number
          phone?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "customers_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      day_entries: {
        Row: {
          amount: number
          business_day_id: string | null
          category: string
          created_at: string
          created_by_staff_id: string | null
          entry_type: string
          id: string
          notes: string | null
          reference_id: string | null
          reference_type: string | null
          shift_id: string | null
          tenant_id: string
        }
        Insert: {
          amount: number
          business_day_id?: string | null
          category: string
          created_at?: string
          created_by_staff_id?: string | null
          entry_type: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          shift_id?: string | null
          tenant_id: string
        }
        Update: {
          amount?: number
          business_day_id?: string | null
          category?: string
          created_at?: string
          created_by_staff_id?: string | null
          entry_type?: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          shift_id?: string | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "day_entries_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_entries_created_by_staff_id_fkey"
            columns: ["created_by_staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_entries_shift_id_fkey"
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_entries_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      day_notes: {
        Row: {
          business_day_id: string | null
          content: string
          created_at: string
          created_by_staff_id: string | null
          id: string
          note_type: string
          tenant_id: string
        }
        Insert: {
          business_day_id?: string | null
          content: string
          created_at?: string
          created_by_staff_id?: string | null
          id?: string
          note_type: string
          tenant_id: string
        }
        Update: {
          business_day_id?: string | null
          content?: string
          created_at?: string
          created_by_staff_id?: string | null
          id?: string
          note_type?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "day_notes_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_notes_created_by_staff_id_fkey"
            columns: ["created_by_staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "day_notes_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      device_pairings: {
        Row: {
          created_at: string
          device_name: string
          expires_at: string
          id: string
          pairing_code: string
          tenant_id: string
        }
        Insert: {
          created_at?: string
          device_name: string
          expires_at: string
          id?: string
          pairing_code: string
          tenant_id: string
        }
        Update: {
          created_at?: string
          device_name?: string
          expires_at?: string
          id?: string
          pairing_code?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "device_pairings_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_attendance: {
        Row: {
          business_day_id: string | null
          charge_amount: number
          created_at: string
          customer_id: string
          id: string
          recorded_by_staff_id: string | null
          shift_id: string | null
          tenant_id: string
        }
        Insert: {
          business_day_id?: string | null
          charge_amount?: number
          created_at?: string
          customer_id: string
          id?: string
          recorded_by_staff_id?: string | null
          shift_id?: string | null
          tenant_id: string
        }
        Update: {
          business_day_id?: string | null
          charge_amount?: number
          created_at?: string
          customer_id?: string
          id?: string
          recorded_by_staff_id?: string | null
          shift_id?: string | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meal_attendance_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_attendance_customer_id_fkey"
            columns: ["customer_id"]
            isOneToOne: false
            referencedRelation: "customers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_attendance_recorded_by_staff_id_fkey"
            columns: ["recorded_by_staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_attendance_shift_id_fkey"
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_attendance_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_configs: {
        Row: {
          created_at: string
          effective_from: string
          id: string
          rate: number
          shift_id: string | null
          tenant_id: string
        }
        Insert: {
          created_at?: string
          effective_from?: string
          id?: string
          rate: number
          shift_id?: string | null
          tenant_id: string
        }
        Update: {
          created_at?: string
          effective_from?: string
          id?: string
          rate?: number
          shift_id?: string | null
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "meal_configs_shift_id_fkey"
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meal_configs_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      paired_devices: {
        Row: {
          device_name: string
          device_sl: number | null
          device_token: string
          failed_attempts: number
          id: string
          is_active: boolean
          last_active_at: string
          locked_until: string | null
          paired_at: string
          tenant_id: string
          unpair_code: string | null
        }
        Insert: {
          device_name: string
          device_sl?: number | null
          device_token: string
          failed_attempts?: number
          id?: string
          is_active?: boolean
          last_active_at?: string
          locked_until?: string | null
          paired_at?: string
          tenant_id: string
          unpair_code?: string | null
        }
        Update: {
          device_name?: string
          device_sl?: number | null
          device_token?: string
          failed_attempts?: number
          id?: string
          is_active?: boolean
          last_active_at?: string
          locked_until?: string | null
          paired_at?: string
          tenant_id?: string
          unpair_code?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "paired_devices_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      salary_payouts: {
        Row: {
          amount: number
          business_day_id: string | null
          created_at: string
          id: string
          notes: string | null
          payment_mode: string
          staff_id: string
          tenant_id: string
        }
        Insert: {
          amount: number
          business_day_id?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          payment_mode?: string
          staff_id: string
          tenant_id: string
        }
        Update: {
          amount?: number
          business_day_id?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          payment_mode?: string
          staff_id?: string
          tenant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "salary_payouts_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "salary_payouts_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "salary_payouts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      shifts: {
        Row: {
          created_at: string
          end_time: string
          id: string
          is_active: boolean
          name: string
          start_time: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          end_time: string
          id?: string
          is_active?: boolean
          name: string
          start_time: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          end_time?: string
          id?: string
          is_active?: boolean
          name?: string
          start_time?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shifts_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_attendance: {
        Row: {
          business_day_id: string | null
          created_at: string
          id: string
          shift_id: string | null
          staff_id: string
          status: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          business_day_id?: string | null
          created_at?: string
          id?: string
          shift_id?: string | null
          staff_id: string
          status: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          business_day_id?: string | null
          created_at?: string
          id?: string
          shift_id?: string | null
          staff_id?: string
          status?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_attendance_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_attendance_shift_id_fkey"
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_attendance_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "staff_members"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_attendance_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_members: {
        Row: {
          allow_terminal_login: boolean
          created_at: string
          full_name: string
          hashed_pin: string | null
          id: string
          is_active: boolean
          phone: string
          staff_role_id: string
          temp_pin: string | null
          tenant_id: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          allow_terminal_login?: boolean
          created_at?: string
          full_name: string
          hashed_pin?: string | null
          id?: string
          is_active?: boolean
          phone: string
          staff_role_id: string
          temp_pin?: string | null
          tenant_id: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          allow_terminal_login?: boolean
          created_at?: string
          full_name?: string
          hashed_pin?: string | null
          id?: string
          is_active?: boolean
          phone?: string
          staff_role_id?: string
          temp_pin?: string | null
          tenant_id?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "staff_members_staff_role_id_fkey"
            columns: ["staff_role_id"]
            isOneToOne: false
            referencedRelation: "staff_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "staff_members_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      staff_roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_system_role: boolean
          name: string
          permissions: Json
          tenant_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name: string
          permissions?: Json
          tenant_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name?: string
          permissions?: Json
          tenant_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "staff_roles_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenant_billing: {
        Row: {
          created_at: string
          current_period_end: string | null
          status: string
          stripe_customer_id: string | null
          stripe_subscription_id: string | null
          subscription_tier: string
          tenant_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          current_period_end?: string | null
          status?: string
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_tier?: string
          tenant_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          current_period_end?: string | null
          status?: string
          stripe_customer_id?: string | null
          stripe_subscription_id?: string | null
          subscription_tier?: string
          tenant_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_billing_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: true
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenant_invitations: {
        Row: {
          created_at: string
          email: string
          expires_at: string
          id: string
          invited_by: string
          role_id: string
          status: string
          tenant_id: string
          token: string
        }
        Insert: {
          created_at?: string
          email: string
          expires_at: string
          id?: string
          invited_by: string
          role_id: string
          status?: string
          tenant_id: string
          token: string
        }
        Update: {
          created_at?: string
          email?: string
          expires_at?: string
          id?: string
          invited_by?: string
          role_id?: string
          status?: string
          tenant_id?: string
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_invitations_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "tenant_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tenant_invitations_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenant_members: {
        Row: {
          id: string
          joined_at: string
          role_id: string
          status: string
          tenant_id: string
          user_id: string
        }
        Insert: {
          id?: string
          joined_at?: string
          role_id: string
          status?: string
          tenant_id: string
          user_id: string
        }
        Update: {
          id?: string
          joined_at?: string
          role_id?: string
          status?: string
          tenant_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_members_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "tenant_roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tenant_members_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenant_roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_system_role: boolean
          name: string
          permissions: Json
          tenant_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name: string
          permissions?: Json
          tenant_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_system_role?: boolean
          name?: string
          permissions?: Json
          tenant_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_roles_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenant_settings: {
        Row: {
          created_at: string
          enabled_features: Json
          logo_url: string | null
          preferences: Json
          tenant_id: string
          theme_color: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          enabled_features?: Json
          logo_url?: string | null
          preferences?: Json
          tenant_id: string
          theme_color?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          enabled_features?: Json
          logo_url?: string | null
          preferences?: Json
          tenant_id?: string
          theme_color?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenant_settings_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: true
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      tenants: {
        Row: {
          created_at: string
          id: string
          name: string
          parent_id: string | null
          slug: string
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          parent_id?: string | null
          slug: string
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          parent_id?: string | null
          slug?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "tenants_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          full_name: string
          id: string
          is_superadmin: boolean
          preferences: Json
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          full_name: string
          id: string
          is_superadmin?: boolean
          preferences?: Json
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          full_name?: string
          id?: string
          is_superadmin?: boolean
          preferences?: Json
          updated_at?: string
        }
        Relationships: []
      }
      wallet_entries: {
        Row: {
          amount: number
          business_day_id: string | null
          created_at: string
          id: string
          notes: string | null
          reference_id: string | null
          reference_type: string | null
          shift_id: string | null
          tenant_id: string
          type: string
          wallet_id: string
        }
        Insert: {
          amount: number
          business_day_id?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          shift_id?: string | null
          tenant_id: string
          type: string
          wallet_id: string
        }
        Update: {
          amount?: number
          business_day_id?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          reference_id?: string | null
          reference_type?: string | null
          shift_id?: string | null
          tenant_id?: string
          type?: string
          wallet_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "wallet_entries_business_day_id_fkey"
            columns: ["business_day_id"]
            isOneToOne: false
            referencedRelation: "business_days"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_entries_shift_id_fkey"
            columns: ["shift_id"]
            isOneToOne: false
            referencedRelation: "shifts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_entries_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "wallet_entries_wallet_id_fkey"
            columns: ["wallet_id"]
            isOneToOne: false
            referencedRelation: "customer_wallets"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_invitation: { Args: { p_token: string }; Returns: string }
      admin_assign_tenant_owner: {
        Args: { p_tenant_id: string; p_user_id: string }
        Returns: undefined
      }
      admin_create_tenant: {
        Args: {
          p_enabled_features?: Json
          p_name: string
          p_owner_email: string
          p_owner_id?: string
          p_parent_id?: string
          p_slug: string
          p_subscription_tier?: string
        }
        Returns: string
      }
      admin_toggle_tenant_features: {
        Args: { p_features: Json; p_tenant_id: string }
        Returns: undefined
      }
      admin_update_billing: {
        Args: { p_status: string; p_tenant_id: string; p_tier: string }
        Returns: undefined
      }
      assert_kiosk_staff: {
        Args: {
          p_device_token: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: undefined
      }
      calculate_expected_cash: { Args: { p_day_id: string }; Returns: number }
      claim_pending_invitations: { Args: never; Returns: number }
      create_tenant: {
        Args: { p_name: string; p_slug: string }
        Returns: string
      }
      create_terminal_customer: {
        Args: {
          p_contract_daily_rate?: number
          p_factory_unit?: string
          p_full_name: string
          p_phone?: string
          p_tenant_id: string
        }
        Returns: Json
      }
      delete_own_account: { Args: never; Returns: undefined }
      edit_pos_sale: {
        Args: {
          p_amount: number
          p_device_token: string
          p_ledger_id: string
          p_notes?: string
          p_payment_method: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: string
      }
      end_business_day: {
        Args: {
          p_closing_cash: number
          p_day_id: string
          p_device_token: string
          p_notes?: string
          p_staff_id: string
        }
        Returns: {
          expected_cash: number
          status: string
          variance: number
        }[]
      }
      generate_pairing_code: {
        Args: { p_device_name: string; p_tenant_id: string }
        Returns: string
      }
      get_active_business_day: {
        Args: { p_tenant_id: string }
        Returns: string
      }
      get_cash_register_running_balance: {
        Args: { p_day_id: string; p_tenant_id: string }
        Returns: number
      }
      get_cash_register_running_balance_kiosk: {
        Args: {
          p_day_id: string
          p_device_token: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: number
      }
      get_current_shift: { Args: { p_tenant_id: string }; Returns: string }
      get_customer_statement_kiosk:
        | {
            Args: {
              p_customer_id: string
              p_days_count?: number
              p_device_token?: string
              p_staff_id?: string
              p_tenant_id: string
            }
            Returns: {
              amount: number
              description: string
              event_date: string
              event_type: string
              method: string
              notes: string
              session_id: string
              unique_id: string
            }[]
          }
        | {
            Args: {
              p_customer_id: string
              p_days_count?: number
              p_device_token: string
              p_staff_id: string
              p_tenant_id: string
            }
            Returns: {
              amount: number
              description: string
              event_date: string
              event_type: string
              method: string
              notes: string
              session_id: string
              unique_id: string
            }[]
          }
      get_daily_financial_breakdown: {
        Args: { p_end_date: string; p_start_date: string; p_tenant_id: string }
        Returns: {
          bazar_discrepancies: number
          bazar_surpluses: number
          debt_collections: number
          manual_inflows: number
          manual_outflows: number
          net_profit: number
          overhead_expenses: number
          payroll_expenses: number
          pos_sales: number
          raw_materials: number
          staff_advances: number
          supplier_payouts: number
          total_inflow: number
          total_outflow: number
          transaction_date: string
        }[]
      }
      get_day_read_scope: { Args: { p_tenant_id: string }; Returns: string }
      get_enabled_features: {
        Args: { p_device_token: string; p_tenant_id: string }
        Returns: Json
      }
      get_financial_summary: {
        Args: { p_end_date: string; p_start_date: string; p_tenant_id: string }
        Returns: {
          net_cash_flow: number
          net_profit_loss: number
          total_canteen_expenses: number
          total_customer_payments: number
          total_market_cost: number
          total_meal_billed: number
          total_salary_outflow: number
        }[]
      }
      get_next_device_sl: { Args: { p_tenant_id: string }; Returns: number }
      get_open_session: {
        Args: { p_device_token: string; p_tenant_id: string }
        Returns: Json
      }
      get_or_create_staff_role: {
        Args: { p_role_name: string; p_tenant_id: string }
        Returns: string
      }
      get_paired_device_staff: {
        Args: { p_device_token: string; p_tenant_id: string }
        Returns: {
          full_name: string
          id: string
          role: string
        }[]
      }
      get_pos_edit_window: {
        Args: { p_device_token?: string; p_tenant_id: string }
        Returns: Json
      }
      get_selected_tenant_id: { Args: never; Returns: string }
      get_tenant_financial_summary: {
        Args: { p_end_date: string; p_start_date: string; p_tenant_id: string }
        Returns: {
          cash_sales_pos: number
          market_expenses: number
          net_profit_loss: number
          outstanding_payables: number
          outstanding_receivables: number
          payroll_expenses: number
          total_inflow: number
          total_outflow: number
        }[]
      }
      get_terminal_customers: {
        Args: { p_tenant_id: string }
        Returns: {
          category: string | null
          contract_daily_rate: number | null
          contract_shifts: string[] | null
          created_at: string
          factory_unit: string | null
          full_name: string
          id: string
          is_active: boolean
          outstanding_balance: number
          phone: string
          tenant_id: string
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "customers"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      has_module_permission: {
        Args: {
          p_module_name: string
          p_permission_name: string
          p_tenant_id: string
        }
        Returns: boolean
      }
      has_staff_permission: {
        Args: {
          p_module_name: string
          p_permission_name: string
          p_staff_id: string
        }
        Returns: boolean
      }
      invite_user: {
        Args: { p_email: string; p_role_id: string; p_tenant_id: string }
        Returns: string
      }
      is_superadmin: { Args: never; Returns: boolean }
      is_tenant_member: { Args: { p_tenant_id: string }; Returns: boolean }
      is_tenant_owner: { Args: { p_tenant_id: string }; Returns: boolean }
      list_active_shifts: {
        Args: { p_device_token: string; p_tenant_id: string }
        Returns: {
          end_time: string
          id: string
          name: string
          start_time: string
        }[]
      }
      list_customers: {
        Args: {
          p_active_only?: boolean
          p_device_token: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: {
          category: string | null
          contract_daily_rate: number | null
          contract_shifts: string[] | null
          created_at: string
          factory_unit: string | null
          full_name: string
          id: string
          is_active: boolean
          outstanding_balance: number
          phone: string
          tenant_id: string
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "customers"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      list_session_baki_transactions: {
        Args: {
          p_device_token: string
          p_session_id: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: {
          amount: number
          created_at: string
          customer_id: string
          customer_name: string
          id: string
          items_description: string
          staff_name: string
        }[]
      }
      log_manual_ledger_entry: {
        Args: {
          p_amount: number
          p_category: string
          p_notes?: string
          p_payment_method: string
          p_session_id: string
          p_tenant_id: string
          p_type: string
        }
        Returns: string
      }
      log_pos_sale: {
        Args: {
          p_amount: number
          p_device_token: string
          p_notes?: string
          p_payment_method: string
          p_staff_id: string
          p_tenant_id: string
        }
        Returns: string
      }
      pos_edit_window_interval: {
        Args: { p_tenant_id: string }
        Returns: string
      }
      post_ledger_entry: {
        Args: {
          p_amount: number
          p_business_day_id: string
          p_category: string
          p_notes?: string
          p_operator_staff_id?: string
          p_operator_user_id?: string
          p_payment_method: string
          p_shift_id?: string
          p_tenant_id: string
          p_type: string
        }
        Returns: string
      }
      prepare_device_repair: {
        Args: { p_device_id: string; p_tenant_id: string }
        Returns: string
      }
      record_baki_transaction: {
        Args: {
          p_amount: number
          p_customer_id: string
          p_device_token?: string
          p_items_description: string
          p_staff_id?: string
          p_tenant_id: string
        }
        Returns: number
      }
      record_customer_collection: {
        Args: {
          p_amount: number
          p_customer_id: string
          p_device_token?: string
          p_notes?: string
          p_payment_method: string
          p_staff_id?: string
          p_tenant_id: string
        }
        Returns: number
      }
      reset_staff_pin: { Args: { p_staff_id: string }; Returns: string }
      resume_business_day: {
        Args: { p_day_id: string; p_device_token: string; p_staff_id: string }
        Returns: undefined
      }
      set_staff_pin:
        | {
            Args: {
              p_device_token: string
              p_new_pin: string
              p_staff_id: string
              p_temp_pin: string
              p_tenant_id: string
            }
            Returns: boolean
          }
        | {
            Args: { p_new_pin: string; p_staff_id: string; p_temp_pin: string }
            Returns: boolean
          }
      start_business_day: {
        Args: {
          p_device_token: string
          p_opening_cash: number
          p_staff_id: string
        }
        Returns: string
      }
      toggle_contract_attendance: {
        Args: {
          p_customer_id: string
          p_device_token?: string
          p_staff_id?: string
          p_tenant_id: string
        }
        Returns: {
          action_taken: string
          new_balance: number
        }[]
      }
      unpair_device: {
        Args: { p_device_token: string; p_tenant_id?: string }
        Returns: boolean
      }
      unpair_device_with_code: {
        Args: { p_device_token: string; p_unpair_code: string }
        Returns: Json
      }
      upsert_customer: {
        Args: {
          p_category?: string
          p_contract_daily_rate?: number
          p_contract_shifts?: string[]
          p_device_token?: string
          p_factory_unit?: string
          p_full_name: string
          p_id?: string
          p_is_active?: boolean
          p_phone?: string
          p_staff_id?: string
          p_tenant_id: string
        }
        Returns: {
          category: string | null
          contract_daily_rate: number | null
          contract_shifts: string[] | null
          created_at: string
          factory_unit: string | null
          full_name: string
          id: string
          is_active: boolean
          outstanding_balance: number
          phone: string
          tenant_id: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "customers"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      verify_pairing_code: {
        Args: { p_code: string; p_device_name: string }
        Returns: Json
      }
      verify_staff_pin:
        | {
            Args: { p_device_token: string; p_pin: string; p_tenant_id: string }
            Returns: Json
          }
        | { Args: { p_pin: string; p_tenant_id: string }; Returns: Json }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const
