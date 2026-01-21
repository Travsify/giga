# Giga API Documentation

## Base URL

```
http://your-domain.com/api
```

## Authentication

All protected endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer {token}
```

## Endpoints

### Authentication

#### Register

```http
POST /register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "Customer" // Customer, Rider, or Company
}

Response: 201 Created
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "Customer"
  },
  "token": "1|abc123..."
}
```

#### Login

```http
POST /login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "user": { ... },
  "token": "2|xyz789..."
}
```

#### Logout

```http
POST /logout
Authorization: Bearer {token}

Response: 200 OK
{
  "message": "Logged out successfully"
}
```

#### Get Current User

```http
GET /me
Authorization: Bearer {token}

Response: 200 OK
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "Customer"
}
```

### Deliveries

#### Estimate Fare

```http
POST /deliveries/estimate
Authorization: Bearer {token}
Content-Type: application/json

{
  "pickup_lat": 6.5244,
  "pickup_lng": 3.3792,
  "dropoff_lat": 6.4281,
  "dropoff_lng": 3.4219,
  "service_type": "bike" // bike, van, or truck
}

Response: 200 OK
{
  "distance_km": 12.5,
  "estimated_fare": 1750.00,
  "service_type": "bike"
}
```

#### Create Delivery

```http
POST /deliveries
Authorization: Bearer {token}
Content-Type: application/json

{
  "parcel_type": "Documents",
  "description": "Important contracts",
  "pickup_address": "123 Main St, Lagos",
  "pickup_lat": 6.5244,
  "pickup_lng": 3.3792,
  "dropoff_address": "456 Oak Ave, Lagos",
  "dropoff_lat": 6.4281,
  "dropoff_lng": 3.4219,
  "fare": 1750.00
}

Response: 201 Created
{
  "id": 1,
  "customer_id": 1,
  "parcel_type": "Documents",
  "status": "pending",
  "fare": 1750.00,
  ...
}
```

#### Update Delivery Status

```http
PATCH /deliveries/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "picked_up" // pending, assigned, picked_up, in_transit, delivered, cancelled
}

Response: 200 OK
{
  "id": 1,
  "status": "picked_up",
  "picked_up_at": "2026-01-19T14:30:00Z",
  ...
}
```

#### Get Nearby Riders

```http
GET /riders/nearby?lat=6.5244&lng=3.3792&radius=5
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": 1,
    "user_id": 5,
    "vehicle_type": "bike",
    "is_online": true,
    "current_lat": 6.5250,
    "current_lng": 3.3800
  },
  ...
]
```

## Integration with Flota App

Update `lib/core/api_client.dart`:

```dart
class ApiClient {
  static const String baseUrl = 'http://your-domain.com/api';
  // ... rest of implementation
}
```

Update `lib/features/auth/auth_provider.dart`:

```dart
Future<void> login(String email, String password) async {
  state = state.copyWith(status: AuthStatus.loading);

  final response = await ApiClient().post('/login', data: {
    'email': email,
    'password': password,
  });

  // Store token and update state
  final token = response.data['token'];
  final user = response.data['user'];

  state = state.copyWith(
    status: AuthStatus.authenticated,
    userEmail: user['email'],
    role: user['role'],
  );
}
```

## Database Setup

Once `composer install` completes:

```bash
# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure database in .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=giga
DB_USERNAME=root
DB_PASSWORD=

# Run migrations
php artisan migrate

# Start development server
php artisan serve
```
