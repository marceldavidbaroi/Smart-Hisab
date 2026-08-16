class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ragbgcqewutilfsiuief.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhZ2JnY3Fld3V0aWxmc2l1aWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MTU5MzMsImV4cCI6MjA5OTQ5MTkzM30.j-Psn4256HLVlvHsNCiHORnwY2-5SvcIDHLChvVcXWs',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
