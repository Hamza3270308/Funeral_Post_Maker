import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Welcome to Funeral Post Maker. By using our mobile application, you agree to these Terms of Service. Our application provides customizable templates for creating memorial and remembrance posts to honor loved ones.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textGray,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Privacy & Data Security',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 12),
              Text(
                'We respect your privacy and the dignity of your cherished memories:\n\n'
                '1. Local Processing: Photos and custom texts you edit are processed locally on your device for fast, private rendering.\n'
                '2. Secure Sharing: When sharing via WhatsApp or email, images are exported directly from your device.\n'
                '3. No Unauthorized Sharing: We never share, sell, or distribute your personal memorial images or information to third parties.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textGray,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Respectful Use Policy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Users agree to use Funeral Post Maker in a respectful, lawful manner that honors the memory of the departed.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppTheme.textGray,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
