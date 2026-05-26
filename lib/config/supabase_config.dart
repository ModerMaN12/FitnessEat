class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://idpnrztaoprjhpscysio.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcG5yenRhb3Byamhwc2N5c2lvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2NjU2MTQsImV4cCI6MjA5NTI0MTYxNH0.eEGqvYtVJUbrT_pFEPPSYOT3WT2n-AFsaapkEtCd_qw',
  );
}
