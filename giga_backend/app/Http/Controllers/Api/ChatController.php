<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    public function index(Request $request, $deliveryId)
    {
        $delivery = Delivery::findOrFail($deliveryId);
        
        // Ensure user is part of this delivery
        if ($delivery->customer_id != Auth::id() && 
            (!$delivery->rider || $delivery->rider->user_id != Auth::id())) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $messages = Message::where('delivery_id', $deliveryId)
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($messages);
    }

    public function store(Request $request, $deliveryId)
    {
        $delivery = Delivery::findOrFail($deliveryId);

        $validator = Validator::make($request->all(), [
            'content' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $message = Message::create([
            'delivery_id' => $deliveryId,
            'sender_id' => Auth::id(),
            'content' => $request->content,
        ]);

        return response()->json($message->load('sender'), 201);
    }
}
