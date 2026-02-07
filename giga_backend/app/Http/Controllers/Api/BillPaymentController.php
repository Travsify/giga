<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\FlutterwaveBillService;
use App\Services\SecurityNotificationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class BillPaymentController extends Controller
{
    protected FlutterwaveBillService $billService;
    protected SecurityNotificationService $notifications;

    public function __construct(FlutterwaveBillService $billService, SecurityNotificationService $notifications)
    {
        $this->billService = $billService;
        $this->notifications = $notifications;
    }

    /**
     * Get all bill categories.
     */
    public function getCategories()
    {
        $categories = $this->billService->getBillCategories();
        return response()->json(['data' => $categories]);
    }

    /**
     * Validate a customer/meter number for a specific bill item.
     */
    public function validateCustomer(Request $request)
    {
        $request->validate([
            'item_code' => 'required|string',
            'code' => 'required|string', // The specific Biller Code
            'customer' => 'required|string', // The Customer ID / Smartcard Number
        ]);

        $result = $this->billService->validateBillService(
            $request->item_code,
            $request->code,
            $request->customer
        );

        if ($result['success']) {
            return response()->json(['status' => 'success', 'data' => $result['data']]);
        }

        return response()->json(['status' => 'error', 'message' => $result['message']], 400);
    }

    /**
     * Process a bill payment.
     */
    public function pay(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'type' => 'required|string', // Biller Type (e.g. DSTV)
            'customer' => 'required|string', // Smartcard/Phone
            'country' => 'nullable|string|in:NG,GH,KE,ZA',
            'biller_name' => 'nullable|string', // For description
        ]);

        try {
            return DB::transaction(function () use ($request) {
                $user = $request->user();
                $wallet = $user->wallet;
                $amount = $request->amount;

                if (!$wallet) {
                    return response()->json(['error' => 'Wallet not found'], 404);
                }

                // Balance check
                if ($wallet->balance < $amount) {
                    return response()->json(['error' => 'Insufficient funds'], 400);
                }

                // Deduct from wallet first (Optimistic locking)
                $wallet->balance -= $amount;
                $wallet->save();

                $reference = 'BILL_' . time() . '_' . $user->id;

                // Call Flutterwave
                $result = $this->billService->payBill([
                    'country' => $request->country ?? 'NG',
                    'customer' => $request->customer,
                    'amount' => $amount,
                    'type' => $request->type,
                    'reference' => $reference,
                ]);

                if (!$result['success']) {
                    // Refund wallet if API call fails
                    $wallet->balance += $amount;
                    $wallet->save();
                    return response()->json(['error' => $result['message']], 400);
                }

                // Record Transaction
                $transaction = $wallet->transactions()->create([
                    'amount' => -$amount,
                    'type' => 'debit',
                    'description' => 'Bill Payment: ' . ($request->biller_name ?? $request->type) . ' (' . $request->customer . ')',
                    'reference' => $reference,
                    'status' => 'completed',
                    'currency' => $wallet->currency,
                    'category' => 'bill_payment',
                    'meta' => [
                        'customer' => $request->customer,
                        'biller_type' => $request->type,
                        'flw_ref' => $result['data']['tx_ref'] ?? null,
                    ]
                ]);

                // Send Notification
                $this->notifications->notifyTransaction($transaction);

                return response()->json([
                    'status' => 'success',
                    'message' => 'Bill payment successful',
                    'data' => $result['data'],
                    'balance' => $wallet->balance
                ]);
            });

        } catch (\Exception $e) {
            Log::error('Bill Payment Controller Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to process bill payment'], 500);
        }
    }
}
