<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Services\ResendService; // Assuming this exists or using direct mail
use Illuminate\Support\Facades\DB;

class IncidentController extends Controller
{
    public function store(Request $request)
    {
        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'type' => 'required|string',
            'description' => 'required|string',
            'location_lat' => 'nullable|numeric',
            'location_lng' => 'nullable|numeric',
            'evidence' => 'nullable|array',
            'evidence.*' => 'file|max:10240', // Removed strict mime check for now
        ]);

        if ($validator->fails()) {
            Log::error('Incident Validation Failed: ' . json_encode($validator->errors()));
            return response()->json([
                'status' => 'error',
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = Auth::user();
            $evidencePaths = [];

            if ($request->hasFile('evidence')) {
                foreach ($request->file('evidence') as $file) {
                    $path = $file->store('incidents/' . $user->id, 'public');
                    $evidencePaths[] = $path;
                }
            }

            $incidentId = DB::table('incidents')->insertGetId([
                'user_id' => $user->id,
                'type' => $request->type,
                'description' => $request->description,
                'location_lat' => $request->location_lat,
                'location_lng' => $request->location_lng,
                'evidence_url' => !empty($evidencePaths) ? json_encode($evidencePaths) : null,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Send Email Alert
            try {
                $resendService = new \App\Services\ResendService();
                $resendService->sendEmail(
                    'admin@giga.com', 
                    'URGENT: New Safety Incident Reported',
                    "
                    <h1>New Incident Report</h1>
                    <p><strong>Rider:</strong> {$user->name} ({$user->email})</p>
                    <p><strong>Type:</strong> {$request->type}</p>
                    <p><strong>Description:</strong> {$request->description}</p>
                    <p><strong>Location:</strong> {$request->location_lat}, {$request->location_lng}</p>
                    <p><strong>Evidence:</strong> " . count($evidencePaths) . " files uploaded.</p>
                    <p><strong>Time:</strong> " . now()->toDateTimeString() . "</p>
                    "
                );
            } catch (\Exception $emailError) {
                Log::error('Failed to send incident alert email: ' . $emailError->getMessage());
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Incident reported successfully. Our safety team has been notified.',
                'incident_id' => $incidentId
            ], 201);

        } catch (\Exception $e) {
            Log::error('Incident Report Error: ' . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
