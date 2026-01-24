<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ProfileController;

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

// Rate-limited auth routes (5 attempts per minute per IP)
Route::middleware('throttle:5,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLink']);
    Route::post('/reset-password', [PasswordResetController::class, 'reset']);
});

// Payment (Public for Demo)
Route::post('/create-payment-intent-public', [PaymentController::class, 'createPaymentIntentPublic']);
Route::get('/diag', [PaymentController::class, 'diag']);
Route::get('/test-mail', [TestMailController::class, 'sendTestMail']);
Route::get('/status', function() { return response()->json(['status' => 'online', 'version' => '1.1.0']); });

// Public Signup Verification
Route::post('/signup/verify-email/send', [EmailVerificationController::class, 'sendSignupCode']);
Route::post('/signup/verify-email/confirm', [EmailVerificationController::class, 'verifySignupCode']);


// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Email Verification
    Route::post('/email/send-verification', [EmailVerificationController::class, 'sendVerificationCode']);
    Route::post('/email/verify', [EmailVerificationController::class, 'verifyCode']);
    Route::post('/email/resend', [EmailVerificationController::class, 'resendCode']);

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
