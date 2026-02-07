<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class VehicleController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $rider = $request->user()->rider;
        if (!$rider) {
            return response()->json(['message' => 'Rider profile not found'], 404);
        }

        $vehicles = $rider->vehicles()->orderBy('created_at', 'desc')->get();

        return response()->json([
            'data' => $vehicles,
            'active_vehicle_id' => $rider->active_vehicle_id
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'vehicle_type' => 'required|string',
            'vehicle_plate_number' => 'required|string', // Unique validation scoped to rider? Or global? Probably global per country but let's keep it simple for now.
            'make' => 'nullable|string',
            'model' => 'nullable|string',
            'color' => 'nullable|string',
            'year' => 'nullable|string',
        ]);

        $rider = $request->user()->rider;
        if (!$rider) {
            return response()->json(['message' => 'Rider profile not found'], 404);
        }

        $vehicle = $rider->vehicles()->create([
            'vehicle_type' => $request->vehicle_type,
            'vehicle_plate_number' => $request->vehicle_plate_number,
            'make' => $request->make,
            'model' => $request->model,
            'color' => $request->color,
            'year' => $request->year,
            'verification_status' => 'pending',
            'is_verified' => false,
        ]);

        // If this is the only vehicle, make it active
        if ($rider->vehicles()->count() === 1) {
            $this->activateVehicle($rider, $vehicle);
        }

        return response()->json(['message' => 'Vehicle added successfully', 'data' => $vehicle], 201);
    }

    /**
     * Activate a specific vehicle.
     */
    public function activate(Request $request, string $id)
    {
        $rider = $request->user()->rider;
        if (!$rider) {
            return response()->json(['message' => 'Rider profile not found'], 404);
        }

        $vehicle = $rider->vehicles()->where('id', $id)->first();
        if (!$vehicle) {
            return response()->json(['message' => 'Vehicle not found'], 404);
        }

        $this->activateVehicle($rider, $vehicle);

        return response()->json(['message' => 'Vehicle activated successfully', 'data' => $vehicle]);
    }

    /**
     * Helper to activate vehicle and sync legacy columns.
     */
    private function activateVehicle($rider, $vehicle)
    {
        $rider->active_vehicle_id = $vehicle->id;
        
        // Sync legacy columns for backward compatibility
        $rider->vehicle_type = $vehicle->vehicle_type;
        $rider->vehicle_plate_number = $vehicle->vehicle_plate_number;
        $rider->vehicle_verified = $vehicle->is_verified;
        $rider->verification_status = $vehicle->verification_status; // Should we sync this? Maybe. Rider status is composite but let's sync for now.
        
        // Sync document paths
        $rider->vehicle_front_path = $vehicle->vehicle_front_path;
        $rider->vehicle_side_path = $vehicle->vehicle_side_path;
        $rider->vehicle_interior_path = $vehicle->vehicle_interior_path;
        $rider->vehicle_license_path = $vehicle->vehicle_license_path;
        $rider->vehicle_registration_path = $vehicle->vehicle_registration_path;
        $rider->insurance_certificate_path = $vehicle->insurance_certificate_path;

        $rider->save();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, string $id)
    {
        $rider = $request->user()->rider;
        if (!$rider) {
            return response()->json(['message' => 'Rider profile not found'], 404);
        }

        $vehicle = $rider->vehicles()->where('id', $id)->first();
        if (!$vehicle) {
            return response()->json(['message' => 'Vehicle not found'], 404);
        }

        if ($rider->active_vehicle_id == $vehicle->id) {
            return response()->json(['message' => 'Cannot delete active vehicle. Please switch to another vehicle first.'], 400);
        }

        $vehicle->delete();

        return response()->json(['message' => 'Vehicle deleted successfully']);
    }
}
