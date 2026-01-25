<?php

namespace Database\Seeders;

use App\Models\AppSetting;
use Illuminate\Database\Seeder;

class AppSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            // ========================
            // APP CONFIGURATION
            // ========================
            ['group' => 'app', 'key' => 'app_name', 'value' => 'Giga', 'type' => 'string', 'label' => 'App Name', 'is_public' => true],
            ['group' => 'app', 'key' => 'app_tagline', 'value' => 'Fast. Reliable. Delivery.', 'type' => 'string', 'label' => 'App Tagline', 'is_public' => true],
            ['group' => 'app', 'key' => 'app_version', 'value' => '1.0.0', 'type' => 'string', 'label' => 'Current App Version', 'is_public' => true],
            ['group' => 'app', 'key' => 'min_app_version', 'value' => '1.0.0', 'type' => 'string', 'label' => 'Minimum Required Version', 'is_public' => true, 'description' => 'Force users to update if below this version'],
            ['group' => 'app', 'key' => 'maintenance_mode', 'value' => '0', 'type' => 'boolean', 'label' => 'Maintenance Mode', 'is_public' => true],
            ['group' => 'app', 'key' => 'maintenance_message', 'value' => 'We are currently performing maintenance. Please check back soon.', 'type' => 'string', 'label' => 'Maintenance Message', 'is_public' => true],
            ['group' => 'app', 'key' => 'splash_image_url', 'value' => '', 'type' => 'string', 'label' => 'Splash Screen Image URL', 'is_public' => true],
            ['group' => 'app', 'key' => 'splash_duration_ms', 'value' => '2000', 'type' => 'integer', 'label' => 'Splash Duration (ms)', 'is_public' => true],
            ['group' => 'app', 'key' => 'onboarding_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Show Onboarding', 'is_public' => true],
            ['group' => 'app', 'key' => 'onboarding_slides', 'value' => json_encode([
                ['title' => 'Fast Delivery', 'description' => 'Get your packages delivered in record time', 'image' => ''],
                ['title' => 'Track Live', 'description' => 'Real-time tracking of your deliveries', 'image' => ''],
                ['title' => 'Safe & Secure', 'description' => 'Your packages are in safe hands', 'image' => ''],
            ]), 'type' => 'json', 'label' => 'Onboarding Slides', 'is_public' => true],

            // ========================
            // AUTHENTICATION
            // ========================
            ['group' => 'auth', 'key' => 'email_verification_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Email Verification Required'],
            ['group' => 'auth', 'key' => 'phone_verification_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Phone Verification Required'],
            ['group' => 'auth', 'key' => 'sms_provider', 'value' => 'log', 'type' => 'string', 'label' => 'SMS Provider', 'description' => 'twilio, vonage, termii, messagebird, log'],
            ['group' => 'auth', 'key' => 'twilio_sid', 'value' => '', 'type' => 'string', 'label' => 'Twilio SID', 'is_sensitive' => true],
            ['group' => 'auth', 'key' => 'twilio_token', 'value' => '', 'type' => 'string', 'label' => 'Twilio Auth Token', 'is_sensitive' => true],
            ['group' => 'auth', 'key' => 'twilio_from', 'value' => '', 'type' => 'string', 'label' => 'Twilio From Number'],
            ['group' => 'auth', 'key' => 'termii_api_key', 'value' => '', 'type' => 'string', 'label' => 'Termii API Key', 'is_sensitive' => true],
            ['group' => 'auth', 'key' => 'termii_sender_id', 'value' => 'Giga', 'type' => 'string', 'label' => 'Termii Sender ID'],
            ['group' => 'auth', 'key' => 'google_auth_enabled', 'value' => '0', 'type' => 'boolean', 'label' => 'Google Sign-In Enabled', 'is_public' => true],
            ['group' => 'auth', 'key' => 'apple_auth_enabled', 'value' => '0', 'type' => 'boolean', 'label' => 'Apple Sign-In Enabled', 'is_public' => true],

            // ========================
            // EMAIL
            // ========================
            ['group' => 'email', 'key' => 'mail_mailer', 'value' => 'smtp', 'type' => 'string', 'label' => 'Mail Driver', 'description' => 'smtp, mailgun, ses, postmark'],
            ['group' => 'email', 'key' => 'mail_host', 'value' => 'smtp.mailgun.org', 'type' => 'string', 'label' => 'SMTP Host'],
            ['group' => 'email', 'key' => 'mail_port', 'value' => '587', 'type' => 'integer', 'label' => 'SMTP Port'],
            ['group' => 'email', 'key' => 'mail_username', 'value' => '', 'type' => 'string', 'label' => 'SMTP Username', 'is_sensitive' => true],
            ['group' => 'email', 'key' => 'mail_password', 'value' => '', 'type' => 'string', 'label' => 'SMTP Password', 'is_sensitive' => true],
            ['group' => 'email', 'key' => 'mail_from_address', 'value' => 'hello@giga.com', 'type' => 'string', 'label' => 'From Email Address'],
            ['group' => 'email', 'key' => 'mail_from_name', 'value' => 'Giga', 'type' => 'string', 'label' => 'From Name'],

            // ========================
            // PAYMENTS
            // ========================
            ['group' => 'payment', 'key' => 'currency', 'value' => 'GBP', 'type' => 'string', 'label' => 'Default Currency', 'is_public' => true],
            ['group' => 'payment', 'key' => 'currency_symbol', 'value' => '£', 'type' => 'string', 'label' => 'Currency Symbol', 'is_public' => true],
            ['group' => 'payment', 'key' => 'stripe_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Stripe Enabled', 'is_public' => true],
            ['group' => 'payment', 'key' => 'stripe_public_key', 'value' => '', 'type' => 'string', 'label' => 'Stripe Publishable Key', 'is_public' => true],
            ['group' => 'payment', 'key' => 'stripe_secret_key', 'value' => '', 'type' => 'string', 'label' => 'Stripe Secret Key', 'is_sensitive' => true],
            ['group' => 'payment', 'key' => 'stripe_webhook_secret', 'value' => '', 'type' => 'string', 'label' => 'Stripe Webhook Secret', 'is_sensitive' => true],
            ['group' => 'payment', 'key' => 'paypal_enabled', 'value' => '0', 'type' => 'boolean', 'label' => 'PayPal Enabled', 'is_public' => true],
            ['group' => 'payment', 'key' => 'paypal_client_id', 'value' => '', 'type' => 'string', 'label' => 'PayPal Client ID', 'is_public' => true],
            ['group' => 'payment', 'key' => 'paypal_secret', 'value' => '', 'type' => 'string', 'label' => 'PayPal Secret', 'is_sensitive' => true],
            ['group' => 'payment', 'key' => 'wallet_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'In-App Wallet Enabled', 'is_public' => true],
            ['group' => 'payment', 'key' => 'cod_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Cash on Delivery Enabled', 'is_public' => true],

            // ========================
            // NOTIFICATIONS
            // ========================
            ['group' => 'notification', 'key' => 'fcm_enabled', 'value' => '1', 'type' => 'boolean', 'label' => 'Push Notifications Enabled'],
            ['group' => 'notification', 'key' => 'fcm_server_key', 'value' => '', 'type' => 'string', 'label' => 'Firebase Server Key', 'is_sensitive' => true],
            ['group' => 'notification', 'key' => 'delivery_notifications', 'value' => '1', 'type' => 'boolean', 'label' => 'Delivery Status Notifications', 'is_public' => true],
            ['group' => 'notification', 'key' => 'promo_notifications', 'value' => '1', 'type' => 'boolean', 'label' => 'Promotional Notifications', 'is_public' => true],
            ['group' => 'notification', 'key' => 'chat_notifications', 'value' => '1', 'type' => 'boolean', 'label' => 'Chat Message Notifications', 'is_public' => true],

            // ========================
            // CONTENT & LEGAL
            // ========================
            ['group' => 'content', 'key' => 'terms_url', 'value' => 'https://giga.com/terms', 'type' => 'string', 'label' => 'Terms & Conditions URL', 'is_public' => true],
            ['group' => 'content', 'key' => 'privacy_url', 'value' => 'https://giga.com/privacy', 'type' => 'string', 'label' => 'Privacy Policy URL', 'is_public' => true],
            ['group' => 'content', 'key' => 'support_email', 'value' => 'support@giga.com', 'type' => 'string', 'label' => 'Support Email', 'is_public' => true],
            ['group' => 'content', 'key' => 'support_phone', 'value' => '+44 123 456 7890', 'type' => 'string', 'label' => 'Support Phone', 'is_public' => true],
            ['group' => 'content', 'key' => 'about_us', 'value' => 'Giga is a next-generation logistics platform delivering packages faster and more reliably than ever before.', 'type' => 'string', 'label' => 'About Us', 'is_public' => true],
            ['group' => 'content', 'key' => 'faq_content', 'value' => json_encode([
                ['question' => 'How do I track my delivery?', 'answer' => 'Open the app and tap on your active delivery to see real-time tracking.'],
                ['question' => 'What are your delivery hours?', 'answer' => 'We deliver 7 days a week, from 8am to 10pm.'],
                ['question' => 'How do I become a rider?', 'answer' => 'Download the app, register as a rider, and complete the verification process.'],
            ]), 'type' => 'json', 'label' => 'FAQ Content', 'is_public' => true],

            // ========================
            // BRANDING
            // ========================
            ['group' => 'branding', 'key' => 'primary_color', 'value' => '#0047C1', 'type' => 'string', 'label' => 'Primary Color', 'is_public' => true],
            ['group' => 'branding', 'key' => 'secondary_color', 'value' => '#C1272D', 'type' => 'string', 'label' => 'Secondary Color', 'is_public' => true],
            ['group' => 'branding', 'key' => 'logo_url', 'value' => '', 'type' => 'string', 'label' => 'Logo URL', 'is_public' => true],
            ['group' => 'branding', 'key' => 'icon_url', 'value' => '', 'type' => 'string', 'label' => 'App Icon URL', 'is_public' => true],

            // ========================
            // OPERATIONS & PRICING
            // ========================
            ['group' => 'operations', 'key' => 'base_delivery_fee', 'value' => '3.50', 'type' => 'decimal', 'label' => 'Base Delivery Fee', 'is_public' => true],
            ['group' => 'operations', 'key' => 'price_per_km', 'value' => '0.50', 'type' => 'decimal', 'label' => 'Price Per KM', 'is_public' => true],
            ['group' => 'operations', 'key' => 'price_per_stop', 'value' => '1.00', 'type' => 'decimal', 'label' => 'Price Per Additional Stop', 'is_public' => true],
            ['group' => 'operations', 'key' => 'surge_multiplier', 'value' => '1.0', 'type' => 'decimal', 'label' => 'Surge Pricing Multiplier', 'is_public' => true],
            ['group' => 'operations', 'key' => 'surge_enabled', 'value' => '0', 'type' => 'boolean', 'label' => 'Surge Pricing Enabled', 'is_public' => true],
            ['group' => 'operations', 'key' => 'max_delivery_distance_km', 'value' => '50', 'type' => 'integer', 'label' => 'Max Delivery Distance (km)', 'is_public' => true],
            ['group' => 'operations', 'key' => 'rider_commission_percent', 'value' => '80', 'type' => 'integer', 'label' => 'Rider Commission %'],
            ['group' => 'operations', 'key' => 'service_areas', 'value' => json_encode([
                ['name' => 'London', 'lat' => 51.5074, 'lng' => -0.1278, 'radius_km' => 30],
                ['name' => 'Manchester', 'lat' => 53.4808, 'lng' => -2.2426, 'radius_km' => 20],
            ]), 'type' => 'json', 'label' => 'Service Areas', 'is_public' => true],
            ['group' => 'operations', 'key' => 'operating_hours_start', 'value' => '08:00', 'type' => 'string', 'label' => 'Operating Hours Start', 'is_public' => true],
            ['group' => 'operations', 'key' => 'operating_hours_end', 'value' => '22:00', 'type' => 'string', 'label' => 'Operating Hours End', 'is_public' => true],
        ];

        foreach ($settings as $setting) {
            AppSetting::updateOrCreate(
                ['key' => $setting['key']],
                $setting
            );
        }
    }
}
