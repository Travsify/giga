<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\NotificationController;

use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TestMailController;
use App\Http\Controllers\Api\EmailVerificationController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\BulkBookingController;
use App\Http\Controllers\Api\PromoController;
use App\Http\Controllers\Api\LockerController;
use App\Http\Controllers\Api\SustainabilityController;
use App\Http\Controllers\Api\SettingsController;
use App\Http\Controllers\Api\CurrencyController;

// Rate-limited auth routes (5 attempts per minute per IP)
Route::middleware('throttle:5,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLink']);
    Route::post('/reset-password', [PasswordResetController::class, 'reset']);
});

// App Settings (Public - no auth required)
Route::get('/settings', [SettingsController::class, 'index']);
Route::get('/settings/check-version/{version}', [SettingsController::class, 'checkVersion']);
Route::get('/countries', [App\Http\Controllers\Api\SettingsController::class, 'getCountries']);
Route::get('/currency-rates', [App\Http\Controllers\Api\SettingsController::class, 'getCurrencyRates']);
Route::get('/settings/payment', [App\Http\Controllers\Api\SettingsController::class, 'getPaymentConfig']);

// Payment (Public for Demo)
Route::post('/create-payment-intent-public', [PaymentController::class, 'createPaymentIntentPublic']);
Route::get('/diag', [PaymentController::class, 'diag']);
Route::get('/test-mail', [TestMailController::class, 'sendTestMail']);
Route::get('/currency-rates', [CurrencyController::class, 'getRates']);
Route::get('/currencies', [CurrencyController::class, 'index']);
Route::get('/status', function() { return response()->json(['status' => 'online', 'version' => '1.1.0']); });

// SECRET: One-time Admin Provisioning Endpoint (Delete after use!)
Route::get('/provision-admin-giga2026secret', function() {
    $user = \App\Models\User::updateOrCreate(
        ['email' => 'admin@giga.com'],
        [
            'name' => 'Super Admin',
            'password' => \Illuminate\Support\Facades\Hash::make('GigaAdmin2026!'),
            'role' => 'SuperAdmin',
            'email_verified_at' => now(),
        ]
    );
    return response()->json(['success' => true, 'message' => 'Admin provisioned', 'user_id' => $user->id]);
});

// Public Signup Verification
Route::post('/signup/verify-email/send', [EmailVerificationController::class, 'sendSignupCode']);
Route::post('/signup/verify-email/confirm', [EmailVerificationController::class, 'verifySignupCode']);
Route::post('/phone/send-otp', [App\Http\Controllers\Api\PhoneVerificationController::class, 'sendOtp']);
Route::post('/phone/verify-otp', [App\Http\Controllers\Api\PhoneVerificationController::class, 'verifyOtp']);


// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Email Verification
    Route::post('/email/send-verification', [EmailVerificationController::class, 'sendVerificationCode']);
    Route::post('/email/verify', [EmailVerificationController::class, 'verifyCode']);
    Route::post('/email/resend', [EmailVerificationController::class, 'resendCode']);

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);

    // Deliveries
    Route::get('/deliveries', [DeliveryController::class, 'index']);
    Route::post('/deliveries/estimate', [DeliveryController::class, 'estimateFare']);
    Route::post('/deliveries', [DeliveryController::class, 'create']);
    Route::post('/deliveries/{id}/proof', [DeliveryController::class, 'uploadProof']);
    Route::patch('/deliveries/{id}/status', [DeliveryController::class, 'updateStatus']);
    Route::get('/riders/nearby', [DeliveryController::class, 'getNearbyRiders']);

    // Chat
    Route::get('/deliveries/{id}/messages', [ChatController::class, 'index']);
    Route::post('/deliveries/{id}/messages', [ChatController::class, 'store']);

    // Profile & Loyalty
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::patch('/profile', [ProfileController::class, 'update']);
    Route::get('/loyalty', [ProfileController::class, 'loyaltyInfo']);
    Route::post('/referral/submit', [ProfileController::class, 'submitReferral']);

    // Payments
    Route::post('/create-payment-intent', [App\Http\Controllers\Api\PaymentController::class, 'createPaymentIntent']);
    Route::post('/payment/confirm', [App\Http\Controllers\Api\PaymentController::class, 'confirmPayment']);
    Route::post('/wallet/redeem', [App\Http\Controllers\Api\PaymentController::class, 'redeem']);
    Route::get('/wallet/transactions', [App\Http\Controllers\Api\PaymentController::class, 'getTransactions']);

    // Subscriptions
    Route::get('/subscription/status', [App\Http\Controllers\Api\SubscriptionController::class, 'status']);
    Route::post('/subscription/subscribe', [App\Http\Controllers\Api\SubscriptionController::class, 'subscribe']);
    Route::post('/subscription/cancel', [App\Http\Controllers\Api\SubscriptionController::class, 'cancel']);

    // Business (B2B)
    Route::post('/business/enroll', [BusinessController::class, 'enroll']);
    Route::get('/business/profile', [BusinessController::class, 'getProfile']);
    Route::get('/business/team', [BusinessController::class, 'getTeam']);
    Route::post('/business/invite', [BusinessController::class, 'inviteMember']);
    Route::get('/business/billing', [BusinessController::class, 'getBilling']);
    Route::get('/business/stats', [BusinessController::class, 'getStats']);
    Route::get('/business/activity', [BusinessController::class, 'getRecentActivity']);
    Route::post('/business/bulk-book', [BulkBookingController::class, 'processBatch']);
    
    // Placeholder for API Keys
    Route::post('/business/api-keys', function() { return response()->json(['token' => 'mock_token_' . time()]); });

    // Promos & Offers
    Route::get('/promos', [App\Http\Controllers\Api\PromoController::class, 'index']);
    Route::post('/promos/validate', [App\Http\Controllers\Api\PromoController::class, 'validateCode']);

    // Lockers
    Route::get('/lockers', [App\Http\Controllers\Api\LockerController::class, 'index']);
    Route::get('/lockers/{id}', [App\Http\Controllers\Api\LockerController::class, 'show']);

    // Sustainability / Carbon Impact
    Route::get('/sustainability/stats', [App\Http\Controllers\Api\SustainabilityController::class, 'getStats']);
});
