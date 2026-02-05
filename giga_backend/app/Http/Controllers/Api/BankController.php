<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class BankController extends Controller
{
    /**
     * Display a listing of the rider's bank accounts.
     */
    public function index(Request $request)
    {
        $rider = $request->user()->rider;

        if (!$rider) {
            return response()->json(['error' => 'Rider not found'], 404);
        }

        $accounts = $rider->bankAccounts()->orderBy('is_active', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $accounts
        ]);
    }

    /**
     * Store a newly created bank account.
     */
    public function store(Request $request)
    {
        $rider = $request->user()->rider;

        if (!$rider) {
            return response()->json(['error' => 'Rider not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'account_name' => 'required|string',
            'account_number' => 'required|string',
            'bank_name' => 'required|string',
            'bank_code' => 'sometimes|string',
            'sort_code' => 'sometimes|string',
            'gateway_type' => 'required|in:flutterwave,stripe',
        ]);

        if ($validator->fails()) {
            \Illuminate\Support\Facades\Log::error('Bank Validation Failed', $validator->errors()->toArray());
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $account = $rider->bankAccounts()->create($request->all());

            return response()->json([
                'status' => 'success',
                'message' => 'Bank account added successfully',
                'data' => $account
            ], 201);
        } catch (\Exception $e) {
            Log::error('Add Bank Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to save account: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Update the specified bank account.
     */
    public function update(Request $request, $id)
    {
        $rider = $request->user()->rider;
        $account = $rider->bankAccounts()->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'account_name' => 'sometimes|string',
            'account_number' => 'sometimes|string',
            'bank_name' => 'sometimes|string',
            'bank_code' => 'sometimes|string',
            'sort_code' => 'sometimes|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $account->update($request->all());

        return response()->json([
            'status' => 'success',
            'message' => 'Bank account updated successfully',
            'data' => $account
        ]);
    }

    /**
     * Remove the specified bank account.
     */
    public function destroy(Request $request, $id)
    {
        $rider = $request->user()->rider;
        $account = $rider->bankAccounts()->findOrFail($id);

        $account->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Bank account removed successfully'
        ]);
    }

    /**
     * Get list of supported banks (for frontend selector).
     */
    public function getBanks(Request $request)
    {
        $country = $request->query('country', 'NG');
        \Illuminate\Support\Facades\Log::info('Fetching supported banks from Flutterwave', ['country' => $country]);
        
        $flw = new \App\Services\FlutterwaveTransferService();
        $banks = $flw->getBanks($country);

        if (empty($banks)) {
            \Illuminate\Support\Facades\Log::warning('Flutterwave returned empty bank list', ['country' => $country]);
        }

        return response()->json([
            'status' => 'success',
            'data' => $banks
        ]);
    }

    /**
     * Resolve a bank account name.
     */
    public function resolveAccount(Request $request)
    {
        $request->validate([
            'account_number' => 'required|string',
            'bank_code' => 'required|string',
        ]);

        \Illuminate\Support\Facades\Log::info('Resolving bank account', [
            'account' => $request->account_number,
            'bank_code' => $request->bank_code
        ]);

        $flw = new \App\Services\FlutterwaveTransferService();
        $result = $flw->resolveAccount($request->account_number, $request->bank_code);

        if ($result['success']) {
            return response()->json([
                'status' => 'success',
                'data' => $result['data']
            ]);
        }

        \Illuminate\Support\Facades\Log::error('Bank account resolution failed', ['message' => $result['message']]);

        return response()->json([
            'status' => 'error',
            'message' => $result['message']
        ], 400);
    }
}
