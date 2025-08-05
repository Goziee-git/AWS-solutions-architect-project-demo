# AWS MongoDB Backend with JWT Authentication

This is a Node.js backend application with JWT authentication, built for AWS deployment with MongoDB.

## Features

- 🔐 JWT Authentication with access and refresh tokens
- 👤 User registration and login
- 🛡️ Protected routes with middleware
- 🗄️ MongoDB integration with Mongoose
- 🚀 Ready for AWS deployment
- 📊 Health check endpoint
- 🔒 Security middleware (Helmet, CORS, Rate limiting)

## Quick Start

### 1. Environment Setup

The application uses environment variables for configuration. A `.env` file has been created with secure defaults:

```bash
# View the current .env configuration
cat .env
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Start the Application

```bash
# Start with environment validation
npm start

# Or start in development mode with nodemon
npm run dev

# Or start the server directly
npm run server
```

### 4. Test JWT Functionality

```bash
npm run test:jwt
```

## JWT Configuration

The JWT system is configured with:

- **Access Token Expiration**: 7 days (configurable via `JWT_EXPIRE`)
- **Refresh Token Expiration**: 30 days
- **Secure Secret**: 256-bit randomly generated secret
- **Issuer**: AWS MongoDB Backend
- **Audience**: aws-mongodb-app-users

## API Endpoints

### Authentication Routes (`/api/auth`)

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login User
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### Get Current User (Protected)
```http
GET /api/auth/me
Authorization: Bearer <your-jwt-token>
```

#### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "<your-refresh-token>"
}
```

### Response Format

All authentication endpoints return:

```json
{
  "success": true,
  "message": "Operation successful",
  "token": "<access-token>",
  "refreshToken": "<refresh-token>",
  "user": {
    "id": "user-id",
    "username": "username",
    "email": "email@example.com",
    "firstName": "First",
    "lastName": "Last",
    "role": "user"
  }
}
```

## Using JWT Tokens

### In Frontend Applications

```javascript
// Store tokens after login
localStorage.setItem('accessToken', response.data.token);
localStorage.setItem('refreshToken', response.data.refreshToken);

// Include token in API requests
const token = localStorage.getItem('accessToken');
const config = {
  headers: {
    'Authorization': `Bearer ${token}`
  }
};

// Make authenticated requests
axios.get('/api/users/profile', config);
```

### Token Refresh Flow

```javascript
// Check if token needs refresh
const isTokenExpired = (token) => {
  const payload = JSON.parse(atob(token.split('.')[1]));
  return payload.exp * 1000 < Date.now();
};

// Refresh token if needed
const refreshAccessToken = async () => {
  const refreshToken = localStorage.getItem('refreshToken');
  const response = await axios.post('/api/auth/refresh', { refreshToken });
  localStorage.setItem('accessToken', response.data.token);
  localStorage.setItem('refreshToken', response.data.refreshToken);
  return response.data.token;
};
```

## Security Features

- **Password Hashing**: bcryptjs with salt rounds of 12
- **JWT Security**: Signed with 256-bit secret, includes issuer and audience
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS Protection**: Configured for specific frontend origins
- **Helmet**: Security headers for production
- **Input Validation**: Joi schema validation for all inputs

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` |
| `PORT` | Server port | `5000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/aws-mongodb-app` |
| `JWT_SECRET` | JWT signing secret | Auto-generated secure secret |
| `JWT_EXPIRE` | Access token expiration | `7d` |
| `FRONTEND_URL` | Frontend URL for CORS | `http://localhost:3000` |

## Health Check

The application includes a health check endpoint:

```http
GET /health
```

Returns:
```json
{
  "status": "OK",
  "timestamp": "2025-08-04T11:00:00.000Z",
  "uptime": 123.456,
  "environment": "development"
}
```

## Development

### Project Structure

```
backend/
├── middleware/          # Authentication middleware
├── models/             # Mongoose models
├── routes/             # API routes
├── utils/              # Utility functions (JWT helpers)
├── .env                # Environment variables
├── server.js           # Main server file
├── start.js            # Startup script with validation
└── test-jwt.js         # JWT functionality test
```

### Testing

```bash
# Test JWT functionality
npm run test:jwt

# Run all tests
npm test
```

## Deployment

The application is ready for deployment on AWS with:

- Docker support (Dockerfile included)
- Environment variable configuration
- Health check endpoint for load balancers
- Production-ready security settings

## Troubleshooting

### Common Issues

1. **JWT_SECRET not found**: Ensure `.env` file exists and contains `JWT_SECRET`
2. **MongoDB connection failed**: Check `MONGODB_URI` in `.env`
3. **CORS errors**: Update `FRONTEND_URL` in `.env` to match your frontend URL
4. **Token expired**: Use the refresh token endpoint to get a new access token

### Debug Mode

Set `LOG_LEVEL=debug` in `.env` for detailed logging.
