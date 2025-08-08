import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://lyyttxtfffyzfcifcldf.supabase.co/',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eXR0eHRmZmZ5emZjaWZjbGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjIwMTcsImV4cCI6MjA2ODgzODAxN30.oCzbljhK0T1yNDu4iTRjIAkArKbqYhGWP9chNyS-lqo',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
