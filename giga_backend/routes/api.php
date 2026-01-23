<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeliveryController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\ProfileController;


// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Payment (Public for Demo)
Route::post('/create-payment-intent-public', [App\Http\Controllers\Api\PaymentController::class, 'createPaymentIntentPublic']);
Route::get('/diag', [App\Http\Controllers\Api\PaymentController::class, 'diag']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Deliveries
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

    // Subscriptions
    Route::get('/subscription/status', [App\Http\Controllers\Api\SubscriptionController::class, 'status']);
    Route::post('/subscription/subscribe', [App\Http\Controllers\Api\SubscriptionController::class, 'subscribe']);
    Route::post('/subscription/cancel', [App\Http\Controllers\Api\SubscriptionController::class, 'cancel']);
});
